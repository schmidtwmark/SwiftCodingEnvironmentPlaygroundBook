//
//  Audio.swift  (GameAPI: iPad only)
//
//  Plays Synth.swift's sound effects through AVAudioEngine with ONE AVAudioSourceNode that pulls
//  samples from the Mixer. It never uses AVAudioPlayerNode (whose play() raises an Objective-C
//  exception, an uncatchable crash, when the engine isn't running), and every throwing call is
//  `try?` or do/catch: if the iPad can't play sound, the game just stays silent.
//
//  - The session is .ambient, so the iPad's Silent mode and volume mute the game, and it mixes with
//    other audio.
//  - The engine starts when a page will play sounds (pre-warm, before the level shows) or at the
//    first sound. After a failed start it waits a second before trying again, and after 3 failed
//    starts it gives up silently, until an interruption (a call, Siri) ends.
//  - A configuration change (headphones, a new route) or a media-services reset throws the engine
//    away; an interruption stops it. Either way, the next sound builds or starts it again.
//  - The 12 sounds are rendered on a background queue and handed to the mixer under its lock; the
//    audio thread only ever tries that lock, so it never waits on the game.
//  - game.soundVolume (0 to 100, 30 at first) sets the main mixer's volume: 100 is 0.5, the
//    loudness before soundVolume existed. It is applied when the engine is built and on every game
//    step (applyVolume), so a change works right away, and 0 is silent.
//  - `GameAudio.audioEnabled = false` is the kill switch: nothing here touches AVFoundation, and the
//    sound log still records every sound, so the checks still work.
//

#if canImport(AVFAudio) && canImport(UIKit)
import AVFAudio
import UIKit

@MainActor final class GameAudio {
    static let shared = GameAudio()
    /// The kill switch (see the top of this file).
    nonisolated static let audioEnabled = true
    static let maxFailures = 3

    let mixer = Mixer()
    private var engine: AVAudioEngine?
    private var source: AVAudioSourceNode?
    private var failures = 0
    /// When the last start failed (system uptime, seconds): the next try waits a second, so 16 sounds
    /// in one frame during an interruption count as one failure, not all 3.
    private var lastFailure = -10.0
    /// The sample rate the mixer's sounds were rendered at (0: none yet).
    private var bankRate = 0.0
    private var observers: [NSObjectProtocol] = []
    /// The game.soundVolume the mixer has now (-1: no engine).
    private var appliedVolume = -1

    /// Starts the audio before the level shows, so the first sound isn't late.
    func prewarm() {
        _ = ensureRunning()
    }

    func play(_ sound: GameSound) {
        guard ensureRunning() else { return }
        applyVolume()
        mixer.play(sound)
    }

    /// Sets the main mixer's volume from game.soundVolume when it changed (every game step, and
    /// before each sound). Without an engine there is nothing to set: build() sets it.
    func applyVolume() {
        guard let engine else { return }
        let volume = game.soundVolume
        if volume == appliedVolume { return }
        appliedVolume = volume
        engine.mainMixerNode.outputVolume = Game.mixerVolume(volume)
    }

    /// Builds and starts the engine if it isn't running. false (silent) if it can't.
    private func ensureRunning() -> Bool {
        guard GameAudio.audioEnabled, failures < GameAudio.maxFailures else { return false }
        if let engine, engine.isRunning { return true }
        let now = ProcessInfo.processInfo.systemUptime
        if now - lastFailure < 1 { return false }
        if engine == nil && !build() {
            failed(at: now)
            return false
        }
        guard let engine else { return false }
        do {
            try engine.start()
            return true
        } catch {
            failed(at: now)
            tearDown()
            return false
        }
    }

    private func failed(at time: Double) {
        failures += 1
        lastFailure = time
    }

    /// One AVAudioEngine with one source node, connected once, before it starts.
    private func build() -> Bool {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.ambient, mode: .default, options: [])
        try? session.setPreferredIOBufferDuration(0.005)
        try? session.setActive(true)
        let e = AVAudioEngine()
        let rate = e.outputNode.outputFormat(forBus: 0).sampleRate
        guard rate >= 8000, rate <= 384_000,
              let format = AVAudioFormat(standardFormatWithSampleRate: rate, channels: 1) else { return false }
        let mixer = self.mixer
        // Mono and not interleaved, so the list holds exactly one buffer: mBuffers. This reads it
        // directly. Swift Playgrounds on the iPad can't see UnsafeMutableAudioBufferListPointer or
        // noErr (they come from the CoreAudio overlay), so neither is used here.
        let node = AVAudioSourceNode(format: format) { @Sendable silence, _, frameCount, bufferList -> OSStatus in
            let buffer = bufferList.pointee.mBuffers
            guard bufferList.pointee.mNumberBuffers == 1, let data = buffer.mData else {
                silence.pointee = true
                return 0
            }
            let out = data.assumingMemoryBound(to: Float.self)
            let fits = min(Int(frameCount), Int(buffer.mDataByteSize) / MemoryLayout<Float>.size)
            mixer.render(into: out, count: fits)
            silence.pointee = false
            return 0
        }
        e.attach(node)
        e.connect(node, to: e.mainMixerNode, format: format)
        e.mainMixerNode.outputVolume = Game.mixerVolume(game.soundVolume)
        appliedVolume = game.soundVolume
        e.prepare()
        engine = e
        source = node
        watch(e)
        if bankRate != rate { renderSounds(rate: rate) }
        return true
    }

    /// Renders the 12 sounds off the main thread, then swaps them into the mixer.
    private func renderSounds(rate: Double) {
        bankRate = rate
        let mixer = self.mixer
        DispatchQueue.global(qos: .userInitiated).async {
            let rendered = GameSound.allCases.map { Synth.render($0, rate: rate) }
            mixer.setBank(SoundBank(rate: rate, effects: rendered))
        }
    }

    private func watch(_ e: AVAudioEngine) {
        let center = NotificationCenter.default
        for o in observers { center.removeObserver(o) }
        observers = []
        // A new route or a media-services reset: throw the engine away; the next sound builds a new one.
        observers.append(center.addObserver(forName: .AVAudioEngineConfigurationChange, object: e, queue: .main) { _ in
            MainActor.assumeIsolated { GameAudio.shared.tearDown() }
        })
        observers.append(center.addObserver(forName: AVAudioSession.mediaServicesWereResetNotification, object: nil, queue: .main) { _ in
            MainActor.assumeIsolated { GameAudio.shared.tearDown() }
        })
        // An interruption (a call, Siri) stops the engine; the next sound starts it again. When it
        // ends, failed starts during it no longer count.
        observers.append(center.addObserver(forName: AVAudioSession.interruptionNotification, object: nil, queue: .main) { note in
            let type = note.userInfo?[AVAudioSessionInterruptionTypeKey] as? UInt
            let ended = type == AVAudioSession.InterruptionType.ended.rawValue
            MainActor.assumeIsolated { if ended { GameAudio.shared.interruptionEnded() } }
        })
    }

    private func interruptionEnded() {
        failures = 0
        lastFailure = -10
    }

    private func tearDown() {
        if let engine {
            engine.stop()
            if let source { engine.detach(source) }
        }
        engine = nil
        source = nil
        appliedVolume = -1
    }
}
#endif
