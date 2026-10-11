/*:

 # Turtle Console Documentation
 
 This playground provides a `turtleConsole` object that enables drawing with turtle robots.

 A new turtle starts in the middle (x: 0, y: 0), facing right, with its pen **up**: call `turtle.penDown()` before it draws.

 To turn or curve, always say which way: `rotateLeft` or `rotateRight`, `arcLeft` or `arcRight`, `ovalLeft` or `ovalRight`.

 Every number can be a whole number or a decimal, and so can a variable: `var size = 50` then `turtle.forward(size)`. One catch: dividing by a whole-number variable drops the remainder. With `let sides = 7`, `360 / sides` is 51, not 51.43 (typing `360 / 7` directly gives 51.43). Use `360.0 / Double(sides)` for the exact angle. (That's also why some commands show up twice when you type `turtle.`: one version is for whole numbers, and either one works.)
 
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
 
 Specifying a fillColor will fill in the space enclosed by the turtle's line. The fill keeps growing until `penUp()`.

 Set `lineColor` and `lineWidth` *before* `penDown(fillColor:)`. Changing them while the pen is down starts a new shape, which breaks up the fill.
 
 ```
 turtle.penDown()
 
 turtle.penDown(fillColor: .green)
 turtle.penDown(fillColor: .hex("aabbcc"))

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
 # `turtle.rotateLeft(_ angle: Double)` and `turtle.rotateRight(_ angle: Double)`

 Turns the turtle left (counterclockwise) or right (clockwise) by the provided number of degrees.

 ```
 turtle.rotateLeft(90)    // a quarter turn to the left
 turtle.rotateRight(144)  // the turn at each point of a star
 ```
 */



/*:
 # `turtle.arcLeft(radius: Double, angle: Double)` and `turtle.arcRight(radius: Double, angle: Double)`

 Moves the turtle along a circle with the provided `radius` for `angle` degrees, curving left or right. The turtle turns as it goes, so it faces along the curve the whole time. 360 makes a whole circle and 180 makes half of one. The radius must be positive.

 ```
 turtle.arcLeft(radius: 50, angle: 360)    // a whole circle, on the turtle's left
 turtle.arcRight(radius: 20, angle: 180)   // half a circle, curving right
 ```
 */



/*:
 # `turtle.ovalLeft(xRadius: Double, yRadius: Double, angle: Double)` and `turtle.ovalRight(...)`

 Like `arcLeft` and `arcRight`, but along a stretched circle. `xRadius` is how far it stretches in the direction the turtle faces, and `yRadius` is how far it stretches to the side.

 ```
 turtle.ovalLeft(xRadius: 140, yRadius: 25, angle: 360)
 ```
 */



/*:
# `turtle.lineColor(_ color: Color)`
 
 Changes the color of the line drawn by the turtle, and of the turtle itself. The turtle starts out blue.

 Use a named color, a hex code in quotes (find one with a color picker), or red, green and blue amounts from 0 to 255:

 ```
 turtle.lineColor(.orange)
 turtle.lineColor(.hex("aabbcc"))
 turtle.lineColor(.rgb(245, 66, 66))
 turtle.lineColor(.rgb(Int.random(in: 0...255), Int.random(in: 0...255), Int.random(in: 0...255)))   // a random color
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



/*:
 # `turtle.backgroundColor(_ color: Color)`

 Changes the color of the whole canvas behind the drawing. Each run starts with the light gray canvas again.

 ```
 turtle.backgroundColor(.black)
 turtle.backgroundColor(.hex("1a1a40"))   // a night sky
 turtle.backgroundColor(.clear)   // back to the normal light gray
 ```
 */



/*:
 # `turtle.hideTurtle()` and `turtle.showTurtle()`

 Hides the turtle (or shows it again), for a clean finished picture. It still moves and draws while it's hidden.

 ```
 turtle.hideTurtle()
 ```
 */



/*:
 # `turtle.goTo(x: Double, y: Double)`

 Moves in a straight line to a spot, without turning. The turtle starts at x: 0, y: 0. Bigger x is farther right, and bigger y is farther up. If the pen is down, it draws the line.

 ```
 turtle.penUp()
 turtle.goTo(x: -100, y: 50)   // 100 left of the start and 50 up
 turtle.penDown()
 ```
 */



/*:
 # `turtle.setHeading(_ angle: Double)`

 Turns to face a direction, no matter which way the turtle faces now: 0 is right, 90 is up, 180 is left, and 270 (or -90) is down.

 ```
 turtle.setHeading(90)   // face up
 ```
 */



/*:
 # `turtle.home()`

 Goes back to where the turtle started (x: 0, y: 0) and faces right, like starting over without erasing. If the pen is down, it draws the line back.

 ```
 turtle.penUp()
 turtle.home()
 ```
 */
