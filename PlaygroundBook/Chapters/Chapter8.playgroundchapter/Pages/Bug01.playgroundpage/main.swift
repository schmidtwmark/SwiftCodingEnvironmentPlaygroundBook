//#-hidden-code
import BookCore
import TextAPI
// MARK: - Solution
// // Hello?. The bug: `Name` has a capital N, but the variable is `name`. Swift cares about capital letters, so `Name` and `name` are different names.
//
// console.write("Hello! I'm a computer.")
// let name = console.read("What's your name?")
// console.write("Nice to meet you, " + name + "!")
//#-end-hidden-code
/*:
 # Bug 1
 ## What it should do
 Say hello, ask for your name, and greet you by name. If you type `sam`, the last line should be:

 ```
 Nice to meet you, sam!
 ```
 */

console.write("Hello! I'm a computer.")
let name = console.read("What's your name?")
console.write("Nice to meet you, " + Name + "!")
