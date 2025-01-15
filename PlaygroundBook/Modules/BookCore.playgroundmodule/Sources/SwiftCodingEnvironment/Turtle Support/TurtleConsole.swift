//
//  TurtleConsole.swift
//  StudentCodeTemplate
//
//  Created by Mark Schmidt on 11/16/24.
//

import SwiftUI
import SpriteKit
import PlaygroundSupport

public enum TurtleSceneCommand {
    case addTurtle
    case turtleAction(UUID, TurtleCommand)
}

public enum TurtleSceneResponse {
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

public enum TurtleCommand {
    case forward(CGFloat)
    case penUp
    case penDown(Color)
    case rotate(CGFloat)
    case arc(CGFloat, CGFloat)
    case lineColor(Color)
    case lineWidth(CGFloat)
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
            case "LineColor":
                guard case let .integer(hex)? = dict["Color"] else { return nil }
                self = .lineColor(Color(hex: hex))
            case "LineWidth":
                guard case let .floatingPoint(width)? = dict["Width"] else { return nil }
                self = .lineWidth(width)
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
        case .lineColor(let color):
            return .dictionary(["Command": .string("LineColor"), "Color": .integer(color.hex)])
        case .lineWidth(let width):
            return .dictionary(["Command": .string("LineWidth"), "Width": .floatingPoint(width)])
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
        super.init(texture: texture, color: .green, size: CGSize(width: 32.0, height: 32.0))
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
        let moveAction = SKAction.move(to: end, duration: distance / MOVEMENT_SPEED_0)
        await self.runAsync(moveAction)
    }
    
    private func runAsync(_ action: SKAction) async {
        guard console.state == .running else { return}
        
        await withCheckedContinuation { continuation in
            self.run(action) {
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
    
        
        
        self.rotation += angle.radians
        let rotateAction = SKAction.rotate(byAngle: angle.radians, duration: duration)
        let followAction = SKAction.follow(path, asOffset: true , orientToPath: false, duration: duration)
        let group = SKAction.group([rotateAction, followAction])
        
        await self.runAsync(group)
            
    }

   public func rotate(_ angle: CGFloat) async {
       self.rotation += angle.radians
       let rotateAction = SKAction.rotate(byAngle: angle.radians, duration: abs(angle / ROTATION_SPEED_0))
       await self.runAsync(rotateAction)
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
        if case .down(let path, let pathNode, _) = penState {
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
        case .lineColor(let color):
            await setColor(UIColor(color))
        case .lineWidth(let width):
            lineWidth(width)
        }
    }
}

let ROTATION_SPEED_0 = 90.0 // degrees / second
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
        
        let xRange = SKRange(lowerLimit: -self.size.width, upperLimit: self.size.width)
        let yRange = SKRange(lowerLimit: -self.size.height, upperLimit: self.size.height)
        
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
public final class TurtleConsole: BaseConsole<TurtleConsole>, Console {
    
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
    
    
    func updateBackground(_ colorScheme: ColorScheme) {
        scene.backgroundColor = .secondarySystemBackground 
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
    }
    
    public var disableClear: Bool {
        false
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
    
}
