//#-hidden-code
import BookCore
import TextAPI
// MARK: - Solution
// // Adventure Mess. The bug: 1) The first `if` is missing its `{` at the end of the line. 2) The variable is `bearChoice` with a capital C, but the `if` checks `bearchoice`.
//
// let path = console.read("Choose LEFT or RIGHT")
// if path == "LEFT" {
//     console.write("You find a sleeping bear.")
//     let bearChoice = console.read("Choose SNEAK or RUN")
//     if bearChoice == "SNEAK" {
//         console.write("You tiptoe past the bear. Safe!")
//     } else {
//         console.write("The bear wakes up. Run faster!")
//     }
// } else {
//     console.write("You find a lemonade stand. Refreshing!")
// }
//#-end-hidden-code
/*:
 # Bug 24
 ## What it should do
 Type `LEFT`, then `SNEAK`: you tiptoe past a bear. Type `LEFT`, then `RUN`: the bear wakes up. Type `RIGHT`: you find a lemonade stand. This one has **two** bugs!
 */

let path = console.read("Choose LEFT or RIGHT")
if path == "LEFT"
    console.write("You find a sleeping bear.")
    let bearChoice = console.read("Choose SNEAK or RUN")
    if bearchoice == "SNEAK" {
        console.write("You tiptoe past the bear. Safe!")
    } else {
        console.write("The bear wakes up. Run faster!")
    }
} else {
    console.write("You find a lemonade stand. Refreshing!")
}
