//#-hidden-code
import BookCore
import RobotAPI
//#-end-hidden-code
/*:
 # Custom Level
 Design your own level! Edit the map in the code below, then write code to solve it.

 ## Map symbols
 - `#` wall, `.` open space
 - `^` `>` `v` `<` the robot's start, pointing up, right, down, or left
 - `*` the flag
 - `a` to `f` keys, and `A` to `F` their matching doors
 - `1` to `6` lasers. Each digit blinks at its own speed.
 - `U` `D` `L` `R` enemies that bounce up, down, left, or right
 - `(` `)` a teleporter pair. `{` `}` and `[` `]` make two more pairs.

 ## Commands
 - `robot.forward()` moves one square forward
 - `robot.turnRight()` turns 90° to the right
 - `robot.turnLeft()` turns 90° to the left
 - `robot.wait()` waits one turn. Lasers and enemies keep moving.
 - `robot.facingWall()` is `true` when there's a wall right in front of the robot
 - `robot.facingEmptySpace()` is `true` when the square right in front of the robot isn't a wall
 - `robot.laserAhead()` is `true` when a laser right in front of the robot is on, or about to turn on
 - `robot.isOnGoal()` is `true` when the robot is on the flag
 */

let robot = robotConsole.loadLevel("""
#########
#v......#
##A####.#
#.)....1#
#..#.R..#
#..#....#
#..#..a.#
#(.*#...#
#########
""")

// Solve your level:
robot.forward()
