//#-hidden-code
import BookCore
import TextAPI
// MARK: - Solution
// // Space It Out. The bug: Swift wants the same spacing on both sides of `=` and `==`: a space on each side. The first line has `="Welcome` and the `if` has `=="OPEN"`, with a space on only one side.
//
// let greeting = "Welcome to the treasure room!"
// console.write(greeting)
// let choice = console.read("Choose OPEN or LEAVE")
// if choice == "OPEN" {
//     console.write("The chest is full of gold!")
// } else {
//     console.write("You leave the chest alone.")
// }
//#-end-hidden-code
/*:
 # Bug 13
 ## What it should do
 Welcome you to the treasure room. Type `OPEN` and the chest is full of gold. Type anything else and you leave it alone. This one has **two** bugs!
 */

let greeting ="Welcome to the treasure room!"
console.write(greeting)
let choice = console.read("Choose OPEN or LEAVE")
if choice =="OPEN" {
    console.write("The chest is full of gold!")
} else {
    console.write("You leave the chest alone.")
}
