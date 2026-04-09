//
//  See LICENSE folder for this template's licensing information.
//
//  Abstract:
//  A source file which is part of the auxiliary module named "BookCore".
//  Provides the implementation of the "always-on" live view.
//

import UIKit
@preconcurrency import PlaygroundSupport
import SwiftUI
import Combine

public class LiveViewController<CV: ConsoleView>: UIHostingController<CodeEnvironmentView<CV>>, PlaygroundLiveViewMessageHandler {

    // nonisolated(unsafe) since this is only accessed from the main thread
    public nonisolated(unsafe) var console: CV.ConsoleType

    public init() {
        let newConsole = CV.ConsoleType(colorScheme: .dark)
        self.console = newConsole
        let contentView = CodeEnvironmentView<CV>(console: newConsole)
        super.init(rootView: contentView)
    }

    @available(*, unavailable)
    public required init?(coder: NSCoder) {
        fatalError("init(coder:) not supported")
    }

    nonisolated public func receive(_ message: PlaygroundValue) {
        MainActor.assumeIsolated {
            console.receive(message)
        }
    }

    nonisolated public func liveViewMessageConnectionOpened() {
        MainActor.assumeIsolated {
            console.start(messageHandler: self)
        }
    }

    nonisolated public func liveViewMessageConnectionClosed() {
        MainActor.assumeIsolated {
            console.finish(.success)
        }
    }
}

// MARK: - Robot Live View Controller

/// Convenience class for Robot levels that pre-loads a level
public class RobotLiveViewController: LiveViewController<RobotConsoleView> {

    public init(level: Level) {
        // Set pending level before super.init() creates the console
        RobotConsole.pendingLevel = level
        super.init()
    }
}
