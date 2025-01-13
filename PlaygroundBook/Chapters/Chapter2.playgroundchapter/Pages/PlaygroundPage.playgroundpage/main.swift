//#-hidden-code
//
//  See LICENSE folder for this template’s licensing information.
//
//  Abstract:
//  The Swift file containing the source code edited by the user of this playground book.
//
//#-end-hidden-code

let turtle = turtleConsole.addTurtle()
turtle.penDown()
turtle.lineColor(.red)
turtle.lineWidth(5)
turtle.rotate(30.0)
turtle.forward(50)
turtle.penDown()
turtle.forward(50)
turtle.arc(radius: 40.0, angle: 270.0)
turtle.penDown()
turtle.forward(100)
turtle.arc(radius: 40.0, angle: 270.0)
turtle.forward(100)
turtle.penDown(fillColor: .yellow)
turtle.arc(radius: 40.0, angle: -270.0)
turtle.forward(200)
turtle.penDown()
turtle.arc(radius: 40.0, angle: -30.0)
turtle.forward(200)
