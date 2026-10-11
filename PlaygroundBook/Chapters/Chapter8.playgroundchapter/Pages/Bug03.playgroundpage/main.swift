//#-hidden-code
import BookCore
import TextAPI
// MARK: - Solution
// // Missing Quote. The bug: The second line is missing its closing `"`. Without it, Swift thinks the text never ends.
//
// console.write("You wake up in a dark cave.")
// console.write("You see a light in the distance!")
// console.write("You walk toward it.")
//#-end-hidden-code
/*:
 # Bug 3
 ## What it should do
 Print three lines:

 ```
 You wake up in a dark cave.
 You see a light in the distance!
 You walk toward it.
 ```
 */

console.write("You wake up in a dark cave.")
console.write("You see a light in the distance!)
console.write("You walk toward it.")
