//
//  See LICENSE folder for this template’s licensing information.
//
//  Abstract:
//  Provides supporting functions for setting up a live view.
//

import UIKit
import PlaygroundSupport
import SwiftUI

public class TextLiveViewClient : LiveViewClient<TextCommand, TextResponse> {
    
    public func write(_ coloredText: ColoredString) {
        sendCommand(TextCommand.writeColor(coloredText))
    }
    
    public func write(_ text: String) {
        sendCommand(TextCommand.write(text))
    }
    
    
    public func read(_ prompt: String) -> String {
        let response = sendCommandAndWait(.read(prompt))
        if case let .submit(text) = response {
            return text
        } else {
            return ""
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
        liveViewClient.sendCommandAndWait(.turtleAction(id, .forward(distance)))
    }
    
    public func backward(_ distance: Double) {
        forward(-distance)
    }
    
    public func rotate(_ angle: Double) {
        liveViewClient.sendCommandAndWait(.turtleAction(id, .rotate(angle)))
    }
    
    public func arc(radius: Double, angle: Double) {
        liveViewClient.sendCommandAndWait(.turtleAction(id, .arc(radius, angle)))
    }
    
    public func penUp() {
        liveViewClient.sendCommandAndWait(.turtleAction(id, .penUp))
    }
    
    public func penDown(fillColor: Color = .clear) {
        liveViewClient.sendCommandAndWait(.turtleAction(id, .penDown(fillColor)))
    }
    
    public func lineColor(_ color: Color) {
        liveViewClient.sendCommandAndWait(.turtleAction(id, .lineColor(color)))
    }
    
    public func lineWidth(_ width: Double) {
        liveViewClient.sendCommandAndWait(.turtleAction(id, .lineWidth(width)))
    }
    
}

public class LiveViewClient<Request: ConsoleMessage, Response: ConsoleMessage> : PlaygroundRemoteLiveViewProxyDelegate {
    public func remoteLiveViewProxyConnectionClosed(_ remoteLiveViewProxy: PlaygroundSupport.PlaygroundRemoteLiveViewProxy) {
    }
    
    public func remoteLiveViewProxy(_ remoteLiveViewProxy: PlaygroundSupport.PlaygroundRemoteLiveViewProxy, received message: PlaygroundSupport.PlaygroundValue) {
        guard let response = Response(message) else {
            return
        }
        
        responses.append(response)
    }
    
    func sendCommand(_ command: Request) {
        guard Thread.isMainThread else {
            return DispatchQueue.main.sync { [unowned self] in
                self.sendCommand(command)
            }
        }
        
        guard let liveViewMessageHandler = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy else {
            return
        }
        
        liveViewMessageHandler.send(command)
    }
    
    @discardableResult func sendCommandAndWait(_ command: Request) -> Response {
        guard Thread.isMainThread else {
            return DispatchQueue.main.sync { [unowned self] in
                return self.sendCommandAndWait(command)
            }
        }
        
        guard let liveViewMessageHandler = PlaygroundPage.current.liveView as? PlaygroundRemoteLiveViewProxy else {
            fatalError("Could not find live view")
        }
        
        liveViewMessageHandler.delegate = self
        liveViewMessageHandler.send(command)
        repeat {
            RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.01))
        } while responses.count == 0

        return responses.remove(at: 0)
    }
    
    var responses: [Response] = []
    
    public init() { }
    
    
}

public class TurtleLiveViewClient : LiveViewClient<TurtleSceneCommand, TurtleSceneResponse> {
    public func addTurtle() -> TurtleHandle {
        let result = sendCommandAndWait(.addTurtle)
        if case .added(let id) = result {
            return TurtleHandle(liveViewClient: self, id: id)
        } else {
            fatalError("Failed to add turtle")
        }
    }
}
