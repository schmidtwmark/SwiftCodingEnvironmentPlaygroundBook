//#-hidden-code
import BookCore
import TextAPI
// MARK: - Solution
// // Extra Brace. The bug: There's one `}` too many at the end. Every `}` needs a `{` that it closes.
//
// let snack = console.read("Choose APPLE or COOKIE")
// if snack == "APPLE" {
//     console.write("Crunchy and healthy!")
// } else {
//     console.write("Delicious, but now you want another one.")
// }
//#-end-hidden-code
/*:
 # Bug 5
 ## What it should do
 Type `APPLE` or `COOKIE` and get a message about your snack.
 */

let snack = console.read("Choose APPLE or COOKIE")
if snack == "APPLE" {
    console.write("Crunchy and healthy!")
} else {
    console.write("Delicious, but now you want another one.")
}
}
