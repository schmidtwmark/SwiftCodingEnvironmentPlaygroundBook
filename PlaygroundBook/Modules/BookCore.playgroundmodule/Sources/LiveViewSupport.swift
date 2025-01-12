//
//  See LICENSE folder for this template’s licensing information.
//
//  Abstract:
//  Provides supporting functions for setting up a live view.
//

import UIKit
import PlaygroundSupport
import SwiftUI

public class TextLiveViewClient : PlaygroundRemoteLiveViewProxyDelegate  {
    
    var responses: [String] = []
    
    public init() {
        
    }
    
    public func write(_ coloredText: ColoredString) {
        
        guard Thread.isMainThread else {
            DispatchQueue.main.sync { [unowned self] in
                self.write(coloredText)
            }
            return
        }
        
        guard let liveViewMessageHandler = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy else {
            return
        }
        
        liveViewMessageHandler.send(TextCommand.writeColor(coloredText).playgroundValue)

    }
    
    public func write(_ text: String) {
        print("Writing \(text)")
        guard Thread.isMainThread else {
            DispatchQueue.main.sync { [unowned self] in
                self.write(text)
            }
            return
        }
        
        let liveViewMessageHandler = PlaygroundPage.current.liveView as! PlaygroundRemoteLiveViewProxy
        
        liveViewMessageHandler.send(TextCommand.write(text).playgroundValue)
    }

    
    public func read(_ prompt: String) -> String {
        return waitForResponse(.read(prompt))
    }

    private func waitForResponse(_ command: TextCommand) -> String {
        var result: String = ""
        guard Thread.isMainThread else {
            DispatchQueue.main.sync { [unowned self] in
                result = self.waitForResponse(command)
            }
            return result
        }

        guard let liveViewMessageHandler = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy else {
            return result
        }

        liveViewMessageHandler.delegate = self
        liveViewMessageHandler.send(command.playgroundValue)

        repeat {
            RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
        } while responses.count == 0


        return responses.remove(at: 0)
    }
    
    // MARK: PlaygroundRemoteLiveViewProxyDelegate Methods
    
    public func remoteLiveViewProxyConnectionClosed(_ remoteLiveViewProxy: PlaygroundRemoteLiveViewProxy) {
    }
    
    public func remoteLiveViewProxy(_ remoteLiveViewProxy: PlaygroundRemoteLiveViewProxy, received message: PlaygroundValue) {
        guard let command = TextCommand(message) else {
            return
        }
        
        if case .submit(let string) = command {
            responses.append(string)
        }
    }
}

public class TurtleHandle {
    let liveViewClient: TurtleLiveViewClient
    let id: UUID
    
    init(liveViewClient: TurtleLiveViewClient, id: UUID) {
        self.liveViewClient = liveViewClient
        self.id = id
    }
    
    public func forward(_ distance: Double) {
        liveViewClient.sendCommand(.turtleAction(id, .forward(distance)))
    }
    
    public func backward(_ distance: Double) {
        forward(-distance)
    }
    
    public func rotate(_ angle: Double) {
        liveViewClient.sendCommand(.turtleAction(id, .rotate(angle)))
    }
    
    public func arc(radius: Double, angle: Double) {
        liveViewClient.sendCommand(.turtleAction(id, .arc(radius, angle)))
    }
    
    public func penUp() {
        liveViewClient.sendCommand(.turtleAction(id, .penUp))
    }
    
    public func penDown(fillColor: Color = .clear) {
        liveViewClient.sendCommand(.turtleAction(id, .penDown(fillColor)))
    }
    
    public func lineColor(_ color: Color) {
        liveViewClient.sendCommand(.turtleAction(id, .lineColor(color)))
    }
    
    public func lineWidth(_ width: Double) {
        liveViewClient.sendCommand(.turtleAction(id, .lineWidth(width)))
    }
    
}

public class TurtleLiveViewClient : PlaygroundRemoteLiveViewProxyDelegate  {
    
    var responses: [TurtleSceneCommand] = []
    
    public init() {
        
    }
    
    @discardableResult func sendCommand(_ command : TurtleSceneCommand) -> TurtleSceneCommand {
        
        guard Thread.isMainThread else {
            return DispatchQueue.main.sync { [unowned self] in
                return self.sendCommand(command)
            }
        }
        
        guard let liveViewMessageHandler = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy else {
            return .actionFinished
        }
        
        liveViewMessageHandler.send(command.playgroundValue)

        repeat {
            RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.1))
        } while responses.count == 0


        return responses.remove(at: 0)
    }
    
    public func addTurtle() -> TurtleHandle {
        let result = sendCommand(.addTurtle)
        
        if case .added(let id) = result {
            return TurtleHandle(liveViewClient: self, id: id)
        } else {
            fatalError("Could not add turtle")
        }
    }
    
    // MARK: PlaygroundRemoteLiveViewProxyDelegate Methods
    
    public func remoteLiveViewProxyConnectionClosed(_ remoteLiveViewProxy: PlaygroundRemoteLiveViewProxy) {
    }
    
    public func remoteLiveViewProxy(_ remoteLiveViewProxy: PlaygroundRemoteLiveViewProxy, received message: PlaygroundValue) {
        guard let command = TurtleSceneCommand(message) else {
            return
        }
        
        responses.append(command)
    }
}
