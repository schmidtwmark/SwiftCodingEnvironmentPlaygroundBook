/*:
 # While Loops
 The halls in this chapter are long. Writing `robot.forward()` over and over would take forever, so let a **loop** repeat it for you.

 A `while` loop repeats the code inside its `{ }` as long as its condition is true:

 ```
 while robot.facingEmptySpace() {
     robot.forward()
 }
 ```

 Read it as "while the robot is facing empty space, move forward." `robot.facingEmptySpace()` is `true` when the square right in front of the robot isn't a wall. The robot keeps moving until it reaches a wall, no matter how long the hall is.

 After the loop, your code keeps going. Turn, then use another loop to walk down the next hall.

 ## Waiting for lasers
 Some halls have lasers that blink on and off. This loop waits until the laser in front of the robot is off:

 ```
 while robot.laserAhead() {
     robot.wait()
 }
 ```

 To check before **every** step, put it inside your walking loop. A loop can go inside another loop.

 **Tip:** many levels look like the one before. Copy your code, paste it into the next level, and change only what needs changing.

 ## Commands
 - `robot.forward()` moves one square forward
 - `robot.turnRight()` turns 90° to the right
 - `robot.turnLeft()` turns 90° to the left
 - `robot.wait()` waits one turn. Lasers and enemies keep moving.
 - `robot.facingEmptySpace()` is `true` when the square right in front of the robot isn't a wall
 - `robot.laserAhead()` is `true` when a laser right in front of the robot is on, or about to turn on
 */
