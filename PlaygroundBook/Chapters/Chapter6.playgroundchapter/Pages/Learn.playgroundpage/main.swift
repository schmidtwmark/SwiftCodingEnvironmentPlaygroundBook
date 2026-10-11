/*:
 # For Loops
 Counting loops are so common that Swift has a shortcut: the `for` loop. This `while` loop:

 ```
 var count = 0
 while count < 3 {
     robot.turnRight()
     count = count + 1
 }
 ```

 does exactly the same thing as this `for` loop:

 ```
 for _ in 1...3 {
     robot.turnRight()
 }
 ```

 `for _ in 1...3` means "repeat 3 times." Swift keeps count for you, so there's nothing to forget.

 ## Loops inside loops
 A `for` loop can go inside another `for` loop. The inner loop runs all the way through every time the outer loop goes around once.

 ## A variable as the count
 The number of repeats can be a variable, and you can change it as you go:

 ```
 var length = 8
 for _ in 1...length {
     robot.forward()     // runs 8 times
 }
 length = length - 2     // now length is 6
 ```

 ## Count carefully
 In this chapter, the halls keep going past the turns. Walking until you reach a wall goes too far, so count the squares exactly with `for` loops.

 ## Commands
 - `robot.forward()` moves one square forward
 - `robot.turnRight()` turns 90° to the right
 - `robot.turnLeft()` turns 90° to the left
 */
