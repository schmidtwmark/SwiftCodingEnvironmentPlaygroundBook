//
//  testmain.swift
//  
// Code for testing the turtle view
//  Created by Mark Schmidt on 1/15/25.
//

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
