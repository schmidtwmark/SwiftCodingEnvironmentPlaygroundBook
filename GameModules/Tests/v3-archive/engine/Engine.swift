//
//  Engine.swift  (GameAPI: iPad only)
//
//  Runs in the page's own process: a SpriteKit scene calls Runtime.tick() 60 times a second
//  (which calls the student's functions directly), draws the world with emoji sprites, the sky
//  (a gradient), background layers, falling weather, particle bursts and screen shake, plays the
//  sounds (Audio.swift), draws the HUD (checklist panel, game.showText lines, inspector, message),
//  and reads the on-screen ◀ ▶ ▲ ▼ buttons, UIKit key presses and the GameController keyboard.
//
//  Keyboard: only the ← → ↑ ↓ arrow keys do anything. Letters and space are ignored, because a
//  student whose code editor still has the keyboard would be typing into their code. The game asks
//  to become first responder when it starts, whenever it is tapped and whenever a button is
//  pressed, and a small "Tap the game to use ← → ↑" hint shows until the first arrow key arrives.
//  The ▼ button appears only once a script asks about .down.
//
//  Step Through My Code: the level is drawn with "Switch to Run My Code (the ⏱ menu)" and the
//  scripts never run, because a stepped script could take seconds and trip the watchdog.
//

#if canImport(UIKit) && canImport(SpriteKit) && canImport(PlaygroundSupport)
import UIKit
import SpriteKit
import GameController
import PlaygroundSupport

// MARK: - GameLauncher (GameWiring.start() in the hidden code at the top of every page)

/// The iPad side of `GameWiring.start()`. Not @MainActor: a page's top-level code calls it. The
/// level is read on the next turn of the main run loop, after the rest of the page's top-level
/// code (game.level, Settings) has run. (Mac twin: Tests/Headless.swift.)
enum GameLauncher {
    static func launch(_ box: StartBox) {
        PlaygroundPage.current.needsIndefiniteExecution = true
        let mode = PlaygroundPage.current.executionMode
        box.stepMode = mode == .step || mode == .stepSlowly
        if !box.stepMode { Watchdog.shared.start() }
        if Thread.isMainThread {
            MainActor.assumeIsolated { GameViewController.showInPlayground(box) }
        } else {
            DispatchQueue.main.async { MainActor.assumeIsolated { GameViewController.showInPlayground(box) } }
        }
    }
}

// MARK: - Emoji textures (each distinct string drawn once)

@MainActor enum EmojiTextures {
    static var cache: [String: SKTexture] = [:]
    static func texture(_ full: String) -> SKTexture {
        // A script that keeps growing an emoji string (player.emoji += "🙂" every frame) must not
        // draw and keep a new image every frame.
        let text = String(full.prefix(8))
        if let t = cache[text] { return t }
        if cache.count >= 200 { cache.removeAll() }
        let size = CGSize(width: 96, height: 96)
        let image = UIGraphicsImageRenderer(size: size).image { _ in
            var fontSize: CGFloat = 78
            var string = NSAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: fontSize)])
            while string.size().width > size.width && fontSize > 8 {
                fontSize -= 4
                string = NSAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: fontSize)])
            }
            let b = string.size()
            string.draw(at: CGPoint(x: (size.width - b.width) / 2, y: (size.height - b.height) / 2))
        }
        let t = SKTexture(image: image)
        cache[text] = t
        return t
    }
}

/// Background layer emoji, drawn at 96, 192 or 384 pixels (the smallest that is sharp at the
/// layer's size), at most 60 kept.
@MainActor enum LayerTextures {
    static var cache: [String: SKTexture] = [:]
    static func texture(_ text: String, size: Int) -> SKTexture {
        let pixels = size <= 48 ? 96 : (size <= 96 ? 192 : 384)
        let key = "\(pixels) " + text
        if let t = cache[key] { return t }
        if cache.count >= 60 { cache.removeAll() }
        let box = CGSize(width: pixels, height: pixels)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: box, format: format).image { _ in
            var fontSize = CGFloat(pixels) * 0.8
            var string = NSAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: fontSize)])
            while string.size().width > box.width && fontSize > 8 {
                fontSize -= 4
                string = NSAttributedString(string: text, attributes: [.font: UIFont.systemFont(ofSize: fontSize)])
            }
            let b = string.size()
            string.draw(at: CGPoint(x: (box.width - b.width) / 2, y: (box.height - b.height) / 2))
        }
        let t = SKTexture(image: image)
        cache[key] = t
        return t
    }
}

extension GameColor {
    var uiColor: UIColor {
        UIColor(red: CGFloat(red) / 255, green: CGFloat(green) / 255, blue: CGFloat(blue) / 255, alpha: 1)
    }
}

// MARK: - Scene

@MainActor final class GameScene: SKScene {
    static let worldSize = CGSize(width: 1024, height: 576)

    var ready = false
    /// Step Through My Code: draw the level and the message, but never call the scripts.
    var scriptsStopped = false
    var diagnostics = false
    /// Whether the HUD text is currently colored for a dark sky (nil = not set yet).
    var darkSkyShown: Bool? = nil
    var builtGeneration = -1
    let cameraNode = SKCameraNode()
    let worldLayer = SKNode()
    var thingNodes: [(thing: Thing, node: SKSpriteNode, emoji: String)] = []
    var flagNodes: [(thing: Thing, node: SKSpriteNode, shown: String)] = []
    var shownThingsVersion = -1

    // The sky (a gradient from game.skyColor to game.horizonColor), behind everything.
    let skyNode = SKSpriteNode(color: .clear, size: GameScene.worldSize)
    var shownSky: (top: GameColor, bottom: GameColor)? = nil
    // Background layers (game.background, game.addLayer): camera children, so they scroll by
    // cameraX / distance.
    let layersNode = SKNode()
    var shownLayers: [GameLayer] = []
    var layerSprites: [[SKSpriteNode]] = []
    var layerShown: [[String]] = []
    var layerChars: [[String]] = []
    // Particles (thing.burst), in level points, above the things.
    let particleLayer = SKNode()
    var particleNodes: [SKSpriteNode] = []
    var particleShown: [String] = []
    var particles = ParticleSystem()
    // Weather (game.weather), in screen points.
    let weatherLayer = SKNode()
    var weatherNodes: [SKSpriteNode] = []
    var weatherShown: [String] = []
    var weather = WeatherSystem()
    var shake = ShakeState()
    /// Called once, when a script first asks about .down (the controller shows the ▼ button).
    var onUsesDown: () -> Void = {}
    var downShown = false

    let panelBox = SKShapeNode()
    let panelLabel = SKLabelNode(fontNamed: "AvenirNext-DemiBold")
    /// game.showText lines, top right, one label per line.
    var textLabels: [SKLabelNode] = []
    /// The inspector: the player's numbers, then the page's own (under the text lines).
    var inspectorLabels: [SKLabelNode] = []
    let messageBox = SKShapeNode()
    let messageLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    let statusLabel = SKLabelNode(fontNamed: "Menlo")
    var shownPanel = ""
    var shownMessage = "\u{0}"

    var lastTime: TimeInterval = 0
    var accumulator: TimeInterval = 0
    var statStart: TimeInterval = 0
    var statFrames = 0
    var statSteps = 0
    var framesPerSecond = 0
    var stepsPerSecond = 0
    var lastKeySource = "none"
    var stepNanos: UInt64 = 0
    var drawNanos: UInt64 = 0
    var pollKeyboard: () -> Void = {}

    override init(size: CGSize) {
        super.init(size: size)
        scaleMode = .aspectFit
        anchorPoint = .zero
        backgroundColor = game.skyColor.uiColor
        addChild(worldLayer)
        camera = cameraNode
        addChild(cameraNode)
        cameraNode.position = CGPoint(x: size.width / 2, y: size.height / 2)
        skyNode.zPosition = -1000
        cameraNode.addChild(skyNode)
        cameraNode.addChild(layersNode)
        setUpEffects()
        setUpHUD()
    }
    required init?(coder: NSCoder) { fatalError() }

    private func setUpHUD() {
        let w = GameScene.worldSize.width / 2, h = GameScene.worldSize.height / 2
        panelBox.fillColor = UIColor.white.withAlphaComponent(0.82)
        panelBox.strokeColor = .clear
        panelBox.zPosition = 100
        cameraNode.addChild(panelBox)
        panelLabel.numberOfLines = 0
        panelLabel.fontSize = 17
        panelLabel.fontColor = .black
        panelLabel.horizontalAlignmentMode = .left
        panelLabel.verticalAlignmentMode = .top
        panelLabel.position = CGPoint(x: -w + 22, y: h - 18)
        panelLabel.zPosition = 101
        cameraNode.addChild(panelLabel)

        for i in 0..<Runtime.maxTexts {
            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            label.fontSize = 24
            label.fontColor = .black
            label.horizontalAlignmentMode = .right
            label.verticalAlignmentMode = .top
            label.position = CGPoint(x: w - 16, y: h - 14 - CGFloat(30 * i))
            label.zPosition = 101
            label.isHidden = true
            addShadow(to: label)
            cameraNode.addChild(label)
            textLabels.append(label)
        }
        for _ in 0..<2 {
            let label = SKLabelNode(fontNamed: "Menlo")
            label.fontSize = 15
            label.fontColor = UIColor(white: 0.22, alpha: 1)
            label.horizontalAlignmentMode = .right
            label.verticalAlignmentMode = .top
            label.zPosition = 101
            label.isHidden = true
            addShadow(to: label)
            cameraNode.addChild(label)
            inspectorLabels.append(label)
        }

        messageBox.fillColor = UIColor.black.withAlphaComponent(0.6)
        messageBox.strokeColor = .clear
        messageBox.zPosition = 110
        cameraNode.addChild(messageBox)
        messageLabel.fontSize = 40
        messageLabel.fontColor = .white
        messageLabel.numberOfLines = 0
        messageLabel.preferredMaxLayoutWidth = 900   // a long message wraps instead of growing off screen
        messageLabel.horizontalAlignmentMode = .center
        messageLabel.verticalAlignmentMode = .center
        messageLabel.position = CGPoint(x: 0, y: 40)
        messageLabel.zPosition = 111
        cameraNode.addChild(messageLabel)

        statusLabel.fontSize = 13
        statusLabel.fontColor = UIColor(white: 0.15, alpha: 1)
        statusLabel.horizontalAlignmentMode = .left
        statusLabel.verticalAlignmentMode = .bottom
        statusLabel.position = CGPoint(x: -w + 10, y: -h + 8)
        statusLabel.zPosition = 101
        cameraNode.addChild(statusLabel)
        messageLabel.text = "Loading…"
    }

    /// A copy of the label 1.5 points down and right, behind it, in the opposite color, so showText and
    /// inspector text stay readable over white clouds, snow or a busy layer.
    private func addShadow(to label: SKLabelNode) {
        let shadow = SKLabelNode(fontNamed: label.fontName)
        shadow.fontSize = label.fontSize
        shadow.fontColor = UIColor(white: 1, alpha: 0.7)
        shadow.horizontalAlignmentMode = label.horizontalAlignmentMode
        shadow.verticalAlignmentMode = label.verticalAlignmentMode
        shadow.position = CGPoint(x: 1.5, y: -1.5)
        shadow.zPosition = -0.5
        label.addChild(shadow)
    }

    /// Sets a HUD label's text and its shadow's. A text line wider than `maxWidth` points (40 emoji
    /// are about 1,160) is scaled down, so it never runs over the checklist.
    private func setHUDText(_ label: SKLabelNode, _ text: String, maxWidth: CGFloat) {
        label.text = text
        (label.children.first as? SKLabelNode)?.text = text
        label.setScale(1)
        let width = label.frame.width
        if width > maxWidth { label.setScale(maxWidth / width) }
    }

    private func setHUDColor(_ label: SKLabelNode, _ color: UIColor, darkSky: Bool) {
        label.fontColor = color
        (label.children.first as? SKLabelNode)?.fontColor = UIColor(white: darkSky ? 0 : 1, alpha: darkSky ? 0.6 : 0.7)
    }

    private func setUpEffects() {
        particleLayer.zPosition = 50
        worldLayer.addChild(particleLayer)
        for _ in 0..<ParticleSystem.capacity {
            let node = SKSpriteNode(color: .clear, size: CGSize(width: 34, height: 34))
            node.isHidden = true
            particleLayer.addChild(node)
            particleNodes.append(node)
            particleShown.append("")
        }
        weatherLayer.zPosition = 60
        cameraNode.addChild(weatherLayer)
        for _ in 0..<WeatherSystem.capacity {
            let node = SKSpriteNode(color: .clear, size: CGSize(width: 40, height: 40))
            node.isHidden = true
            weatherLayer.addChild(node)
            weatherNodes.append(node)
            weatherShown.append("")
        }
    }

    // MARK: Frame loop

    override func update(_ currentTime: TimeInterval) {
        guard ready else { return }
        let runtime = Runtime.shared
        pollKeyboard()
        // Start a quarter step off the boundary, so frames timed by the display run exactly 1 step
        // each at 60 Hz (and 0, 1, 0, 1 at 120 Hz) instead of a jittery 0, 1 or 2.
        if lastTime == 0 { lastTime = currentTime; statStart = currentTime; accumulator = 0.25 / 60.0 }
        accumulator += min(currentTime - lastTime, 0.25)
        lastTime = currentTime
        var steps = 0
        let t0 = DispatchTime.now().uptimeNanoseconds
        while !scriptsStopped && accumulator >= 1.0 / 60.0 && steps < 4 {
            Watchdog.shared.enter()
            runtime.tick()
            Watchdog.shared.leave()
            stepEffects()
            accumulator -= 1.0 / 60.0
            steps += 1
        }
        if steps == 4 { accumulator = min(accumulator, 0.25 / 60.0) }   // drop a backlog instead of speeding up
        let t1 = DispatchTime.now().uptimeNanoseconds
        if runtime.generation != builtGeneration { rebuild() }
        sync()
        stepNanos += t1 - t0
        drawNanos += DispatchTime.now().uptimeNanoseconds - t1

        statFrames += 1
        statSteps += steps
        if currentTime - statStart >= 1 {
            framesPerSecond = Int((Double(statFrames) / (currentTime - statStart)).rounded())
            stepsPerSecond = Int((Double(statSteps) / (currentTime - statStart)).rounded())
            let stepMicros = statSteps > 0 ? Int(stepNanos / UInt64(statSteps) / 1000) : 0
            let syncMicros = statFrames > 0 ? Int(drawNanos / UInt64(statFrames) / 1000) : 0
            stepNanos = 0
            drawNanos = 0
            if diagnostics { print("GAMESTATS cpu: \(stepMicros) µs per step (scripts+physics), \(syncMicros) µs per frame (sprite sync+HUD), things=\((runtime.realWorld?.enemies.count ?? 0) + (runtime.realWorld?.coins.count ?? 0))") }
            statStart = currentTime
            statFrames = 0
            statSteps = 0
            if diagnostics {
                print("GAMESTATS fps=\(framesPerSecond) steps/s=\(stepsPerSecond) step=\(runtime.stepsTaken) player=(\(player.x),\(player.y)) won=\(runtime.pageCompleted) msg=\(runtime.message)")
            }
        }
    }

    // MARK: Effects (once per fixed step, also while the game is frozen)

    /// Plays the sounds and starts the bursts and shakes the step asked for, then moves the
    /// particles, the weather and the shake one step on.
    private func stepEffects() {
        for effect in Runtime.shared.takeEffects() {
            switch effect {
            case .sound(let sound):
                GameAudio.shared.play(sound)
            case .burst(let emoji, let count, let speed, let x, let y):
                particles.emit(emoji, count: count, speed: speed, x: x, y: y)
            case .shake(let strength):
                if !UIAccessibility.isReduceMotionEnabled { shake.start(strength) }
            }
        }
        particles.step()
        weather.step(game.weather)
        shake.step()
    }

    private func drawEffects() {
        for i in 0..<ParticleSystem.capacity {
            let p = particles.particles[i]
            let node = particleNodes[i]
            if !p.alive {
                if !node.isHidden { node.isHidden = true }
                continue
            }
            if particleShown[i] != p.emoji {
                node.texture = EmojiTextures.texture(p.emoji)
                particleShown[i] = p.emoji
            }
            node.isHidden = false
            node.position = CGPoint(x: p.x, y: p.y)
            node.alpha = CGFloat(p.life)
            node.setScale(CGFloat(p.scale))
        }
        let w2 = GameScene.worldSize.width / 2, h2 = GameScene.worldSize.height / 2
        for i in 0..<WeatherSystem.capacity {
            let f = weather.flakes[i]
            let node = weatherNodes[i]
            if !f.alive {
                if !node.isHidden { node.isHidden = true }
                continue
            }
            if weatherShown[i] != f.emoji {
                node.texture = EmojiTextures.texture(f.emoji)
                weatherShown[i] = f.emoji
            }
            node.isHidden = false
            node.position = CGPoint(x: f.drawX - w2, y: f.y - h2)
        }
        let offset = CGPoint(x: shake.offset.x, y: shake.offset.y)
        if worldLayer.position != offset { worldLayer.position = offset }
        if layersNode.position != offset { layersNode.position = offset }
    }

    // MARK: Sky and background layers

    private func drawSky() {
        let top = game.skyColor, bottom = game.horizonColor
        if let shown = shownSky, shown.top == top, shown.bottom == bottom { return }
        shownSky = (top, bottom)
        backgroundColor = bottom.uiColor
        if top == bottom {
            skyNode.texture = nil
            skyNode.color = top.uiColor
            skyNode.colorBlendFactor = 1
            return
        }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let image = UIGraphicsImageRenderer(size: CGSize(width: 1, height: 256), format: format).image { ctx in
            let colors = [top.uiColor.cgColor, bottom.uiColor.cgColor] as CFArray
            if let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(), colors: colors, locations: [0, 1]) {
                ctx.cgContext.drawLinearGradient(gradient, start: .zero, end: CGPoint(x: 0, y: 256), options: [])
            }
        }
        let texture = SKTexture(image: image)
        texture.filteringMode = .linear
        skyNode.texture = texture
        skyNode.colorBlendFactor = 0
        skyNode.size = GameScene.worldSize
    }

    private func drawLayers(rows: Int) {
        let all = game.presetLayers + game.layers
        if all != shownLayers {
            shownLayers = all
            layersNode.removeAllChildren()
            layerSprites = []
            layerShown = []
            layerChars = []
            for layer in all {
                let count = Int((GameScene.worldSize.width / CGFloat(layer.size)).rounded(.up)) + 2
                var sprites: [SKSpriteNode] = []
                for _ in 0..<count {
                    let node = SKSpriteNode(color: .clear, size: CGSize(width: layer.size, height: layer.size))
                    node.zPosition = -150 - CGFloat(layer.distance)
                    node.isHidden = true
                    layersNode.addChild(node)
                    sprites.append(node)
                }
                layerSprites.append(sprites)
                layerShown.append(Array(repeating: "", count: count))
                layerChars.append(layer.emoji.map { String($0) })
            }
        }
        let w2 = GameScene.worldSize.width / 2, h2 = GameScene.worldSize.height / 2
        let cx = cameraNode.position.x, cy = cameraNode.position.y
        for (li, layer) in all.enumerated() {
            let chars = layerChars[li]
            let n = chars.count
            if n == 0 { continue }
            let size = CGFloat(layer.size), d = CGFloat(layer.distance)
            let offX = (cx - w2) / d
            let offY = rows > 9 ? (cy - h2) / d : 0
            let first = Int((offX / size).rounded(.down))
            for (k, node) in layerSprites[li].enumerated() {
                let i = first + k
                let ch = chars[((i % n) + n) % n]
                if ch.trimmingCharacters(in: .whitespaces).isEmpty {
                    if !node.isHidden { node.isHidden = true }
                    continue
                }
                if layerShown[li][k] != ch {
                    node.texture = LayerTextures.texture(ch, size: layer.size)
                    layerShown[li][k] = ch
                }
                node.isHidden = false
                node.position = CGPoint(x: CGFloat(i) * size + size / 2 - offX - w2,
                                        y: CGFloat(layer.y) + size / 2 - offY - h2)
            }
        }
    }

    // MARK: Building the level's nodes

    func rebuild() {
        let runtime = Runtime.shared
        guard let w = runtime.realWorld else { return }
        builtGeneration = runtime.generation
        worldLayer.removeAllChildren()
        worldLayer.addChild(particleLayer)
        thingNodes = []
        flagNodes = []
        shownThingsVersion = -1
        drawSky()
        let blockTexture: SKTexture? = game.blockEmoji.isEmpty ? nil : EmojiTextures.texture(game.blockEmoji)
        let grass = UIColor(red: 0.36, green: 0.72, blue: 0.27, alpha: 1)
        for row in 0..<w.rows {
            for col in 0..<w.cols {
                let tile = w.tiles[row][col]
                let center = CGPoint(x: col * tileSize + tileSize / 2, y: (w.rows - 1 - row) * tileSize + tileSize / 2)
                switch tile {
                case .air: break
                case .block:
                    let node: SKSpriteNode
                    if let blockTexture {
                        node = SKSpriteNode(texture: blockTexture, size: CGSize(width: 66, height: 66))
                    } else {
                        node = SKSpriteNode(color: game.blockColor.uiColor, size: CGSize(width: 64, height: 64))
                        if w.tile(col: col, row: row - 1) == .air || row == 0 {
                            let top = SKSpriteNode(color: grass, size: CGSize(width: 64, height: 12))
                            top.position = CGPoint(x: 0, y: 26)
                            node.addChild(top)
                        }
                    }
                    node.position = center
                    worldLayer.addChild(node)
                case .brick:
                    let node = SKSpriteNode(color: UIColor(red: 0.85, green: 0.45, blue: 0.2, alpha: 1), size: CGSize(width: 62, height: 62))
                    node.position = center
                    worldLayer.addChild(node)
                case .spikes:
                    let node = SKSpriteNode(texture: EmojiTextures.texture(game.spikeEmoji), size: CGSize(width: 52, height: 52))
                    node.position = CGPoint(x: center.x, y: center.y - 32 + 26)
                    worldLayer.addChild(node)
                }
            }
        }
        for s in w.scenery {
            let node = SKSpriteNode(texture: EmojiTextures.texture(s.emoji), size: CGSize(width: 64, height: 64))
            node.position = CGPoint(x: s.col * tileSize + tileSize / 2, y: (w.rows - 1 - s.row) * tileSize + tileSize / 2)
            node.zPosition = -5
            node.alpha = 0.9
            worldLayer.addChild(node)
        }
        for f in w.flags {
            let node = SKSpriteNode(texture: EmojiTextures.texture(f.emoji), size: CGSize(width: 60, height: 60))
            node.zPosition = 1
            worldLayer.addChild(node)
            flagNodes.append((f, node, f.emoji))
        }
        matchThings(w)
        sync()
        cameraNode.position = cameraTarget(w)
    }

    /// Every thing in the world has a sprite, and no sprite is left for a thing that left it
    /// (game.spawn adds things while the game runs, and removed spawned things are pruned).
    func matchThings(_ w: World) {
        if w.thingsVersion == shownThingsVersion { return }
        shownThingsVersion = w.thingsVersion
        var things: [Thing] = w.pickups
        things += w.enemies as [Thing]
        things += w.fireballs as [Thing]
        things.append(player)
        let wanted = Set(things.map { ObjectIdentifier($0) })
        thingNodes.removeAll { entry in
            if wanted.contains(ObjectIdentifier(entry.thing)) { return false }
            entry.node.removeFromParent()
            return true
        }
        let have = Set(thingNodes.map { ObjectIdentifier($0.thing) })
        for t in things where !have.contains(ObjectIdentifier(t)) {
            let size: CGFloat
            switch t.kind {
            case .coin, .fireball: size = 40
            case .star: size = 46
            case .spring: size = 52
            default: size = 58
            }
            let node = SKSpriteNode(texture: EmojiTextures.texture(t.emoji), size: CGSize(width: size, height: size))
            // The player draws above the checklist panel's box (100) and below its text (101), so it
            // never hides behind the panel and never hides a hint.
            node.zPosition = t.kind == .player ? 100.5 : (t.kind.isPickup ? 2 : 3)
            node.position = CGPoint(x: t.x, y: t.y)
            worldLayer.addChild(node)
            thingNodes.append((t, node, t.emoji))
        }
    }

    func cameraTarget(_ w: World) -> CGPoint {
        let size = GameScene.worldSize
        let levelW = CGFloat(w.widthInPoints), levelH = CGFloat(w.heightInPoints)
        let x = levelW <= size.width ? levelW / 2 : min(max(CGFloat(player.x), size.width / 2), levelW - size.width / 2)
        let y = w.rows <= 9 ? size.height / 2 : min(max(CGFloat(player.y), size.height / 2), levelH - size.height / 2)
        return CGPoint(x: x, y: y)
    }

    // MARK: Copy the game's numbers onto the nodes

    func sync() {
        let runtime = Runtime.shared
        guard let w = runtime.realWorld else { return }
        drawSky()
        matchThings(w)
        // Light text on a dark sky (like game.skyColor = .hex("1a1a40")), dark text on a light one.
        // The text sits at the top of the sky, so it follows skyColor (the gradient's top).
        let darkSky = game.skyColor.isDark
        if darkSky != darkSkyShown {
            darkSkyShown = darkSky
            for label in textLabels { setHUDColor(label, darkSky ? .white : .black, darkSky: darkSky) }
            for label in inspectorLabels { setHUDColor(label, UIColor(white: darkSky ? 0.82 : 0.22, alpha: 1), darkSky: darkSky) }
            statusLabel.fontColor = UIColor(white: darkSky ? 0.85 : 0.15, alpha: 1)
        }
        for i in thingNodes.indices {
            let (t, node, emoji) = thingNodes[i]
            node.isHidden = t.removed
            if t.removed { continue }
            node.position = CGPoint(x: t.x, y: t.y)
            if t.emoji != emoji {
                node.texture = EmojiTextures.texture(t.emoji)
                thingNodes[i].emoji = t.emoji
            }
            // Emoji face left; a thing whose speedX points right (or last did) is drawn mirrored.
            if !t.kind.isPickup { node.xScale = t.facesRight ? -1 : 1 }
            if t.kind == .player {
                node.alpha = (w.blinkFrames > 0 && (w.blinkFrames / 6) % 2 == 0) ? 0.25 : 1
            }
        }
        let locked = w.lockMessage != nil
        for i in flagNodes.indices {
            let (f, node, shown) = flagNodes[i]
            node.isHidden = f.removed
            node.position = CGPoint(x: f.x, y: f.y)
            let want = locked ? "🔒" : f.emoji
            if want != shown {
                node.texture = EmojiTextures.texture(want)
                flagNodes[i].shown = want
            }
        }
        let target = cameraTarget(w)
        cameraNode.position = CGPoint(x: cameraNode.position.x + (target.x - cameraNode.position.x) * 0.2,
                                      y: cameraNode.position.y + (target.y - cameraNode.position.y) * 0.2)
        drawLayers(rows: w.rows)
        drawEffects()
        if runtime.usesDown && !downShown {
            downShown = true
            onUsesDown()
        }

        let panel = runtime.panelLines().joined(separator: "\n")
        if panel != shownPanel {
            shownPanel = panel
            panelLabel.text = panel
            let frame = panelLabel.frame
            panelBox.path = UIBezierPath(roundedRect: frame.insetBy(dx: -10, dy: -8), cornerRadius: 12).cgPath
        }
        // game.showText lines: this frame's (while frozen, the last frame's), top right.
        let texts = runtime.texts
        for (i, label) in textLabels.enumerated() {
            if i < texts.count {
                if label.text != texts[i] { setHUDText(label, texts[i], maxWidth: 600) }
                label.isHidden = false
            } else if !label.isHidden {
                label.isHidden = true
            }
        }
        // The inspector sits right under the text lines.
        let w2 = GameScene.worldSize.width / 2, h2 = GameScene.worldSize.height / 2
        let inspector = runtime.inspectorLines
        let top = h2 - 14 - CGFloat(30 * texts.count) - (texts.isEmpty ? 0 : 4)
        for (i, label) in inspectorLabels.enumerated() {
            if i < inspector.count {
                if label.text != inspector[i] { setHUDText(label, inspector[i], maxWidth: 600) }
                let position = CGPoint(x: w2 - 16, y: top - CGFloat(19 * i))
                if label.position != position { label.position = position }
                label.isHidden = false
            } else if !label.isHidden {
                label.isHidden = true
            }
        }
        if runtime.message != shownMessage {
            shownMessage = runtime.message
            messageLabel.text = runtime.message
            messageBox.isHidden = runtime.message.isEmpty
            if !runtime.message.isEmpty {
                let frame = messageLabel.frame
                messageBox.path = UIBezierPath(roundedRect: frame.insetBy(dx: -24, dy: -14), cornerRadius: 18).cgPath
            }
        }
        if diagnostics {
            statusLabel.text = "\(stepsPerSecond) steps/s · \(framesPerSecond) fps · last key: \(lastKeySource)"
        }
    }
}

// MARK: - On-screen hold buttons (each tracks its own finger)

final class HoldButton: UIView {
    var onChange: (Bool) -> Void = { _ in }
    private let label = UILabel()
    private var touchCount = 0
    init(title: String) {
        super.init(frame: .zero)
        backgroundColor = UIColor.white.withAlphaComponent(0.22)
        layer.cornerRadius = 20
        layer.borderWidth = 2
        layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        label.text = title
        label.font = .systemFont(ofSize: 34, weight: .heavy)
        label.textColor = .white
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        addSubview(label)
        NSLayoutConstraint.activate([label.centerXAnchor.constraint(equalTo: centerXAnchor),
                                     label.centerYAnchor.constraint(equalTo: centerYAnchor)])
        isMultipleTouchEnabled = true
    }
    required init?(coder: NSCoder) { fatalError() }
    private func update(_ delta: Int) {
        let was = touchCount > 0
        touchCount = max(0, touchCount + delta)
        let now = touchCount > 0
        backgroundColor = UIColor.white.withAlphaComponent(now ? 0.55 : 0.22)
        if was != now { onChange(now) }
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) { update(touches.count) }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) { update(-touches.count) }
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) { update(-touches.count) }
}

// MARK: - Live view controller

final class GameViewController: UIViewController, PlaygroundLiveViewSafeAreaContainer {
    let skView = SKView()
    let scene = GameScene(size: GameScene.worldSize)
    let leftButton = HoldButton(title: "◀")
    let rightButton = HoldButton(title: "▶")
    let upButton = HoldButton(title: "▲")
    /// Hidden until a script asks about .down.
    let downButton = HoldButton(title: "▼")

    static func showInPlayground(_ box: StartBox) {
        let controller = GameViewController()
        PlaygroundPage.current.setLiveView(controller)
        DispatchQueue.main.async {
            MainActor.assumeIsolated { controller.begin(box) }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(red: 0.08, green: 0.09, blue: 0.12, alpha: 1)
        view.isMultipleTouchEnabled = true
        skView.preferredFramesPerSecond = 60
        skView.ignoresSiblingOrder = true
        skView.isMultipleTouchEnabled = true
        view.addSubview(skView)
        skView.presentScene(scene)
        for (button, key) in [(leftButton, GameKey.left), (rightButton, .right), (upButton, .up), (downButton, .down)] {
            button.onChange = { [weak self] down in
                let runtime = Runtime.shared
                if down {
                    runtime.input.touch |= key.bit
                    runtime.input.pressBegan(key)
                    runtime.userPoked()
                    self?.scene.lastKeySource = "touch"
                    self?.grabKeyboard()
                } else {
                    runtime.input.touch &= ~key.bit
                }
            }
            view.addSubview(button)
        }
        let tap = UITapGestureRecognizer(target: self, action: #selector(tapped))
        tap.cancelsTouchesInView = false
        skView.addGestureRecognizer(tap)
        downButton.isHidden = true
        scene.pollKeyboard = { [weak self] in self?.pollKeyboard() }
        scene.onUsesDown = { [weak self] in
            guard let self else { return }
            self.downButton.isHidden = false
            self.keyHintLabel.text = "Tap the game to use ← → ↑ ↓"
            self.view.setNeedsLayout()
        }
        setUpKeyHint()
    }

    /// Runs after the page's top-level code: test drives, then the level, then the 60 Hz loop.
    func begin(_ box: StartBox) {
        scene.diagnostics = box.diagnostics
        let runtime = Runtime.shared
        runtime.begin(page: box.page, scripts: box.scripts, runChecks: !box.stepMode)
        // Start the audio before the level shows when this page will play sounds (its checks
        // played one, or it is the Sounds or Design page). Other pages never touch the audio.
        if !box.stepMode && (runtime.checksPlayedSound || box.page == .sounds || box.page == .design) {
            GameAudio.shared.prewarm()
        }
        if box.stepMode {
            // Stays up, and the scripts never run (see the top of this file).
            runtime.showMessage("Switch to Run My Code (the ⏱ menu)")
            runtime.messageFrames = Int.max
            scene.scriptsStopped = true
        }
        if box.diagnostics { print("GAMESTATS checks took \(runtime.checkMilliseconds) ms") }
        scene.rebuild()
        scene.ready = true
        keyHint.isHidden = sawArrowKey
        grabKeyboard(retries: 10)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var safe = liveViewSafeAreaGuide.layoutFrame
        if safe.width < 10 || safe.height < 10 { safe = view.bounds }
        let gap: CGFloat = 14
        // Four buttons (with ▼) need about 420 points: in a narrower live view they shrink.
        let buttons: CGFloat = downButton.isHidden ? 3 : 4
        let button = max(52, min(84, (safe.width - 2 * 16 - 2 * gap - 40 - (buttons - 3) * gap) / buttons))
        let strip = button + 2 * gap
        let aspect = GameScene.worldSize.height / GameScene.worldSize.width
        var game = CGRect.zero
        var buttonsInStrip = false
        if safe.height - safe.width * aspect >= strip {
            let h = safe.width * aspect
            let top = safe.minY + (safe.height - h - strip) / 2
            game = CGRect(x: safe.minX, y: top, width: safe.width, height: h)
            buttonsInStrip = true
        } else {
            let w = min(safe.width, safe.height / aspect)
            let h = w * aspect
            game = CGRect(x: safe.midX - w / 2, y: safe.midY - h / 2, width: w, height: h)
        }
        skView.frame = game
        let y = buttonsInStrip ? game.maxY + gap : game.maxY - gap - button
        let inset: CGFloat = 16
        leftButton.frame = CGRect(x: game.minX + inset, y: y, width: button, height: button)
        rightButton.frame = CGRect(x: game.minX + inset + button + gap, y: y, width: button, height: button)
        upButton.frame = CGRect(x: game.maxX - inset - button, y: y, width: button, height: button)
        downButton.frame = CGRect(x: upButton.frame.minX - gap - button, y: y, width: button, height: button)
        for b in [leftButton, rightButton, upButton, downButton] { b.alpha = buttonsInStrip ? 1 : 0.6 }
        layOutKeyHint(game: game, buttonY: y, button: button, gap: gap)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        grabKeyboard()
    }

    @objc func tapped() {
        Runtime.shared.userPoked()
        grabKeyboard()
    }

    /// Asks for the keyboard. Before the view is in a window this fails, so `retries` tries again
    /// every 0.3 s.
    func grabKeyboard(retries: Int = 0) {
        if isFirstResponder { return }
        if becomeFirstResponder() || retries <= 0 { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
            MainActor.assumeIsolated { self?.grabKeyboard(retries: retries - 1) }
        }
    }
    override var canBecomeFirstResponder: Bool { true }

    // MARK: "Tap the game to use ← → ↑" (until the first arrow key arrives)

    private let keyHint = UIView()
    private let keyHintLabel = UILabel()
    private var sawArrowKey = false

    private func setUpKeyHint() {
        keyHint.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        keyHint.layer.cornerRadius = 10
        keyHint.isUserInteractionEnabled = false
        keyHint.isHidden = true
        keyHintLabel.text = "Tap the game to use ← → ↑"
        keyHintLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        keyHintLabel.textColor = .white
        keyHintLabel.textAlignment = .center
        keyHintLabel.numberOfLines = 2
        keyHintLabel.adjustsFontSizeToFitWidth = true
        keyHintLabel.minimumScaleFactor = 0.75
        keyHint.addSubview(keyHintLabel)
        view.addSubview(keyHint)
    }

    /// Between ▶ and ▲ when there is room, otherwise centered just above the buttons.
    private func layOutKeyHint(game: CGRect, buttonY: CGFloat, button: CGFloat, gap: CGFloat) {
        let pad: CGFloat = 10
        let roomLeft = rightButton.frame.maxX + gap
        let roomRight = (downButton.isHidden ? upButton.frame.minX : downButton.frame.minX) - gap
        let room = roomRight - roomLeft
        let maxWidth = room >= 150 ? room : min(game.width - 2 * gap, 320)
        let fits = keyHintLabel.sizeThatFits(CGSize(width: maxWidth - 2 * pad, height: 60))
        let w = min(fits.width, maxWidth - 2 * pad) + 2 * pad
        let h = fits.height + 2 * 6
        let x = room >= 150 ? roomLeft + (room - w) / 2 : game.midX - w / 2
        let y = room >= 150 ? buttonY + (button - h) / 2 : buttonY - gap - h
        keyHint.frame = CGRect(x: x, y: y, width: w, height: h)
        keyHintLabel.frame = keyHint.bounds.insetBy(dx: pad, dy: 6)
    }

    private func arrowKeyArrived() {
        if sawArrowKey { return }
        sawArrowKey = true
        UIView.animate(withDuration: 0.4, animations: { self.keyHint.alpha = 0 },
                       completion: { _ in self.keyHint.isHidden = true })
    }

    // MARK: Keyboard path 1: UIKit key presses (true held state)

    override func pressesBegan(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if !handle(presses, down: true) { super.pressesBegan(presses, with: event) }
    }
    override func pressesEnded(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if !handle(presses, down: false) { super.pressesEnded(presses, with: event) }
    }
    override func pressesCancelled(_ presses: Set<UIPress>, with event: UIPressesEvent?) {
        if !handle(presses, down: false) { super.pressesCancelled(presses, with: event) }
    }

    private func handle(_ presses: Set<UIPress>, down: Bool) -> Bool {
        let runtime = Runtime.shared
        var handled = false
        for press in presses {
            // ⌘ shortcuts (like ⌘R) belong to Swift Playgrounds, not the game. (Releases always
            // count, so a key can't get stuck down.)
            if down && press.key?.modifierFlags.contains(.command) == true { continue }
            let key: GameKey?
            switch press.key?.keyCode {
            case .keyboardLeftArrow?: key = .left
            case .keyboardRightArrow?: key = .right
            case .keyboardUpArrow?: key = .up
            case .keyboardDownArrow?: key = .down
            default: key = nil
            }
            guard let key else { continue }
            handled = true
            if down {
                runtime.input.keys |= key.bit
                runtime.input.pressBegan(key)
                runtime.userPoked()
                scene.lastKeySource = "UIKit"
                arrowKeyArrived()
            } else {
                runtime.input.keys &= ~key.bit
            }
        }
        return handled
    }

    // MARK: Keyboard path 2: GameController keyboard, polled every frame

    private var padBefore = 0
    private func pollKeyboard() {
        guard let keys = GCKeyboard.coalesced?.keyboardInput else { return }
        var bits = 0
        if keys.button(forKeyCode: .leftArrow)?.isPressed == true { bits |= GameKey.left.bit }
        if keys.button(forKeyCode: .rightArrow)?.isPressed == true { bits |= GameKey.right.bit }
        if keys.button(forKeyCode: .upArrow)?.isPressed == true { bits |= GameKey.up.bit }
        if keys.button(forKeyCode: .downArrow)?.isPressed == true { bits |= GameKey.down.bit }
        let runtime = Runtime.shared
        if bits & ~padBefore != 0 {
            runtime.input.latched |= bits & ~padBefore
            runtime.userPoked()
            if runtime.input.keys == 0 { scene.lastKeySource = "GCKeyboard" }
            arrowKeyArrived()
        }
        padBefore = bits
        runtime.input.pad = bits
    }
}
#endif
