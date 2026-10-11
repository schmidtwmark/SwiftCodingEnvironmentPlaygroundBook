/*:
 # Counting Loops
 A `while` loop can also repeat something an exact number of times. Use a variable to count:

 ```
 var count = 0
 while count < 3 {
     robot.turnRight()
     count = count + 1
 }
 ```

 `var` makes a variable you're allowed to change. `count` starts at 0 and goes up by 1 each time around the loop: 0, 1, 2. When it reaches 3, `count < 3` is `false` and the loop stops. This example turns right 3 times.

 Don't forget `count = count + 1`. Without it, `count` stays 0 and the loop never stops!

 ## Loops inside loops
 The code you repeat can have a loop of its own. This walks along 4 walls, turning right at each one:

 ```
 var count = 0
 while count < 4 {
     while robot.facingEmptySpace() {
         robot.forward()
     }
     robot.turnRight()
     count = count + 1
 }
 ```

 ## Counting again
 To use `count` for a second loop, set it back to 0 first:

 ```
 count = 0
 ```

 ## Enemies
 An enemy moves one square every time the robot steps, turns, or waits. If one catches the robot, add `robot.wait()` before your loop starts, not inside it. Then try one more wait, and one more, until the robot slips past.

 **Tip:** when a level is a bigger version of the last one, copy your code and change the numbers.

 ## Commands
 - `robot.forward()` moves one square forward
 - `robot.turnRight()` turns 90° to the right
 - `robot.turnLeft()` turns 90° to the left
 - `robot.wait()` waits one turn. Lasers and enemies keep moving.
 - `robot.facingEmptySpace()` is `true` when the square right in front of the robot isn't a wall
 */
