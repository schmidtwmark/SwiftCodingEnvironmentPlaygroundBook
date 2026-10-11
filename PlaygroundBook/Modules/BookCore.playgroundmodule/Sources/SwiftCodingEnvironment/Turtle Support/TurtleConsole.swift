//
//  TurtleConsole.swift
//  StudentCodeTemplate
//
//  Created by Mark Schmidt on 11/16/24.
//

import SwiftUI
import SpriteKit
import PlaygroundSupport

public enum TurtleSceneCommand: Sendable {
    case addTurtle
    case turtleAction(UUID, TurtleCommand)
}

public enum TurtleSceneResponse: Sendable {
    case added(UUID)
    case actionFinished(UUID, TurtleCommand)
}

extension TurtleSceneResponse: ConsoleMessage {
    public init?(_ playgroundValue: PlaygroundValue) {
        guard case let .dictionary(dict) = playgroundValue else {
            return nil
        }
        
        guard case let .string(command)? = dict["Command"] else {
            return nil
        }
        switch command {
            
        case "Added":
            guard case let .string(id)? = dict["ID"] else { return nil }
            guard let uuid = UUID(uuidString: id) else { return nil }
            self = .added(uuid)
        case "ActionFinished":
            guard case let .string(id)? = dict["ID"] else { return nil }
            guard let uuid = UUID(uuidString: id) else { return nil }
            guard let command = dict["TurtleCommand"] else { return nil }
            guard let turtleCommand = TurtleCommand(command) else { return nil }
            self = .actionFinished(uuid, turtleCommand)
        default: return nil
        }
    }
    
    public var playgroundValue: PlaygroundValue {
        switch self {
        case .added(let uuid):
            return .dictionary([
                "Command": .string("Added"),
                "ID": .string(uuid.uuidString)
            ])
        case .actionFinished(let uuid, let command):
            return .dictionary([
                "Command": .string("ActionFinished"),
                "ID": .string(uuid.uuidString),
                "TurtleCommand": command.playgroundValue
                ])
            }
    }
}

extension TurtleSceneCommand: ConsoleMessage {
    public init?(_ playgroundValue: PlaygroundValue) {
        guard case let .dictionary(dict) = playgroundValue else {
            return nil
        }
        
        guard case let .string(command)? = dict["Command"] else {
            return nil
        }
        
        switch command {
            case "AddTurtle":
                self = .addTurtle
            case "TurtleAction":
                guard case let .string(id)? = dict["ID"] else { return nil }
                guard let uuid = UUID(uuidString: id) else { return nil }
                guard case let .dictionary(actionDict)? = dict["Action"] else { return nil }
                guard let action = TurtleCommand(.dictionary(actionDict)) else { return nil }
                self = .turtleAction(uuid, action)
            default: return nil
        }
    }
    public var playgroundValue: PlaygroundValue {
        switch self {
        case .addTurtle:
            return .dictionary(["Command": .string("AddTurtle")])
        case .turtleAction(let uuid, let action):
            return .dictionary([
                "Command": .string("TurtleAction"),
                "ID": .string(uuid.uuidString),
                "Action": action.playgroundValue
            ])
        }
    }
}

public enum TurtleCommand: @unchecked Sendable {
    case forward(CGFloat)
    case penUp
    case penDown(Color)
    case rotate(CGFloat)
    case arc(CGFloat, CGFloat)
    case oval(CGFloat, CGFloat, CGFloat)
    case lineColor(Color)
    case lineWidth(CGFloat)
    case backgroundColor(Color)
    case visible(Bool)
    case goTo(CGFloat, CGFloat)
    case setHeading(CGFloat)
}

extension TurtleCommand : ConsoleMessage {
    public init?(_ playgroundValue: PlaygroundValue) {
        guard case let .dictionary(dict) = playgroundValue else {
            return nil
        }
        
        guard case let .string(command)? = dict["Command"] else {
            return nil
        }
        
        switch command {
            case "Forward":
                guard case let .floatingPoint(distance)? = dict["Distance"] else { return nil }
                self = .forward(distance)
            case "PenUp":
                self = .penUp
            case "PenDown":
                guard case let .integer(hex)? = dict["FillColor"] else { return nil }
                self = .penDown(Color(hex: hex))
            case "Rotate":
                guard case let .floatingPoint(angle)? = dict["Angle"] else { return nil }
                self = .rotate(angle)
            case "Arc":
                guard case let .floatingPoint(radius)? = dict["Radius"] else { return nil }
                guard case let .floatingPoint(angle)? = dict["Angle"] else { return nil }
                self = .arc(radius, angle)
            case "Oval":
                guard case let .floatingPoint(xRadius)? = dict["XRadius"] else { return nil }
                guard case let .floatingPoint(yRadius)? = dict["YRadius"] else { return nil }
                guard case let .floatingPoint(angle)? = dict["Angle"] else { return nil }
                self = .oval(xRadius, yRadius, angle)
            case "LineColor":
                guard case let .integer(hex)? = dict["Color"] else { return nil }
                self = .lineColor(Color(hex: hex))
            case "LineWidth":
                guard case let .floatingPoint(width)? = dict["Width"] else { return nil }
                self = .lineWidth(width)
            case "BackgroundColor":
                guard case let .integer(hex)? = dict["Color"] else { return nil }
                self = .backgroundColor(Color(hex: hex))
            case "Visible":
                guard case let .boolean(visible)? = dict["Visible"] else { return nil }
                self = .visible(visible)
            case "GoTo":
                guard case let .floatingPoint(x)? = dict["X"] else { return nil }
                guard case let .floatingPoint(y)? = dict["Y"] else { return nil }
                self = .goTo(x, y)
            case "SetHeading":
                guard case let .floatingPoint(angle)? = dict["Angle"] else { return nil }
                self = .setHeading(angle)
            default: return nil
        }
    }
    
    public var playgroundValue: PlaygroundValue {
        switch self {
        case .forward(let distance):
            return .dictionary(["Command": .string("Forward"), "Distance": .floatingPoint(distance)])
        case .penUp:
            return .dictionary(["Command": .string("PenUp")])
        case .penDown(let fillColor):
            return .dictionary(["Command": .string("PenDown"), "FillColor": .integer(fillColor.hex)])
        case .rotate(let angle):
            return .dictionary(["Command": .string("Rotate"), "Angle": .floatingPoint(angle)])
        case .arc(let radius, let angle):
            return .dictionary(["Command": .string("Arc"), "Radius": .floatingPoint(radius), "Angle": .floatingPoint(angle)])
        case .oval(let xRadius, let yRadius, let angle):
            return .dictionary([
                "Command": .string("Oval"),
                "XRadius": .floatingPoint(xRadius),
                "YRadius": .floatingPoint(yRadius),
                "Angle": .floatingPoint(angle)
            ])
        case .lineColor(let color):
            return .dictionary(["Command": .string("LineColor"), "Color": .integer(color.hex)])
        case .lineWidth(let width):
            return .dictionary(["Command": .string("LineWidth"), "Width": .floatingPoint(width)])
        case .backgroundColor(let color):
            return .dictionary(["Command": .string("BackgroundColor"), "Color": .integer(color.hex)])
        case .visible(let visible):
            return .dictionary(["Command": .string("Visible"), "Visible": .boolean(visible)])
        case .goTo(let x, let y):
            return .dictionary(["Command": .string("GoTo"), "X": .floatingPoint(x), "Y": .floatingPoint(y)])
        case .setHeading(let angle):
            return .dictionary(["Command": .string("SetHeading"), "Angle": .floatingPoint(angle)])
        }
    }
}

extension CGFloat {
    var radians: CGFloat {
        return self * .pi / 180
    }
}

public class Turtle: SKSpriteNode {
    private var rotation: CGFloat = 0

    private enum PenState {
        case up
        case down(CGMutablePath, SKShapeNode, /* fillColor */ UIColor)
    }
    
    private var lineWidth: CGFloat = 3.0
    private var penState: PenState = .up
    private let console: TurtleConsole
    
    private static func texture() -> SKTexture {
//        let image = UIImage(resource: .init(name: "arrow", bundle: Bundle.module))
        let image = UIImage(named: "arrow") ?? UIImage(systemName: "arrow.right")!
        return SKTexture(image: image)
    }
    
    init(console: TurtleConsole) {
        self.console = console
        let texture = Turtle.texture()
        super.init(texture: texture, color: .systemBlue, size: CGSize(width: 32.0, height: 32.0))
        self.colorBlendFactor = 1.0
        self.zPosition = 1
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    public func forward(_ distance: CGFloat) async {
        let dx = distance * cos(self.rotation)
        let dy = distance * sin(self.rotation)
        let start = self.position
        let end = CGPointMake(start.x + dx, start.y + dy)
        let moveAction = SKAction.move(to: end, duration: abs(distance) / MOVEMENT_SPEED_0)
        await self.runAsync(moveAction)
    }
    
    private func runAsync(_ action: SKAction) async {
        guard console.state == .running else { return}
        
        await withCheckedContinuation { continuation in
            self.run(action) {
                // The frame update may run before the move finishes, so add its exact end point.
                self.update()
                continuation.resume()
            }
        }
    }
    
    
    // Trace the path of an arc with a certain radius for @param angle degrees
    // This should both move and rotate the turtle so it is always facing tangent to the circle.
    // Positive angles go left, negative angles go right (from perspective of turtle)
    public func arc(radius: CGFloat, angle: CGFloat) async {
        guard radius >= 0 else {
            return
        }
        
        let counterclockwise = angle >= 0
        let directionMultiplier : CGFloat = counterclockwise ? 1.0 : -1.0
        let center = CGPoint(x: -directionMultiplier * sin(self.rotation) * radius, y: directionMultiplier * cos(self.rotation) * radius)
        
        let startOffset: CGFloat = counterclockwise ? 270.0 : 90.0
        let path = CGMutablePath()
        path.addRelativeArc(center: center, radius: radius, startAngle: startOffset.radians + self.rotation, delta: angle.radians)
        
        let circumference = abs(2 * .pi * radius * angle / 360)
        let duration = circumference / MOVEMENT_SPEED_0
    
        
        
        let start = self.position
        let endOffset = path.currentPoint
        self.rotation += angle.radians
        let rotateAction = SKAction.rotate(byAngle: angle.radians, duration: duration)
        let followAction = SKAction.follow(path, asOffset: true , orientToPath: false, duration: duration)
        let group = SKAction.group([rotateAction, followAction])

        await self.runAsync(group)
        // SpriteKit's follow action can stop short of the end of the path, by more at higher speeds (fewer
        // frames per arc). Over many arcs that drift bent drawings, so land exactly on the end.
        if console.state == .running {
            self.position = CGPoint(x: start.x + endOffset.x, y: start.y + endOffset.y)
            self.zRotation = self.rotation
            self.update()
        }
            
    }

    // Trace an elliptical arc with two radii for @param angle degrees.
    // xRadius is the semi-axis along the turtle's heading; yRadius is perpendicular
    // (the distance from the turtle to the ellipse center, matching `arc`'s radius).
    // Positive angles go left, negative angles go right.
    public func oval(xRadius: CGFloat, yRadius: CGFloat, angle: CGFloat) async {
        guard xRadius >= 0, yRadius >= 0, angle != 0 else { return }

        let counterclockwise = angle >= 0
        let directionMultiplier: CGFloat = counterclockwise ? 1.0 : -1.0
        let startT: CGFloat = counterclockwise ? (3 * .pi / 2) : (.pi / 2)
        let deltaT = angle.radians

        let steps = max(Int(abs(angle) / 2.0), 16)
        let cosR = cos(self.rotation)
        let sinR = sin(self.rotation)

        var offsets: [CGPoint] = []
        var tangentAngles: [CGFloat] = []

        for i in 0...steps {
            let t = startT + CGFloat(i) / CGFloat(steps) * deltaT
            let localX = xRadius * cos(t)
            let localY = directionMultiplier * yRadius + yRadius * sin(t)
            let dx = localX * cosR - localY * sinR
            let dy = localX * sinR + localY * cosR
            offsets.append(CGPoint(x: dx, y: dy))

            let localTanX: CGFloat = counterclockwise ? -xRadius * sin(t) : xRadius * sin(t)
            let localTanY: CGFloat = counterclockwise ? yRadius * cos(t) : -yRadius * cos(t)
            let tanX = localTanX * cosR - localTanY * sinR
            let tanY = localTanX * sinR + localTanY * cosR
            tangentAngles.append(atan2(tanY, tanX))
        }

        var segmentLengths: [CGFloat] = []
        var arcLength: CGFloat = 0
        for i in 1...steps {
            let ddx = offsets[i].x - offsets[i - 1].x
            let ddy = offsets[i].y - offsets[i - 1].y
            let len = sqrt(ddx * ddx + ddy * ddy)
            segmentLengths.append(len)
            arcLength += len
        }
        let totalDuration = arcLength / MOVEMENT_SPEED_0

        var actions: [SKAction] = []
        for i in 1...steps {
            let ddx = offsets[i].x - offsets[i - 1].x
            let ddy = offsets[i].y - offsets[i - 1].y
            let segmentDuration = arcLength > 0 ? totalDuration * segmentLengths[i - 1] / arcLength : 0

            var rotationDelta = tangentAngles[i] - tangentAngles[i - 1]
            if rotationDelta > .pi { rotationDelta -= 2 * .pi }
            if rotationDelta < -.pi { rotationDelta += 2 * .pi }

            let move = SKAction.moveBy(x: ddx, y: ddy, duration: segmentDuration)
            let rotate = SKAction.rotate(byAngle: rotationDelta, duration: segmentDuration)
            actions.append(SKAction.group([move, rotate]))
        }

        self.rotation += deltaT
        await self.runAsync(SKAction.sequence(actions))
    }

    // Move in a straight line to a point, keeping the same heading. (0, 0) is where the turtle started.
    public func goTo(_ point: CGPoint) async {
        let distance = hypot(point.x - position.x, point.y - position.y)
        await self.runAsync(SKAction.move(to: point, duration: distance / MOVEMENT_SPEED_0))
    }

    // Turn to face a direction, the short way around: 0 is right, 90 is up, 180 is left, 270 is down.
    public func setHeading(_ angle: CGFloat) async {
        var delta = (angle.radians - rotation).truncatingRemainder(dividingBy: 2 * .pi)
        if delta > .pi { delta -= 2 * .pi }
        if delta < -.pi { delta += 2 * .pi }
        await rotate(delta * 180 / .pi)
    }

   public func rotate(_ angle: CGFloat) async {
       self.rotation += angle.radians
       let rotateAction = SKAction.rotate(byAngle: angle.radians, duration: abs(angle / ROTATION_SPEED_0))
       await self.runAsync(rotateAction)
       // Keep the arrow pointing exactly along the heading the next move will use.
       if console.state == .running {
           self.zRotation = self.rotation
       }
    }
    
    public func setColor(_ color: UIColor) async {
        self.color = color
        if case .down(_, _, let fill) = self.penState {
            // Call penDown again so the next section has the right color
            self.penDown(fillColor: fill)
        }
    }
    
    public func penDown(fillColor: UIColor = .clear) {
        let path = CGMutablePath()
        path.move(to: self.position)
        let pathNode = SKShapeNode()
        pathNode.strokeColor = self.color
        pathNode.lineWidth = self.lineWidth
        pathNode.fillColor = fillColor
        pathNode.lineCap = .square
        self.scene?.addChild(pathNode)
        self.penState = .down(path, pathNode, fillColor)
    }
    
    
    func update() {
        if case .down(let path, let pathNode, _) = penState, path.currentPoint != self.position {
            path.addLine(to: self.position)
            pathNode.path = path
        }
    }
    
    public func penUp() {
        self.penState = .up
    }
    
    public func lineWidth(_ width: CGFloat) {
        self.lineWidth = width
        if case .down(_, _, let fill) = self.penState {
            self.penDown(fillColor: fill)
        }
    }
    
    func action(_ command: TurtleCommand) async {
        switch command {
        case .forward(let distance):
            await forward(distance)
        case .penUp:
            penUp()
        case .penDown(let fillColor):
            penDown(fillColor: UIColor(fillColor))
        case .rotate(let angle):
            await rotate(angle)
        case .arc(let radius, let angle):
            await arc(radius: radius, angle: angle)
        case .oval(let xRadius, let yRadius, let angle):
            await oval(xRadius: xRadius, yRadius: yRadius, angle: angle)
        case .lineColor(let color):
            await setColor(UIColor(color))
        case .lineWidth(let width):
            lineWidth(width)
        case .backgroundColor(let color):
            console.setBackground(UIColor(color))
        case .visible(let visible):
            isHidden = !visible
        case .goTo(let x, let y):
            await goTo(CGPoint(x: x, y: y))
        case .setHeading(let angle):
            await setHeading(angle)
        }
    }
}

let ROTATION_SPEED_0 = 360.0 // degrees / second
let MOVEMENT_SPEED_0 = 200.0 // points / second

class TurtleScene: SKScene {
    
    var cameraNode: SKCameraNode? // Reference for the camera
    var cameraLocked = true
    
    var showCameraLock: Bool {
        getOnlyTurtle() != nil && !cameraLocked
    }
    
    func getOnlyTurtle() -> Turtle? {
        
        var onlyTurtle: Turtle? = nil
        
        for node in children {
            if let turtle = node as? Turtle {
                if onlyTurtle == nil {
                    onlyTurtle = turtle
                } else {
                    return nil
                }
            }
        }
        return onlyTurtle
    }
    
    func setupCamera() {
        let camera = SKCameraNode()
        self.cameraNode = camera
        self.camera = camera
        addChild(camera)
    }
    
    override func didMove(to view: SKView) {
        setupCamera()
        
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
            view.addGestureRecognizer(panGesture)
            
        // Add pinch gesture recognizer
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinchGesture(_:)))
        view.addGestureRecognizer(pinchGesture)
    }
    
    @objc func handlePanGesture(_ sender: UIPanGestureRecognizer) {
        guard let cameraNode = self.cameraNode else { return }
        
        cameraLocked = false
        
        let translation = sender.translation(in: self.view)
        let sceneTranslation = CGPoint(x: translation.x, y: -translation.y) // Invert Y because SpriteKit's coordinate system is flipped.
        
        cameraNode.position = CGPoint(
            x: cameraNode.position.x - sceneTranslation.x,
            y: cameraNode.position.y - sceneTranslation.y
        )

        sender.setTranslation(.zero, in: self.view) // Reset translation to avoid compounding
    }
    
    @objc func handlePinchGesture(_ sender: UIPinchGestureRecognizer) {
        guard let cameraNode = self.cameraNode else { return }
        
        if sender.state == .changed {
            let zoomFactor = sender.scale
            let newScale = cameraNode.xScale / zoomFactor // In SpriteKit, smaller scale zooms in
            
            // Clamp the scale to prevent over-zooming
            let minScale: CGFloat = 0.5
            let maxScale: CGFloat = 5.0
            cameraNode.setScale(max(min(newScale, maxScale), minScale))
            
            sender.scale = 1.0 // Reset scale to avoid compounding
        }
    }
    
    func clampCameraPosition() {
        guard let cameraNode = self.cameraNode else { return }
        
        // .resizeFill makes the scene the size of the view, so its size can't be the limit.
        let limit: CGFloat = 2500
        let xRange = SKRange(lowerLimit: -limit, upperLimit: limit)
        let yRange = SKRange(lowerLimit: -limit, upperLimit: limit)
        
        cameraNode.position.x = max(min(cameraNode.position.x, xRange.upperLimit), xRange.lowerLimit)
        cameraNode.position.y = max(min(cameraNode.position.y, yRange.upperLimit), yRange.lowerLimit)
    }
    
    func animateCameraToMovingTarget(target: SKNode, duration: TimeInterval = 0.5) {
        guard let camera = self.cameraNode else { return }
        
        // Stop any current camera actions
        camera.removeAllActions()
        
        // Create a new action to move toward the target's position
        let moveAction = SKAction.move(to: target.position, duration: duration)
        moveAction.timingMode = .easeInEaseOut
        
        // Run the action
        camera.run(moveAction)
    }
    
    func lockCamera() {
        cameraLocked = true
    }

    
    override func update(_ currentTime: TimeInterval) {
       clampCameraPosition()
       for node in children {
           if let turtle = node as? Turtle {
               turtle.update()
           }
        }
        
        if cameraLocked {
            guard let camera = self.cameraNode, let target = getOnlyTurtle() else { return }
                
            // Smoothly interpolate the camera's position toward the target's position
            let lerpFactor: CGFloat = 0.1 // Adjust for smoother or quicker follow
            let newPosition = CGPoint(
                x: camera.position.x + (target.position.x - camera.position.x) * lerpFactor,
                y: camera.position.y + (target.position.y - camera.position.y) * lerpFactor
            )
            
            camera.position = newPosition
        }
    }

}

extension CGSize {
    var midpoint : CGPoint {
        CGPoint(x: width / 2, y: height / 2)
    }
}

@MainActor
public final class TurtleConsole: BaseConsole<TurtleConsole>, Console, @unchecked Sendable {
    
    var turtleMap: [UUID: Turtle] = [:]
    public func receive(_ message: PlaygroundSupport.PlaygroundValue) {
        guard let command = TurtleSceneCommand(message) else { return }
        
        switch command {
        case .addTurtle:
            addTurtle()
        case .turtleAction(let turtleId, let action):
            Task {
                await turtleMap[turtleId]?.action(action)
                messageHandler?.send(TurtleSceneResponse.actionFinished(turtleId, action).playgroundValue)
            }
        }
    }
    
    
    // The canvas stays the same light gray in light and dark mode, so drawings (and the pictures on the
    // tutorial pages) look the same on every iPad. turtle.backgroundColor(_:) changes it until the next run.
    static let defaultBackground = UIColor(red: 0xF2 / 255.0, green: 0xF2 / 255.0, blue: 0xF7 / 255.0, alpha: 1)
    private var customBackground: UIColor? = nil

    func updateBackground(_ colorScheme: ColorScheme) {
        scene.backgroundColor = customBackground ?? Self.defaultBackground
    }

    func setBackground(_ color: UIColor) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        guard a > 0 else {
            // .clear means the normal canvas
            customBackground = nil
            scene.backgroundColor = Self.defaultBackground
            return
        }
        var dr: CGFloat = 0, dg: CGFloat = 0, db: CGFloat = 0, da: CGFloat = 0
        Self.defaultBackground.getRed(&dr, green: &dg, blue: &db, alpha: &da)
        let blended = UIColor(red: r * a + dr * (1 - a), green: g * a + dg * (1 - a), blue: b * a + db * (1 - a), alpha: 1)
        customBackground = blended
        scene.backgroundColor = blended
    }

    // The zoom slider: a bigger zoom shows the drawing bigger.
    func applyZoom() {
        scene.cameraNode?.setScale(1 / zoomLevel)
    }
    
    public init(colorScheme: ColorScheme) {
        self.scene = TurtleScene()
        super.init()
        scene.size = CGSize(width: 5000, height: 5000)
        scene.scaleMode = .resizeFill
        updateBackground(colorScheme)
    }

    var scene: TurtleScene
    
    public override func start(messageHandler: any PlaygroundLiveViewMessageHandler) {
        clear()
        super.start(messageHandler: messageHandler)
    }
    
    override public func clear() {
        super.clear()
        scene.removeAllChildren()
        scene.setupCamera()
        scene.lockCamera()
        applyZoom()
        customBackground = nil
        scene.backgroundColor = Self.defaultBackground
    }
    
    // Clearing mid-run would remove a moving turtle whose move never finishes, so the run would hang.
    public var disableClear: Bool {
        state == .running
    }
    
    func addTurtle() {
        let turtle = Turtle(console: self)
        self.scene.addChild(turtle)
        let turtleId = UUID()
        turtleMap[turtleId] = turtle
        messageHandler?.send(TurtleSceneResponse.added(turtleId).playgroundValue)
//        return turtle
    }
    
    public var title: String { "Turtle" }

    // The canvas is always light, so draw the "Turtle" tab above it in light mode too.
    public var tabColorScheme: ColorScheme? { .light }
    
}
