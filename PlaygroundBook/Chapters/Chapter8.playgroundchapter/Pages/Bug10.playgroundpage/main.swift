//#-hidden-code
import BookCore
import TextAPI
// MARK: - Solution
// // Else What?. The bug: A plain `else` can't have a condition. To check another condition, write `else if`.
//
// let pet = console.read("Choose CAT or DOG")
// if pet == "CAT" {
//     console.write("The cat ignores you. Classic.")
// } else if pet == "DOG" {
//     console.write("The dog licks your face!")
// } else {
//     console.write("That's not a pet!")
// }
//#-end-hidden-code
/*:
 # Bug 10
 ## What it should do
 Type `CAT` or `DOG` and get a message about your pet. Anything else prints `That's not a pet!`
 */

let pet = console.read("Choose CAT or DOG")
if pet == "CAT" {
    console.write("The cat ignores you. Classic.")
} else pet == "DOG" {
    console.write("The dog licks your face!")
} else {
    console.write("That's not a pet!")
}
