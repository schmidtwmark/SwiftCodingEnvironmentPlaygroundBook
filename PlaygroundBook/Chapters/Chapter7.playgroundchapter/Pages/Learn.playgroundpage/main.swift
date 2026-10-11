/*:
 # If and Functions
 ## An if inside a loop
 A loop can make a decision every time it goes around. This one keeps going until the robot reaches the flag. Each time around, it either turns or moves:

 ```
 while !robot.isOnGoal() {
     if robot.facingWall() {
         robot.turnRight()
     } else {
         robot.forward()
     }
 }
 ```

 `robot.isOnGoal()` is `true` when the robot is on the flag. A short program like this can follow a whole winding path, no matter how long it is.

 ## Not: `!`
 `!` means **not**. It flips `true` to `false` and `false` to `true`. `!robot.isOnGoal()` means "the robot is **not** on the flag", so `while !robot.isOnGoal()` keeps going until the robot reaches the flag. In the same way, `!robot.facingWall()` means the same thing as `robot.facingEmptySpace()`.

 ## An if inside an if
 An `if` can have another `if` inside it. For example, after turning right, check `robot.facingWall()` again to find out whether the path really goes left.

 ## Functions
 A **function** gives a name to a group of commands, so you can use them again and again:

 ```
 func turnAround() {
     robot.turnRight()
     robot.turnRight()
 }

 turnAround()   // runs both turns
 ```

 A function can use other functions, including ones you wrote yourself.

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
