//#-hidden-code
import BookCore
import RobotAPI

let robot = robotConsole.robot()
// MARK: - Solution
// // Round or Curly?. The bug: Round `( )` go after a command, like `robot.turnRight()`. Curly `{ }` go around the code inside a loop or an `if`. The first loop uses `( )` where it needs `{ }`, and `robot.turnRight{}` uses `{ }` where it needs `( )`.
//
// while robot.facingEmptySpace() {
//     robot.forward()
// }
// robot.turnRight()
// while robot.facingEmptySpace() {
//     robot.forward()
// }
//#-end-hidden-code
/*:
 # Bug 11
 ## What it should do
 Drive to the end of the hall, turn right, and drive to the flag. This one has **two** bugs!
 */

while robot.facingEmptySpace() (
    robot.forward()
)
robot.turnRight{}
while robot.facingEmptySpace() {
    robot.forward()
}
