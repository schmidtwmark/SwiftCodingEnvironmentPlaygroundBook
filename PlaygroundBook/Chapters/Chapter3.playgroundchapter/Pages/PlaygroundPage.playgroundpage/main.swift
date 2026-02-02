//#-hidden-code
//
//  See LICENSE folder for this template's licensing information.
//
//  Abstract:
//  The Swift file containing the source code edited by the user of this playground book.
//
import BookCore
//#-end-hidden-code
import RobotAPI

// Load a level and get the robot handle
let robot = robotConsole.loadLevel(level1)

// Control the robot to reach the goal!
// Available commands:
//   robot.forward()   - Move one cell forward
//   robot.turnRight() - Turn 90 degrees right
//   robot.turnLeft()  - Turn 90 degrees left

// Example: Navigate from bottom-left to top-right in level1
robot.forward()
robot.forward()
robot.turnRight()
robot.forward()
robot.forward()
