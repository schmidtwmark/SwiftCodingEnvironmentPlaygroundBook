//#-hidden-code
import BookCore
import TextAPI
// MARK: - Solution
// // The Wrong Else. The bug: The beach `else` is inside the LEFT block, so it belongs to the dragon `if`, not to `if path == "LEFT"`. Typing RIGHT skips the whole LEFT block, so nothing happens. Close the dragon `if` with a `}` before the beach `else`, and remove the extra `}` at the end.
//
// let path = console.read("Choose LEFT or RIGHT")
// if path == "LEFT" {
//     console.write("You find a sleeping dragon.")
//     let dragonChoice = console.read("Choose SNEAK or FIGHT")
//     if dragonChoice == "SNEAK" {
//         console.write("You sneak past and grab the treasure!")
//     } else if dragonChoice == "FIGHT" {
//         console.write("The dragon wakes up. Run!")
//     }
// } else {
//     console.write("You find a quiet beach. Nice!")
// }
//#-end-hidden-code
/*:
 # Bug 26
 ## What it should do
 **Challenge bug:** this one is extra tricky.

 Type `LEFT`, then `SNEAK` or `FIGHT`, and you get a dragon ending. Type `RIGHT` and you find a beach.
 */

let path = console.read("Choose LEFT or RIGHT")
if path == "LEFT" {
    console.write("You find a sleeping dragon.")
    let dragonChoice = console.read("Choose SNEAK or FIGHT")
    if dragonChoice == "SNEAK" {
        console.write("You sneak past and grab the treasure!")
    } else if dragonChoice == "FIGHT" {
        console.write("The dragon wakes up. Run!")
    } else {
        console.write("You find a quiet beach. Nice!")
    }
}
