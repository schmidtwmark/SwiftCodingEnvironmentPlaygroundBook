//
//  Engine.swift  (GameAPI: iPad only)
//
//  Runs in the page's own process: a SpriteKit scene calls Runtime.tick() 60 times a second
//  (which calls the student's functions directly), draws the world with emoji sprites, the sky
//  (a gradient), background layers, falling weather, particle bursts and screen shake, plays the
//  sounds (Audio.swift), draws the student's own HUD in the game (game.showText lines and
//  game.showMessage), and reads the on-screen ◀ ▶ ▲ ▼ buttons, UIKit key presses and the
//  GameController keyboard.
//
//  Layout, top to bottom: the GOALS (GoalHeaderView: page title, checklist, a "Can't find:" line
//  for a function the engine can't find, the "Page complete!" / "Almost!" status and the inspector
//  numbers, in UIKit so they keep their size; no hints: the Hints pages have them), then the game,
//  then the buttons in their own strip (smaller in a short live view, never over the game).
//  Nothing about the page's goals is drawn over the game.
//  The game always shows 9 squares (576 points) of height; its width follows the game view's shape
//  (1.4 to 2.4 times its height), so a wide view shows more of the level instead of black bars.
//
//  Keyboard: only the ← → ↑ ↓ arrow keys do anything. Letters and space are ignored, because a
//  student whose code editor still has the keyboard would be typing into their code. The game asks
//  to become first responder when it starts, whenever it is tapped and whenever a button is
//  pressed, and a small "Tap the game to use ← → ↑" hint shows until the first arrow key arrives.
//  The ▼ button appears only once a function asks about .down.
//
//  Step Through My Code: the level is drawn with "Switch to Run My Code (the ⏱ menu)" and the
//  functions never run, because a stepped function could take seconds and trip the watchdog.
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
        // A function that keeps growing an emoji string (player.emoji += "🙂" every frame) must not
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
    /// The starting size. The height (9 squares) never changes; fit(aspect:) changes the width.
    static let worldSize = CGSize(width: 1024, height: 576)

    var ready = false
    /// Step Through My Code: draw the level and the message, but never call the functions.
    var functionsStopped = false
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
    /// Called once, when a function first asks about .down (the controller shows the ▼ button).
    var onUsesDown: () -> Void = {}
    var downShown = false

    /// game.showText lines, top right, one label per line.
    var textLabels: [SKLabelNode] = []
    /// A soft box behind the text lines, so they stay readable over clouds, snow or a busy layer
    /// (dark behind light text, light behind dark text). Below the player.
    let textBox = SKShapeNode()
    var textBoxShown = CGRect.null
    var textBoxDirty = true
    /// game.showMessage, "Game over" (Runtime.gameMessage). The goal status is above the game.
    let messageBox = SKShapeNode()
    let messageLabel = SKLabelNode(fontNamed: "AvenirNext-Heavy")
    /// Diagnostics only (steps/s, fps, last key), bottom left.
    let statusLabel = SKLabelNode(fontNamed: "Menlo")
    var shownMessage = "\u{0}"
    /// Called at the end of every sync: the controller copies the goals into the header.
    var onSync: () -> Void = {}

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
        textBox.strokeColor = .clear
        textBox.fillColor = UIColor.black.withAlphaComponent(0.28)
        textBox.zPosition = 99
        textBox.isHidden = true
        cameraNode.addChild(textBox)
        for _ in 0..<Runtime.maxTexts {
            let label = SKLabelNode(fontNamed: "AvenirNext-Bold")
            label.fontSize = 24
            label.fontColor = .black
            label.horizontalAlignmentMode = .right
            label.verticalAlignmentMode = .top
            label.zPosition = 101
            label.isHidden = true
            addShadow(to: label)
            cameraNode.addChild(label)
            textLabels.append(label)
        }

        messageBox.fillColor = UIColor.black.withAlphaComponent(0.6)
        messageBox.strokeColor = .clear
        messageBox.zPosition = 110
        cameraNode.addChild(messageBox)
        messageLabel.fontSize = 40
        messageLabel.fontColor = .white
        messageLabel.numberOfLines = 0
        messageLabel.horizontalAlignmentMode = .center
        messageLabel.verticalAlignmentMode = .center
        messageLabel.position = CGPoint(x: 0, y: 40)
        messageLabel.zPosition = 111
        cameraNode.addChild(messageLabel)

        statusLabel.fontSize = 13
        statusLabel.fontColor = UIColor(white: 0.15, alpha: 1)
        statusLabel.horizontalAlignmentMode = .left
        statusLabel.verticalAlignmentMode = .bottom
        statusLabel.zPosition = 101
        cameraNode.addChild(statusLabel)
        layOutHUD()
        messageLabel.text = "Loading…"
    }

    /// The text lines sit at the top right of the visible part of the world, which is as wide as
    /// the game view's shape (fit(aspect:)).
    private func layOutHUD() {
        let w = size.width / 2, h = size.height / 2
        for (i, label) in textLabels.enumerated() {
            label.position = CGPoint(x: w - 16, y: h - 14 - CGFloat(30 * i))
        }
        // A long message wraps instead of growing off screen.
        messageLabel.preferredMaxLayoutWidth = min(900, size.width - 100)
        statusLabel.position = CGPoint(x: -w + 10, y: -h + 8)
        skyNode.size = size
    }

    /// Shows 576 points (9 squares) of height and as much width as the game view's shape asks for.
    func fit(aspect: CGFloat) {
        let width = (GameScene.worldSize.height * aspect).rounded()
        if abs(width - size.width) < 1 { return }
        size = CGSize(width: width, height: GameScene.worldSize.height)
    }

    override func didChangeSize(_ oldSize: CGSize) {
        super.didChangeSize(oldSize)
        if textLabels.isEmpty { return }   // still in init
        layOutHUD()
        textBoxDirty = true
        shownLayers = []            // the layers are laid out again for the new width
        shownMessage = "\u{0}"      // ...and the message box
        for label in textLabels where !label.isHidden {
            if let text = label.text { setHUDText(label, text, maxWidth: size.width - 40) }
        }
        if let w = Runtime.shared.realWorld { cameraNode.position = cameraTarget(w) }
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
    /// are about 1,160) is scaled down, so it never runs off the left edge.
    private func setHUDText(_ label: SKLabelNode, _ text: String, maxWidth: CGFloat) {
        label.text = text
        (label.children.first as? SKLabelNode)?.text = text
        label.setScale(1)
        let width = label.frame.width
        if width > maxWidth { label.setScale(maxWidth / width) }
        textBoxDirty = true
    }

    /// Fits the box around the text lines that show (only when one changed).
    private func layOutTextBox() {
        if !textBoxDirty { return }
        textBoxDirty = false
        var box = CGRect.null
        for label in textLabels where !label.isHidden { box = box.union(label.frame) }
        if box.isNull {
            textBox.isHidden = true
            textBoxShown = .null
            return
        }
        // Whole multiples of 4 points, so a number that ticks up doesn't redraw it every frame.
        box = box.insetBy(dx: -8, dy: -5)
        let snapped = CGRect(x: (box.minX / 4).rounded(.down) * 4, y: (box.minY / 4).rounded(.down) * 4,
                             width: (box.width / 4).rounded(.up) * 4, height: (box.height / 4).rounded(.up) * 4)
        textBox.isHidden = false
        if snapped == textBoxShown { return }
        textBoxShown = snapped
        textBox.path = UIBezierPath(roundedRect: snapped, cornerRadius: 9).cgPath
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
        while !functionsStopped && accumulator >= 1.0 / 60.0 && steps < 4 {
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
            if diagnostics { print("GAMESTATS cpu: \(stepMicros) µs per step (functions+physics), \(syncMicros) µs per frame (sprite sync+HUD), things=\((runtime.realWorld?.enemies.count ?? 0) + (runtime.realWorld?.coins.count ?? 0))") }
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
        // game.soundVolume works right away (a function may have changed it in this step).
        GameAudio.shared.applyVolume()
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
        // Weather falls in a 1024 x 576 box, spread over the visible width.
        let w2 = size.width / 2, h2 = size.height / 2
        let spread = size.width / CGFloat(WeatherSystem.width)
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
            node.position = CGPoint(x: CGFloat(f.drawX) * spread - w2, y: CGFloat(f.y) - h2)
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
        skyNode.size = size
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
                let count = Int((size.width / CGFloat(layer.size)).rounded(.up)) + 2
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
        let w2 = size.width / 2, h2 = size.height / 2
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
            // The player draws above everything in the level (and the bursts and weather), and below
            // the student's text lines (101) and message (110).
            node.zPosition = t.kind == .player ? 100.5 : (t.kind.isPickup ? 2 : 3)
            node.position = CGPoint(x: t.x, y: t.y)
            worldLayer.addChild(node)
            thingNodes.append((t, node, t.emoji))
        }
    }

    func cameraTarget(_ w: World) -> CGPoint {
        let view = size
        let levelW = CGFloat(w.widthInPoints), levelH = CGFloat(w.heightInPoints)
        let x = levelW <= view.width ? levelW / 2 : min(max(CGFloat(player.x), view.width / 2), levelW - view.width / 2)
        let y = w.rows <= 9 ? view.height / 2 : min(max(CGFloat(player.y), view.height / 2), levelH - view.height / 2)
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
            textBox.fillColor = darkSky ? UIColor.black.withAlphaComponent(0.28) : UIColor.white.withAlphaComponent(0.45)
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

        // game.showText lines: this frame's (while frozen, the last frame's), top right.
        let texts = runtime.texts
        for (i, label) in textLabels.enumerated() {
            if i < texts.count {
                if label.text != texts[i] { setHUDText(label, texts[i], maxWidth: size.width - 40) }
                if label.isHidden { label.isHidden = false; textBoxDirty = true }
            } else if !label.isHidden {
                label.isHidden = true
                textBoxDirty = true
            }
        }
        layOutTextBox()
        // The student's message (the goal status is above the game, in the header).
        let message = runtime.gameMessage
        if message != shownMessage {
            shownMessage = message
            messageLabel.text = message
            messageBox.isHidden = message.isEmpty
            if !message.isEmpty {
                let frame = messageLabel.frame
                messageBox.path = UIBezierPath(roundedRect: frame.insetBy(dx: -24, dy: -14), cornerRadius: 18).cgPath
            }
        }
        if diagnostics {
            statusLabel.text = "\(stepsPerSecond) steps/s · \(framesPerSecond) fps · last key: \(lastKeySource)"
        }
        onSync()
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
    /// Rounder corners and a smaller ▲ on a small button (44 to 84 points).
    func setSide(_ side: CGFloat) {
        layer.cornerRadius = min(20, (side * 0.24).rounded())
        let size = max(20, min(34, (side * 0.42).rounded()))
        if label.font.pointSize != size { label.font = .systemFont(ofSize: size, weight: .heavy) }
    }
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

// MARK: - The goals, above the game

/// The page title, the checklist (in columns when there is room), the ⚠️ "Can't find:" notes, the
/// goal status (a pill next to the title) and the gray inspector numbers. No hints. It sits ABOVE
/// the game view and is plain UIKit, so it keeps its size when the game scales, and nothing about
/// the page's goals covers the game.
final class GoalHeaderView: UIView {
    private let titleLabel = UILabel()
    private let statusPill = UIView()
    private let statusLabel = UILabel()
    private var rowLabels: [UILabel] = []
    private var noteLabels: [UILabel] = []
    private var inspectorLabels: [UILabel] = []

    private var list = Checklist()
    private var status = ""
    /// "Tap the game to use ← → ↑" when the controller has no room for it next to the buttons:
    /// gray, in the status's place, while there is no status. It never hides the title.
    var keyHint = "" {
        didSet { if keyHint != oldValue { styleStatus(); setNeedsLayout() } }
    }
    /// How many inspector lines the page has (0 when game.showNumbers is false).
    private var inspectorSlots = 0
    /// The inspector's lines joined into one (a wide header).
    private var joinInspector = false
    /// The font scale the labels have now (0: not styled yet).
    private var scale: CGFloat = 0

    private static let ink = UIColor(white: 0.94, alpha: 1)
    private static let dim = UIColor(white: 0.80, alpha: 1)
    private static let failInk = UIColor(red: 1.0, green: 0.62, blue: 0.58, alpha: 1)
    private static let noteInk = UIColor(red: 1.0, green: 0.80, blue: 0.42, alpha: 1)
    private static let inspectorInk = UIColor(white: 0.62, alpha: 1)

    override init(frame: CGRect) {
        super.init(frame: frame)
        clipsToBounds = true
        isUserInteractionEnabled = false
        titleLabel.textColor = GoalHeaderView.ink
        titleLabel.lineBreakMode = .byTruncatingTail
        addSubview(titleLabel)
        statusPill.layer.cornerRadius = 7
        statusPill.isHidden = true
        statusLabel.textColor = .white
        statusLabel.textAlignment = .center
        statusLabel.adjustsFontSizeToFitWidth = true
        statusLabel.minimumScaleFactor = 0.7
        statusLabel.lineBreakMode = .byTruncatingTail
        statusPill.addSubview(statusLabel)
        addSubview(statusPill)
    }
    required init?(coder: NSCoder) { fatalError() }

    /// Takes the runtime's checklist, status and inspector lines. True when the header's height may
    /// change (the controller lays the view out again); the inspector's numbers alone never change it.
    func show(_ newList: Checklist, status newStatus: String, inspector: [String], slots: Int) -> Bool {
        var resized = false
        if newList != list || slots != inspectorSlots {
            list = newList
            inspectorSlots = slots
            restyle()
            resized = true
        }
        if newStatus != status {
            status = newStatus
            styleStatus()
            setNeedsLayout()
        }
        let lines = joinInspector ? [inspector.joined(separator: "     ")] : inspector
        for (i, label) in inspectorLabels.enumerated() {
            let text = i < lines.count ? lines[i] : ""
            if label.text != text { label.text = text }
        }
        return resized
    }

    /// The height for `width`, with the fonts made smaller (down to 88%) when the header would be
    /// taller than `maxHeight`. `compact` (a short live view): the inspector on one line.
    func fit(width: CGFloat, maxHeight: CGFloat, compact short: Bool = false) -> CGFloat {
        let base: CGFloat = width >= 1000 ? 1.22 : (width >= 740 ? 1.1 : 1.0)
        let join = width >= 900 || short
        if join != joinInspector { joinInspector = join; scale = 0 }
        var height: CGFloat = 0
        for step in [1.0, 0.94, 0.88] as [CGFloat] {
            let s = base * step
            if s != scale { scale = s; restyle() }
            height = layOut(width: width, apply: false)
            if height <= maxHeight { break }
        }
        return height
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        _ = layOut(width: bounds.width, apply: true)
    }

    // MARK: Styling (when the checklist, the status or the scale changes)

    private func restyle() {
        if scale == 0 { scale = 1 }
        titleLabel.font = UIFont.systemFont(ofSize: 15 * scale, weight: .bold)
        titleLabel.text = list.title
        while rowLabels.count < list.rows.count {
            let label = UILabel()
            label.numberOfLines = 0
            addSubview(label)
            rowLabels.append(label)
        }
        for (i, label) in rowLabels.enumerated() {
            label.isHidden = i >= list.rows.count
            if i >= list.rows.count { continue }
            let row = list.rows[i]
            let font = UIFont.systemFont(ofSize: 13 * scale, weight: row.firstFailure ? .bold : .medium)
            let color = row.firstFailure ? GoalHeaderView.failInk : (row.mark == "✅" ? GoalHeaderView.ink : GoalHeaderView.dim)
            // A row that wraps goes on under its text, not under its ✅.
            let mark = NSAttributedString(string: row.mark + " ", attributes: [.font: font])
            let paragraph = NSMutableParagraphStyle()
            paragraph.headIndent = ceil(mark.size().width)
            label.attributedText = NSAttributedString(string: row.mark + " " + row.text,
                                                      attributes: [.font: font, .foregroundColor: color, .paragraphStyle: paragraph])
        }
        while noteLabels.count < list.notes.count {
            let label = UILabel()
            label.numberOfLines = 0
            addSubview(label)
            noteLabels.append(label)
        }
        for (i, label) in noteLabels.enumerated() {
            label.isHidden = i >= list.notes.count
            if i >= list.notes.count { continue }
            label.attributedText = GoalHeaderView.styled(list.notes[i].text, size: 12 * scale, color: GoalHeaderView.noteInk)
        }
        let slots = joinInspector ? min(inspectorSlots, 1) : inspectorSlots
        while inspectorLabels.count < 2 {
            let label = UILabel()
            label.textColor = GoalHeaderView.inspectorInk
            label.adjustsFontSizeToFitWidth = true
            label.minimumScaleFactor = 0.6
            label.lineBreakMode = .byTruncatingTail
            addSubview(label)
            inspectorLabels.append(label)
        }
        for (i, label) in inspectorLabels.enumerated() {
            label.isHidden = i >= slots
            label.font = UIFont.monospacedSystemFont(ofSize: 10.5 * scale, weight: .regular)
        }
        styleStatus()
        setNeedsLayout()
    }

    private func styleStatus() {
        let shown = status.isEmpty ? keyHint : status
        statusPill.isHidden = shown.isEmpty
        statusLabel.text = shown
        statusLabel.font = UIFont.systemFont(ofSize: 13 * (scale == 0 ? 1 : scale), weight: status.isEmpty ? .semibold : .bold)
        statusLabel.textColor = status.isEmpty ? UIColor(white: 0.86, alpha: 1) : .white
        if status.isEmpty {
            statusPill.backgroundColor = UIColor(white: 0.26, alpha: 1)
        } else if status.hasPrefix("✅") {
            statusPill.backgroundColor = UIColor(red: 0.13, green: 0.58, blue: 0.29, alpha: 1)
        } else if status.hasPrefix("Almost") {
            statusPill.backgroundColor = UIColor(red: 0.85, green: 0.40, blue: 0.10, alpha: 1)
        } else {
            statusPill.backgroundColor = UIColor(red: 0.20, green: 0.42, blue: 0.82, alpha: 1)
        }
    }

    /// A note: its `code` spans in a monospaced font (a short one never breaks), the
    /// backticks dropped.
    static func styled(_ text: String, size: CGFloat, color: UIColor) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let plain: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: size, weight: .medium), .foregroundColor: color]
        let code: [NSAttributedString.Key: Any] = [.font: UIFont.monospacedSystemFont(ofSize: size - 0.5, weight: .semibold), .foregroundColor: color]
        for (i, part) in text.split(separator: "`", omittingEmptySubsequences: false).enumerated() {
            var piece = String(part)
            if i % 2 == 1 && piece.count <= 28 { piece = piece.replacingOccurrences(of: " ", with: "\u{00A0}") }
            result.append(NSAttributedString(string: piece, attributes: i % 2 == 1 ? code : plain))
        }
        return result
    }

    // MARK: Layout (measured with apply: false, placed with apply: true)

    private func layOut(width: CGFloat, apply: Bool) -> CGFloat {
        let padX: CGFloat = 12, padY: CGFloat = 7
        let inner = max(40, width - 2 * padX)
        let huge: CGFloat = 10_000
        var y = padY

        // Title row: the title, and the status pill on the right (in the title's place when both
        // don't fit). Its height never depends on the status, so a status never moves the game.
        let titleFont = titleLabel.font ?? UIFont.systemFont(ofSize: 15)
        let statusFont = statusLabel.font ?? UIFont.systemFont(ofSize: 13)
        let rowHeight = ceil(max(titleFont.lineHeight, statusFont.lineHeight + 6))
        let titleWidth = min(inner, ceil(titleLabel.sizeThatFits(CGSize(width: huge, height: huge)).width))
        if apply {
            let shown = status.isEmpty ? keyHint : status
            let wanted = shown.isEmpty ? 0 : ceil(statusLabel.sizeThatFits(CGSize(width: huge, height: huge)).width) + 20
            let besides = titleWidth + 14 + wanted <= inner
            if shown.isEmpty {
                titleLabel.isHidden = false
                titleLabel.frame = CGRect(x: padX, y: y, width: inner, height: rowHeight)
            } else if status.isEmpty {
                // The key hint takes what the title leaves (its font shrinks to 70%), or waits.
                let left = inner - titleWidth - 14
                let pillWidth = min(wanted, left)
                titleLabel.isHidden = false
                titleLabel.frame = CGRect(x: padX, y: y, width: titleWidth, height: rowHeight)
                statusPill.isHidden = pillWidth < wanted * 0.7
                statusPill.frame = CGRect(x: padX + inner - max(0, pillWidth), y: y, width: max(0, pillWidth), height: rowHeight)
                statusLabel.frame = statusPill.bounds.insetBy(dx: 8, dy: 0)
            } else {
                let pillWidth = min(inner, wanted)
                titleLabel.isHidden = !besides
                titleLabel.frame = CGRect(x: padX, y: y, width: titleWidth, height: rowHeight)
                statusPill.frame = CGRect(x: besides ? padX + inner - pillWidth : padX, y: y, width: pillWidth, height: rowHeight)
                statusLabel.frame = statusPill.bounds.insetBy(dx: 8, dy: 0)
            }
        }
        y += rowHeight + 4

        // The checklist, row by row in up to 3 columns.
        let count = list.rows.count
        let gap: CGFloat = 16
        let fitColumns = Int((inner + gap) / (215 * scale + gap))
        let columns = max(1, min(3, min(fitColumns, count)))
        let columnWidth = (inner - CGFloat(columns - 1) * gap) / CGFloat(columns)
        var i = 0
        while i < count {
            var lineHeight: CGFloat = 0
            for c in 0..<columns where i + c < count {
                let label = rowLabels[i + c]
                let h = ceil(label.sizeThatFits(CGSize(width: columnWidth, height: huge)).height)
                if apply { label.frame = CGRect(x: padX + CGFloat(c) * (columnWidth + gap), y: y, width: columnWidth, height: h) }
                lineHeight = max(lineHeight, h)
            }
            y += lineHeight + 3
            i += columns
        }
        if count > 0 { y += 1 }

        // ⚠️ "Can't find:" notes.
        for label in noteLabels where !label.isHidden {
            let h = ceil(label.sizeThatFits(CGSize(width: inner, height: huge)).height)
            if apply { label.frame = CGRect(x: padX, y: y, width: inner, height: h) }
            y += h + 3
        }

        // The inspector: one line each, the same height whatever the numbers are.
        for label in inspectorLabels where !label.isHidden {
            let h = ceil((label.font ?? UIFont.systemFont(ofSize: 10)).lineHeight)
            if apply { label.frame = CGRect(x: padX, y: y, width: inner, height: h) }
            y += h + 1
        }
        return ceil(y + padY - 3)
    }
}

// MARK: - Live view controller

final class GameViewController: UIViewController, PlaygroundLiveViewSafeAreaContainer {
    let skView = SKView()
    let scene = GameScene(size: GameScene.worldSize)
    /// The page's goals, above the game.
    let header = GoalHeaderView()
    /// The game view's shape (width / height): narrower shows less of the level, wider more.
    static let narrowest: CGFloat = 1.4
    static let widest: CGFloat = 2.4
    let leftButton = HoldButton(title: "◀")
    let rightButton = HoldButton(title: "▶")
    let upButton = HoldButton(title: "▲")
    /// Hidden until a function asks about .down.
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
        view.addSubview(header)
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
        scene.onSync = { [weak self] in self?.updateHeader() }
        scene.onUsesDown = { [weak self] in
            guard let self else { return }
            self.downButton.isHidden = false
            self.keyHintLabel.text = "Tap the game to use ←\u{00A0}→\u{00A0}↑\u{00A0}↓"   // the arrows never split
            self.view.setNeedsLayout()
        }
        setUpKeyHint()
    }

    /// Runs after the page's top-level code: test drives, then the level, then the 60 Hz loop.
    func begin(_ box: StartBox) {
        // viewDidLoad hooks up the ▼ button and the key hint, so load the view first: Swift
        // Playgrounds may not have shown it yet.
        loadViewIfNeeded()
        scene.diagnostics = box.diagnostics
        let runtime = Runtime.shared
        runtime.begin(page: box.page, functions: box.functions, runChecks: !box.stepMode)
        // Start the audio before the level shows when this page will play sounds: its checks
        // played one, or it comes at or after Sounds (from there on the book's own code plays a
        // jump and a coin sound). Started any later, the first sound would set up the audio in
        // the middle of a frame (a stutter) and be lost. Pages before Sounds never touch the audio.
        let order = GamePage.allCases
        let playsSounds = (order.firstIndex(of: box.page) ?? 0) >= (order.firstIndex(of: .sounds) ?? 0)
        if !box.stepMode && (runtime.checksPlayedSound || playsSounds) {
            GameAudio.shared.prewarm()
        }
        if box.stepMode {
            // Stays up, and the functions never run (see the top of this file).
            runtime.showMessage("Switch to Run My Code (the ⏱ menu)")
            runtime.gameMessageFrames = Int.max
            scene.functionsStopped = true
        }
        if box.diagnostics { print("GAMESTATS checks took \(runtime.checkMilliseconds) ms") }
        scene.rebuild()
        scene.ready = true
        keyHintOn = !sawArrowKey
        showKeyHint()
        grabKeyboard(retries: 10)
    }

    /// Copies the checklist, the goal status and the inspector into the header (every frame).
    func updateHeader() {
        let runtime = Runtime.shared
        let slots = game.showNumbers ? (runtime.info.inspect.isEmpty ? 1 : 2) : 0
        if header.show(runtime.checklist(), status: runtime.status, inspector: runtime.inspectorLines, slots: slots) {
            view.setNeedsLayout()
        }
    }

    /// Top to bottom: the goals, the game, the buttons. The buttons always have their own strip
    /// under the game, never over it: in a short live view (Swift Playground's pane on a Mac) they
    /// and their gaps get smaller first, down to 44 points. In a tall live view the goals, the game
    /// and the buttons stay together in the middle. The "Tap the game" hint goes between the
    /// buttons, under them, or in the header: never over the game.
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var safe = liveViewSafeAreaGuide.layoutFrame
        if safe.width < 10 || safe.height < 10 { safe = view.bounds }
        // The goals: about 40% of the height at most (the header makes its fonts smaller first).
        let fitted = header.fit(width: safe.width, maxHeight: safe.height * 0.4, compact: safe.height < 380)
        let headerHeight = min(fitted, safe.height * 0.6)
        let area = CGRect(x: safe.minX, y: safe.minY + headerHeight, width: safe.width, height: safe.height - headerHeight)

        var gap: CGFloat = area.height < 420 ? 10 : 14
        // Four buttons (with ▼) need about 420 points: in a narrower live view they shrink.
        let count: CGFloat = downButton.isHidden ? 3 : 4
        var button = max(52, min(84, (safe.width - 2 * 16 - 2 * gap - 40 - (count - 3) * gap) / count))
        // The strip takes the height the game can't use (its shape stops it), or 15% of the area.
        let room = max(area.height - gameFrame(in: area).height, area.height * 0.15)
        if button + 2 * gap > room {
            button = max(44, min(button, (room - 20).rounded(.down)))
            gap = max(6, min(gap, ((room - button) / 2).rounded(.down)))
        }
        let strip = button + 2 * gap
        var game = gameFrame(in: CGRect(x: area.minX, y: area.minY, width: area.width, height: area.height - strip))
        let inset: CGFloat = 16
        // The buttons line up with the game's edges, or spread wider when a small game can't fit them.
        let needed = 2 * inset + count * (button + gap) + 40
        var row = game
        if row.width < needed { row = row.insetBy(dx: -min((needed - row.width) / 2, (safe.width - row.width) / 2), dy: 0) }
        let place = keyHintPlace(row: row, button: button, gap: gap, inset: inset, count: count,
                                 spare: area.height - game.height - strip)
        // A tall live view: everything moves down by half of what's left.
        var used = headerHeight + game.height + strip
        if place == .below { used += keyHint.frame.height + 6 }
        let shift = max(0, ((safe.height - used) / 2).rounded(.down))
        header.frame = CGRect(x: safe.minX, y: safe.minY + shift, width: safe.width, height: headerHeight)
        game.origin.y += shift
        row.origin.y += shift
        skView.frame = game
        scene.fit(aspect: game.width / game.height)
        let y = game.maxY + gap
        leftButton.frame = CGRect(x: row.minX + inset, y: y, width: button, height: button)
        rightButton.frame = CGRect(x: row.minX + inset + button + gap, y: y, width: button, height: button)
        upButton.frame = CGRect(x: row.maxX - inset - button, y: y, width: button, height: button)
        downButton.frame = CGRect(x: upButton.frame.minX - gap - button, y: y, width: button, height: button)
        for b in [leftButton, rightButton, upButton, downButton] { b.setSide(button) }
        switch place {
        case .between:
            let left = rightButton.frame.maxX + gap
            let right = (downButton.isHidden ? upButton.frame.minX : downButton.frame.minX) - gap
            keyHint.center = CGPoint(x: ((left + right) / 2).rounded(), y: (y + button / 2).rounded())
        case .below:
            keyHint.center = CGPoint(x: game.midX.rounded(), y: (y + button + gap + 6 + keyHint.frame.height / 2).rounded())
        case .header:
            break
        }
        keyHintLabel.frame = keyHint.bounds.insetBy(dx: 10, dy: 6)
        keyHintInHeader = place == .header
        showKeyHint()
    }

    /// The biggest game view at the top of `area`, centered, between `narrowest` and `widest` in shape.
    private func gameFrame(in area: CGRect) -> CGRect {
        let height = max(60, min(area.height, area.width / GameViewController.narrowest))
        let width = min(area.width, height * GameViewController.widest)
        return CGRect(x: (area.midX - width / 2).rounded(), y: area.minY, width: width.rounded(), height: height.rounded())
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
        keyHintLabel.text = "Tap the game to use ←\u{00A0}→\u{00A0}↑"
        keyHintLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        keyHintLabel.textColor = .white
        keyHintLabel.textAlignment = .center
        keyHintLabel.numberOfLines = 2
        keyHintLabel.adjustsFontSizeToFitWidth = true
        keyHintLabel.minimumScaleFactor = 0.75
        keyHint.addSubview(keyHintLabel)
        view.addSubview(keyHint)
    }

    private enum KeyHintPlace { case between, below, header }
    /// Between begin() and the first arrow key.
    private var keyHintOn = false
    private var keyHintInHeader = false

    /// Where the hint goes (and its size): between ▶ and ▲ (or ▼) when it fits there, on 2 lines if
    /// it must; under the buttons when a tall live view has the room; otherwise in the header.
    private func keyHintPlace(row: CGRect, button: CGFloat, gap: CGFloat, inset: CGFloat, count: CGFloat,
                              spare: CGFloat) -> KeyHintPlace {
        let pad: CGFloat = 10
        let room = row.width - 2 * inset - count * button - count * gap   // between ▶ and ▲ (or ▼)
        let one = keyHintLabel.sizeThatFits(CGSize(width: 1000, height: 100))
        var size = CGSize(width: ceil(one.width) + 2 * pad, height: ceil(one.height) + 12)
        var place = KeyHintPlace.header
        if size.width <= room {
            place = .between
        } else if room - 2 * pad >= 110 {
            let two = keyHintLabel.sizeThatFits(CGSize(width: room - 2 * pad, height: 100))
            if ceil(two.height) + 12 <= button {
                place = .between
                size = CGSize(width: room, height: ceil(two.height) + 12)
            }
        }
        if place == .header && spare >= size.height + 12 && size.width <= row.width {
            place = .below
        }
        keyHint.bounds = CGRect(origin: .zero, size: size)
        return place
    }

    /// Shows the hint in its place (the header's, or its own view), or nowhere once an arrow key came.
    private func showKeyHint() {
        if !keyHintOn {
            header.keyHint = ""
            return
        }
        keyHint.isHidden = keyHintInHeader
        keyHint.alpha = 1
        header.keyHint = keyHintInHeader ? (keyHintLabel.text ?? "") : ""
    }

    private func arrowKeyArrived() {
        if sawArrowKey { return }
        sawArrowKey = true
        keyHintOn = false
        header.keyHint = ""
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
