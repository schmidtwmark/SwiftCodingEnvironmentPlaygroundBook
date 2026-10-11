//#-hidden-code
import BookCore
import TextAPI
// MARK: - Solution
// // Typo in Quotes. The bug: LEFT is spelled "LFET" inside the quotes. Swift never checks spelling inside quotes, so there is no red error.
//
// let path = console.read("Choose LEFT or RIGHT")
// if path == "LEFT" {
//     console.write("You find a river full of fish. Dinner time!")
// } else if path == "RIGHT" {
//     console.write("You find a cave full of bats. Run!")
// } else {
//     console.write("That's not a path!")
// }
//#-end-hidden-code
/*:
 # Bug 8
 ## What it should do
 Type `LEFT` and you find a river. Type `RIGHT` and you find a cave. Anything else prints `That's not a path!`
 */

let path = console.read("Choose LEFT or RIGHT")
if path == "LFET" {
    console.write("You find a river full of fish. Dinner time!")
} else if path == "RIGHT" {
    console.write("You find a cave full of bats. Run!")
} else {
    console.write("That's not a path!")
}
