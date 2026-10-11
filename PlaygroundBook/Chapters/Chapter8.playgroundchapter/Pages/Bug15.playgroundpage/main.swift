//#-hidden-code
import BookCore
import TextAPI
// MARK: - Solution
// // Equals or Equals Equals. The bug: `=` puts a value into a variable. `==` asks whether two things are equal, and an `if` needs `==`. The first red error is misleading: changing `let` to `var` doesn't fix it.
//
// let path = console.read("Choose LEFT or RIGHT")
// if path == "LEFT" {
//     console.write("You cross a rickety bridge.")
// } else {
//     console.write("You climb a tall mountain.")
// }
//#-end-hidden-code
/*:
 # Bug 15
 ## What it should do
 Type `LEFT` and you cross a bridge. Type anything else and you climb a mountain.
 */

let path = console.read("Choose LEFT or RIGHT")
if path = "LEFT" {
    console.write("You cross a rickety bridge.")
} else {
    console.write("You climb a tall mountain.")
}
