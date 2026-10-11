//#-hidden-code
import BookCore
import TextAPI
// MARK: - Solution
// // Go Team!. The bug: The `We win!` line is inside the loop's `{ }`, so it runs every time around. Move it below the loop's closing `}`.
//
// var cheers = 0
// while cheers < 3 {
//     console.write("Go team!")
//     cheers = cheers + 1
// }
// console.write("🎉 We win! 🎉")
//#-end-hidden-code
/*:
 # Bug 16
 ## What it should do
 Cheer 3 times, then celebrate once. It should print:

 ```
 Go team!
 Go team!
 Go team!
 🎉 We win! 🎉
 ```
 */

var cheers = 0
while cheers < 3 {
    console.write("Go team!")
    cheers = cheers + 1
    console.write("🎉 We win! 🎉")
}
