//#-hidden-code
import BookCore
import TextAPI
// MARK: - Solution
// // Out of Scope. The bug: A variable made inside `{ }` only exists inside those braces. `weapon` is made inside the LEFT block, so move the line that uses it up inside that block.
//
// let path = console.read("Choose LEFT or RIGHT")
// if path == "LEFT" {
//     let weapon = console.read("You find some weapons. Choose SWORD or BOW")
//     console.write("You march into battle with your " + weapon)
// } else {
//     console.write("You take a nap under a tree.")
// }
//#-end-hidden-code
/*:
 # Bug 21
 ## What it should do
 Type `LEFT`, then `SWORD` or `BOW`. The last line should be:

 ```
 You march into battle with your SWORD
 ```

 (or BOW). Type `RIGHT` and you take a nap instead.
 */

let path = console.read("Choose LEFT or RIGHT")
if path == "LEFT" {
    let weapon = console.read("You find some weapons. Choose SWORD or BOW")
} else {
    console.write("You take a nap under a tree.")
}
console.write("You march into battle with your " + weapon)
