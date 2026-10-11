//#-hidden-code
import BookCore
import TextAPI
// MARK: - Solution
// // Write or Read?. The bug: 1) `console.write` only shows text. It doesn't give back what you type, so `name` gets nothing; asking a question needs `console.read`. 2) The welcome uses `console.read`, so the program stops and waits for you to type. Just showing a message needs `console.write`.
//
// console.write("Welcome to the Dragon Cave!")
// let name = console.read("What is your name, hero?")
// console.write("Good luck, " + name + "!")
//#-end-hidden-code
/*:
 # Bug 17
 ## What it should do
 Welcome you, ask for your name, then wish you luck. If you type `sam`, the last line should be:

 ```
 Good luck, sam!
 ```

 You should only have to type **once**. This one has **two** bugs!
 */

console.read("Welcome to the Dragon Cave!")
let name = console.write("What is your name, hero?")
console.write("Good luck, " + name + "!")
