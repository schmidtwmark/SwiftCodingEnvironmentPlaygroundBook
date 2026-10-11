//#-hidden-code
import BookCore
import RobotAPI

let robot = robotConsole.robot()
// MARK: - Solution
// // Counting Steps. The bug: `let` makes a constant, which can never change. A counter that goes up needs `var`.
//
// var steps = 0
// while steps < 7 {
//     robot.forward()
//     steps = steps + 1
// }
//#-end-hidden-code
/*:
 # Bug 4
 ## What it should do
 Drive 7 squares to the flag, counting the steps as you go.
 */

let steps = 0
while steps < 7 {
    robot.forward()
    steps = steps + 1
}
