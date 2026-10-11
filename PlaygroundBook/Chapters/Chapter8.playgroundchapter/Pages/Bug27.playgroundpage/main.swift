//#-hidden-code
import BookCore
import RobotAPI

let robot = robotConsole.robot()
// MARK: - Solution
// // Stairs. The bug: `steps` is never set back to 0. After the first stair it is already 2, so `steps < 2` is false and the inner loop never runs again. Put `steps = 0` at the start of each stair, inside the outer loop and above the inner loop.
//
// var stairs = 0
// var steps = 0
// while stairs < 4 {
//     steps = 0
//     while steps < 2 {
//         robot.forward()
//         steps = steps + 1
//     }
//     robot.turnRight()
//     robot.forward()
//     robot.turnLeft()
//     stairs = stairs + 1
// }
//#-end-hidden-code
/*:
 # Bug 27
 ## What it should do
 **Challenge bug:** this one is extra tricky.

 Walk down 4 stairs to the flag. Each stair is 2 steps forward, then 1 step down.
 */

var stairs = 0
var steps = 0
while stairs < 4 {
    while steps < 2 {
        robot.forward()
        steps = steps + 1
    }
    robot.turnRight()
    robot.forward()
    robot.turnLeft()
    stairs = stairs + 1
}
