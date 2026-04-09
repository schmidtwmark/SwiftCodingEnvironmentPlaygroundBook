//
//  See LICENSE folder for this template’s licensing information.
//
//  Abstract:
//  Contains classes/structs/enums/functions which are part of a module that is
//  automatically imported into user-editable code.
//

import BookCore

// Implement any classes/structs/enums/functions in the BookAPI module which you
// want to be automatically imported and visible for users on playground pages
// and in user modules.
//
// This is controlled via the book-level `UserAutoImportedAuxiliaryModules`
// Manifest.plist key.

// nonisolated(unsafe) because this is only accessed from the main thread in Swift Playgrounds
nonisolated(unsafe) public let turtleConsole = TurtleLiveViewClient()

