//#-hidden-code
import BookCore
import TextAPI
// MARK: - Solution
// // The Shadow. The bug: `var weapon = "SWORD"` inside the `{ }` makes a brand-new variable that happens to have the same name. It disappears at the `}`, so the first `weapon` is still STICK. To change the variable you already have, leave off `var`: `weapon = "SWORD"`.
//
// var weapon = "STICK"
// let path = console.read("Choose LEFT or RIGHT")
// if path == "LEFT" {
//     console.write("You find a shiny sword!")
//     weapon = "SWORD"
// }
// console.write("A troll appears! You fight it with your " + weapon)
//#-end-hidden-code
/*:
 # Bug 28
 ## What it should do
 **Challenge bug:** this one is extra tricky.

 Type `LEFT` and you pick up a sword, so the last line should be:

 ```
 A troll appears! You fight it with your SWORD
 ```

 Type `RIGHT` and you fight it with your STICK.
 */

var weapon = "STICK"
let path = console.read("Choose LEFT or RIGHT")
if path == "LEFT" {
    console.write("You find a shiny sword!")
    var weapon = "SWORD"
}
console.write("A troll appears! You fight it with your " + weapon)
