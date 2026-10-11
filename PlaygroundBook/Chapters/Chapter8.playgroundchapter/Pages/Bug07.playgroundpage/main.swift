//#-hidden-code
import BookCore
import RobotAPI

let robot = robotConsole.robot()
// MARK: - Solution
// // Two Dots. The bug: Swift counts with three dots: `1...4`. Two dots doesn't mean anything to Swift.
//
// for _ in 1...4 {
//     robot.forward()
// }
// robot.turnRight()
// for _ in 1...3 {
//     robot.forward()
// }
//#-end-hidden-code
/*:
 # Bug 7
 ## What it should do
 Drive 4 squares, turn right, and drive 3 squares to the flag.
 */

for _ in 1..4 {
    robot.forward()
}
robot.turnRight()
for _ in 1...3 {
    robot.forward()
}
