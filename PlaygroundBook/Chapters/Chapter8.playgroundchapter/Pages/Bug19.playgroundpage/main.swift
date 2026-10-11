//#-hidden-code
import BookCore
import RobotAPI

let robot = robotConsole.robot()
// MARK: - Solution
// // The Spiral. The bug: `sides` never goes up, so `sides < 6` is always true. The robot keeps following the spiral right past the flag and never stops. Add `sides = sides + 1` inside the outer loop, after `robot.turnRight()`.
//
// var sides = 0
// while sides < 6 {
//     while robot.facingEmptySpace() {
//         robot.forward()
//     }
//     robot.turnRight()
//     sides = sides + 1
// }
// // Turn around and step into the flag's room
// robot.turnLeft()
// robot.turnLeft()
// robot.forward()
//#-end-hidden-code
/*:
 # Bug 19
 ## What it should do
 The robot starts in the middle of a spiral. It should follow the spiral for **6** sides, turning right after each one, then turn around and step into the little room with the flag.
 */

var sides = 0
while sides < 6 {
    while robot.facingEmptySpace() {
        robot.forward()
    }
    robot.turnRight()
}
// Turn around and step into the flag's room
robot.turnLeft()
robot.turnLeft()
robot.forward()
