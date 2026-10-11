//#-hidden-code
import BookCore
import RobotAPI

let robot = robotConsole.robot()
// MARK: - Solution
// // One Step Too Far. The bug: `0...5` counts 0, 1, 2, 3, 4, 5. That's 6 times, one too many. `1...5` runs 5 times. This exact bug was on the Day 6 and Day 7 slides (`for counter in 0...5`).
//
// for _ in 1...5 {
//     robot.forward()
// }
// robot.turnRight()
// for _ in 1...3 {
//     robot.forward()
// }
//#-end-hidden-code
/*:
 # Bug 9
 ## What it should do
 Drive 5 squares, turn right, and drive 3 squares to the flag.
 */

for _ in 0...5 {
    robot.forward()
}
robot.turnRight()
for _ in 1...3 {
    robot.forward()
}
