//#-hidden-code
import BookCore
// MARK: - Solution
// turtle.penDown(fillColor: .white)
// turtle.arcLeft(radius: 75, angle: 360)
// turtle.penUp()
// turtle.rotateLeft(90)
// turtle.forward(150)
// turtle.rotateRight(90)
// turtle.penDown(fillColor: .white)
// turtle.arcLeft(radius: 50, angle: 360)
// turtle.penUp()
// turtle.rotateLeft(90)
// turtle.forward(100)
// turtle.rotateRight(90)
// turtle.penDown(fillColor: .white)
// turtle.arcLeft(radius: 25, angle: 360)
//#-end-hidden-code
/*:
 # Snowman
 ![A snowman made of three white balls with blue outlines](snowman.png)

 Three new commands:
 - `turtle.arcLeft(radius: 75, angle: 360)` draws a whole circle, curving left. When the turtle faces right, the circle is above it, so the turtle is at the bottom of the ball.
 - `turtle.penDown(fillColor: .white)` colors the inside of the shape the turtle draws next.
 - `turtle.penUp()` lifts the pen, so the turtle can move without drawing.

 The balls have radius 75, 50 and 25. To get from the bottom of a ball to its top, move up twice its radius. Each ball needs its own `penDown(fillColor: .white)`.
 */

let turtle = turtleConsole.addTurtle()
// Write your code here:
