/*:

 # Turtle Console Documentation
 
 This playground provides a `turtleConsole` object that enables drawing with turtle robots.
 
 */



/*:
 # `turtleConsole.addTurtle()`
 
 Adds a turtle to the screen, returning it to the user to give commands
 
 ```
let turtle = turtleConsole.addTurtle()
 ```
 */



/*:
 
 # `turtle.forward(_ distance: Double)`
 
 Moves the turtle the provided distance in the direction it is currently facing.
 
 ```
turtle.forward(100)
 
turtle.forward(90.5)
 ```
 */



/*:
# `turtle.backward(_ distance: Double)`
 
 Moves the turtle the provided distance opposite to the direction it is currently facing
 
 ```
turtle.backward(10)
 ```
 */



/*:
# `turtle.penDown(fillColor: Color = .clear)`

 Begins drawing a line starting at the turtle's current position. As the turtle moves, the line will appear behind it.
 
 Specifying a fillColor will fill in the space enclosed by the turtle's line.
 
 ```
 turtle.penDown()
 
 turtle.penDown(fillColor: .green)
 
 ```
 
 
 */



/*:
# `turtle.penUp()`
 
 Stops drawing a line
 
 ```
 turtle.penUp()
 ```
 */



/*:
 # `turtle.rotate(_ angle: Double)`
 
 Rotates the turtle by the provided number of degrees
 
 ```
 turtle.rotate(90) // Turns 90 degrees clockwise
 turtle.rotate(-135) // Turns 135 degrees counterclockwise
 ```
 
 */



/*:
# `turtle.arc(radius: Double, angle: Double)`
 
 Moves the turtle along `angle` degrees of an arc of a circle with the provided `radius`
 
 The turtle rotates by the same angle as it traces the path of the arc
 
 ```
 turtle.arc(radius: 10, angle: 90)
 ```
 
 */



/*:
# `turtle.lineColor(_ color: Color)`
 
 Changes the color of the line drawn by the turtle

 ```
 turtle.lineColor(.blue)
 turtle.lineColor(.green)
 ```
 
 */



/*:
 # `turtle.lineWidth(_ width: Double)`
 
 Changes the width of the line drawn by the turtle
 
 ```
 turtle.lineWidth(5)
 turtle.lineWidth(5.5)
 ```
 */
