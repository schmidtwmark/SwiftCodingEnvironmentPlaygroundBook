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
