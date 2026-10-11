//#-hidden-code
import BookCore
import TextAPI
// MARK: - Solution
// // Wrong Variable. The bug: The inside `if` checks `firstChoice`, which is LEFT, so it's never FIRE. It should check `forestChoice`. The yellow warning was a clue: `forestChoice` was never used.
//
// let firstChoice = console.read("Choose LEFT or RIGHT")
// if firstChoice == "LEFT" {
//     let forestChoice = console.read("You're in a forest. Choose FIRE or HELP")
//     if forestChoice == "FIRE" {
//         console.write("The fire keeps the wolves away. You survive!")
//     } else {
//         console.write("A ranger hears you and leads you home. You survive!")
//     }
// } else {
//     console.write("You find a quiet village and take a nap. The end!")
// }
//#-end-hidden-code
/*:
 # Bug 22
 ## What it should do
 Type `LEFT`, then `FIRE`: the fire keeps you safe. Type `LEFT`, then `HELP`: a ranger rescues you. Type `RIGHT`: you find a village.
 */

let firstChoice = console.read("Choose LEFT or RIGHT")
if firstChoice == "LEFT" {
    let forestChoice = console.read("You're in a forest. Choose FIRE or HELP")
    if firstChoice == "FIRE" {
        console.write("The fire keeps the wolves away. You survive!")
    } else {
        console.write("A ranger hears you and leads you home. You survive!")
    }
} else {
    console.write("You find a quiet village and take a nap. The end!")
}
