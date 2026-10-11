//#-hidden-code
import BookCore
import TextAPI
// MARK: - Solution
// // Password Door. The bug: 1) After the right password, nothing sets `unlocked` to `true`, so `while unlocked == false` keeps going and asks again. Add `unlocked = true` after the door opens. 2) Then Swift says `unlocked` is a `let` constant: it has to be `var` so it can change.
//
// var unlocked = false
// while unlocked == false {
//     let guess = console.read("The door is locked. What's the password?")
//     if guess == "MOTH" {
//         console.write("The door creaks open!")
//         unlocked = true
//     } else {
//         console.write("Wrong! Try again.")
//     }
// }
// console.write("You step into the treasure room. You win!")
//#-end-hidden-code
/*:
 # Bug 30
 ## What it should do
 **Challenge bug:** this one is extra tricky.

 Keep asking for the password until you type `MOTH`. A wrong answer prints `Wrong! Try again.` Once you get it right, the last line should be `You step into the treasure room. You win!` This one has **two** bugs, and the second one shows up after you fix the first.

 `unlocked` holds `true` or `false`, the same way `robot.facingWall()` does.
 */

let unlocked = false
while unlocked == false {
    let guess = console.read("The door is locked. What's the password?")
    if guess == "MOTH" {
        console.write("The door creaks open!")
    } else {
        console.write("Wrong! Try again.")
    }
}
console.write("You step into the treasure room. You win!")
