//#-hidden-code
import BookCore
import RobotAPI

let robot = robotConsole.robot()
// MARK: - Solution
// // If or While?. The bug: `if` checks only once. The robot waits one turn and then steps forward, even if the laser is still on. `while` keeps waiting until the laser is off. Adding more waits inside the `if` doesn't work on this map.
//
// while robot.facingEmptySpace() {
//     while robot.laserAhead() {
//         robot.wait()
//     }
//     robot.forward()
// }
//#-end-hidden-code
/*:
 # Bug 29
 ## What it should do
 **Challenge bug:** this one is extra tricky.

 Walk down the hall to the flag without getting zapped. Before each step, wait until the laser in front of the robot is off.
 */

while robot.facingEmptySpace() {
    if robot.laserAhead() {
        robot.wait()
    }
    robot.forward()
}
