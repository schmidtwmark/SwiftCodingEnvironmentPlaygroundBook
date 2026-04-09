//#-hidden-code
import BookCore
import RobotAPI
//#-end-hidden-code
// Design your own level! Edit the map below.
//
// Symbols:
//   # wall       . open space
//   ^ > v < robot start (direction)
//   * goal
//
//   a-f keys     A-F matching doors
//   1-6 lasers   (timed on/off, digit sets speed)
//   U D L R enemies (bounce up/down/left/right)
//   ( ) teleporter pair    { } pair    [ ] pair

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
