//#-hidden-code
import BookCore
import TextAPI
// MARK: - Solution
// // Two Ifs. The bug: The second `if` starts a brand-new question, so its `else` runs whenever the item isn't SHIELD, including SWORD. Make it `} else if` so all three choices are one chain.
//
// let item = console.read("Choose SWORD or SHIELD")
// if item == "SWORD" {
//     console.write("You take the sword. Watch out, dragon!")
// } else if item == "SHIELD" {
//     console.write("You take the shield. Nothing can hurt you!")
// } else {
//     console.write("That's not one of the choices!")
// }
//#-end-hidden-code
/*:
 # Bug 12
 ## What it should do
 Type `SWORD` or `SHIELD` and print **one** message about what you picked. Anything else prints `That's not one of the choices!`
 */

let item = console.read("Choose SWORD or SHIELD")
if item == "SWORD" {
    console.write("You take the sword. Watch out, dragon!")
}
if item == "SHIELD" {
    console.write("You take the shield. Nothing can hurt you!")
} else {
    console.write("That's not one of the choices!")
}
