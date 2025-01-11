//
//  See LICENSE folder for this template’s licensing information.
//
//  Abstract:
//  A source file which is part of the auxiliary module named "BookCore".
//  Provides the implementation of the "always-on" live view.
//

import UIKit
import PlaygroundSupport
import SwiftUI
import Combine

//@MainActor
public class LiveViewController: UIHostingController<CodeEnvironmentView<TextConsoleView>>, PlaygroundLiveViewMessageHandler {
    
    let console: TextConsole = TextConsole(colorScheme: .dark)

    
    public init() {
        let contentView = CodeEnvironmentView<TextConsoleView>(console: console)
        super.init(rootView: contentView)
    }
    
    public required init?(coder: NSCoder) {
        let contentView = CodeEnvironmentView<TextConsoleView>(console: console)
        
        super.init(rootView: contentView)
    }
    
    // Implement required method to receive messages
    public func receive(_ message: PlaygroundValue) {
        self.console.receive(message)
    }
    
    public func liveViewMessageConnectionOpened() {
        self.console.start(messageHandler: self)
    }

    public func liveViewMessageConnectionClosed() {
        self.console.finish(.success)
    }
}
