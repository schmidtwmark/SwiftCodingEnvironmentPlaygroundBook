//#-hidden-code
import BookCore
import TextAPI
// MARK: - Solution
// // The Forest Follows You. The bug: The `}` right after the forest line closes the LEFT block too early, so the FIRE or HELP question runs for everyone. Move that `}` down below the FIRE / HELP `if` so the whole forest part is inside the LEFT block.
//
// let firstChoice = console.read("Choose LEFT or RIGHT")
// if firstChoice == "LEFT" {
//     console.write("You're in a forest. You can start a fire or call for help.")
//     let forestChoice = console.read("Choose FIRE or HELP")
//     if forestChoice == "FIRE" {
//         console.write("The fire keeps the wolves away. You survive!")
//     } else {
//         console.write("A ranger hears you and leads you home. You survive!")
//     }
// }
// if firstChoice == "RIGHT" {
//     console.write("You find a quiet village and take a nap. The end!")
// }
//#-end-hidden-code
/*:
 # Bug 20
 ## What it should do
 Type `LEFT`, then `FIRE` or `HELP`, and you get a forest ending. Type `RIGHT` and you should go straight to the village. It should **not** ask about FIRE or HELP.
 */

let firstChoice = console.read("Choose LEFT or RIGHT")
if firstChoice == "LEFT" {
    console.write("You're in a forest. You can start a fire or call for help.")
}
let forestChoice = console.read("Choose FIRE or HELP")
if forestChoice == "FIRE" {
    console.write("The fire keeps the wolves away. You survive!")
} else {
    console.write("A ranger hears you and leads you home. You survive!")
}
if firstChoice == "RIGHT" {
    console.write("You find a quiet village and take a nap. The end!")
}
