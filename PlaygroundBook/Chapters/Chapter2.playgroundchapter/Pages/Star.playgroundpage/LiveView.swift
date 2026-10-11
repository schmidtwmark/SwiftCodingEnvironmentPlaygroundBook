//
//  See LICENSE folder for this template’s licensing information.
//
//  Abstract:
//  Instantiates a live view and passes it to the PlaygroundSupport framework.
//

import UIKit
import BookCore
import PlaygroundSupport

import SwiftUI


// Set up the live view
let liveViewController = LiveViewController<TurtleConsoleView>()
PlaygroundPage.current.liveView = liveViewController
