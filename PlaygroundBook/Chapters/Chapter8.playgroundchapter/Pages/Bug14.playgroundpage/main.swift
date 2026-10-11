//#-hidden-code
import BookCore
import RobotAPI

let robot = robotConsole.robot()
// MARK: - Solution
// // Three Sides. The bug: `robot.turnRight()` is below the loop's closing `}`, so it runs only once, after all the driving. Move it inside the loop so the robot turns after each side.
//
// var sides = 0
// while sides < 3 {
//     robot.forward()
//     robot.forward()
//     robot.forward()
//     robot.turnRight()
//     sides = sides + 1
// }
//#-end-hidden-code
/*:
 # Bug 14
 ## What it should do
 Drive 3 squares and turn right. Do that for each side until you reach the flag.
 */

var sides = 0
while sides < 3 {
    robot.forward()
    robot.forward()
    robot.forward()
    sides = sides + 1
}
robot.turnRight()
