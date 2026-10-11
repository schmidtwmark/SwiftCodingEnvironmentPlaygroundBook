//#-hidden-code
import BookCore
import RobotAPI

let robot = robotConsole.robot()
// MARK: - Solution
// // Hurdles. The bug: `jumpHurdle()` is written but never used. Writing a function only teaches the steps; you still have to call it. Add `jumpHurdle()` inside the loop, after the two steps.
//
// func jumpHurdle() {
//     robot.turnLeft()
//     robot.forward()
//     robot.turnRight()
//     robot.forward()
//     robot.forward()
//     robot.turnRight()
//     robot.forward()
//     robot.turnLeft()
// }
//
// for _ in 1...3 {
//     robot.forward()
//     robot.forward()
//     jumpHurdle()
// }
//#-end-hidden-code
/*:
 # Bug 23
 ## What it should do
 Take 2 steps, jump the hurdle, and do that 3 times to reach the flag.
 */

func jumpHurdle() {
    robot.turnLeft()
    robot.forward()
    robot.turnRight()
    robot.forward()
    robot.forward()
    robot.turnRight()
    robot.forward()
    robot.turnLeft()
}

for _ in 1...3 {
    robot.forward()
    robot.forward()
}
