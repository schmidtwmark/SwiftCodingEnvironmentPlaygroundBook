//#-hidden-code
import BookCore
import RobotAPI

let robot = robotConsole.robot()
// MARK: - Solution
// // Wrong Way. The bug: The flag is to the robot's left, so it needs `robot.turnLeft()`, not `robot.turnRight()`.
//
// robot.forward()
// robot.forward()
// robot.forward()
// robot.forward()
// robot.turnLeft()
// robot.forward()
// robot.forward()
// robot.forward()
//#-end-hidden-code
/*:
 # Bug 2
 ## What it should do
 Drive 4 squares, turn toward the flag, and drive 3 squares to reach it.
 */

robot.forward()
robot.forward()
robot.forward()
robot.forward()
robot.turnRight()
robot.forward()
robot.forward()
robot.forward()
