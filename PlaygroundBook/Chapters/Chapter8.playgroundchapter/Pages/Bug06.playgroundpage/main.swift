//#-hidden-code
import BookCore
import TextAPI
// MARK: - Solution
// // Two Words. The bug: A variable's name can't have a space in it: Swift reads `first choice` as two separate names. Squish it into one word, like `firstChoice`, everywhere it's used.
//
// let firstChoice = console.read("Choose LEFT or RIGHT")
// if firstChoice == "LEFT" {
//     console.write("You walk into a spooky forest.")
// } else {
//     console.write("You walk into a busy village.")
// }
//#-end-hidden-code
/*:
 # Bug 6
 ## What it should do
 Type `LEFT` and you walk into a forest. Type anything else and you walk into a village.
 */

let first choice = console.read("Choose LEFT or RIGHT")
if first choice == "LEFT" {
    console.write("You walk into a spooky forest.")
} else {
    console.write("You walk into a busy village.")
}
