//#-hidden-code
import BookCore
import TextAPI
// MARK: - Solution
// // Three Doors. The bug: 1) `else door == "BLUE"` needs to be `else if`. 2) The `}` after the dragon line closes the RED block too early, so everyone gets asked CHESS or TAG; move it below the game's `if` / `else`. 3) `if door == "GREEN"` starts a new chain, so RED also prints "That's not a door!"; make it `} else if door == "GREEN" {`.
//
// let door = console.read("Three doors! Choose RED, GREEN, or BLUE")
// if door == "RED" {
//     console.write("A dragon! It wants to play a game.")
//     let game = console.read("Choose CHESS or TAG")
//     if game == "CHESS" {
//         console.write("The dragon wins in 4 moves. You're toast!")
//     } else {
//         console.write("Dragons are terrible at tag. You win!")
//     }
// } else if door == "GREEN" {
//     console.write("A room full of puppies. Best ending!")
// } else if door == "BLUE" {
//     console.write("A room full of homework. Oh no.")
// } else {
//     console.write("That's not a door!")
// }
//#-end-hidden-code
/*:
 # Bug 25
 ## What it should do
 Type `RED`, then `CHESS` or `TAG`: you get **only** a dragon ending. Type `GREEN`: **only** puppies. Type `BLUE`: **only** homework. Anything else: `That's not a door!` This one has **three** bugs!
 */

let door = console.read("Three doors! Choose RED, GREEN, or BLUE")
if door == "RED" {
    console.write("A dragon! It wants to play a game.")
}
let game = console.read("Choose CHESS or TAG")
if game == "CHESS" {
    console.write("The dragon wins in 4 moves. You're toast!")
} else {
    console.write("Dragons are terrible at tag. You win!")
}
if door == "GREEN" {
    console.write("A room full of puppies. Best ending!")
} else door == "BLUE" {
    console.write("A room full of homework. Oh no.")
} else {
    console.write("That's not a door!")
}
