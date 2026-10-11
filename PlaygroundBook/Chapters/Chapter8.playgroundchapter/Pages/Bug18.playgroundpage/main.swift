//#-hidden-code
import BookCore
import TextAPI
// MARK: - Solution
// // Lost Brace. The bug: The `if` block never closes: it needs a `}` right before `else`. Every `{` needs its own `}`.
//
// let door = console.read("Choose RED or BLUE")
// if door == "RED" {
//     console.write("A dragon is sleeping behind the red door.")
// } else {
//     console.write("A pile of gold is behind the blue door!")
// }
//#-end-hidden-code
/*:
 # Bug 18
 ## What it should do
 Type `RED` and you find a dragon. Type anything else and you find gold.
 */

let door = console.read("Choose RED or BLUE")
if door == "RED" {
    console.write("A dragon is sleeping behind the red door.")
else {
    console.write("A pile of gold is behind the blue door!")
}
