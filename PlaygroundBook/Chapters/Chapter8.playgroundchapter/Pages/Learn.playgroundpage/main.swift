/*:
 # Bug Hunt
 In 1947, the people running the Harvard Mark II computer found a real moth stuck inside it. They taped it into their logbook with the note "First actual case of bug being found." Engineers already called problems "bugs," which is why the note says *actual*. Programmers have been hunting them ever since.

 Every program in this book has a bug, and some have more than one. Find them and fix them, at your own pace.

 ## Two kinds of bugs
 - **Compiler errors.** Swift can't understand the code, so it won't run at all. A red error appears next to the problem. Tap it to read the message.
 - **Runtime bugs.** The code runs, but it does the wrong thing: the robot crashes, the console prints the wrong thing, or the program never stops. If it never stops, tap **Stop**.

 On text pages, a green **Success** only means the program finished. It says Success even when the output is wrong, so always compare the output with **What it should do**.

 ## How to hunt
 1. Read **What it should do** at the top of the page.
 2. Run the code. Is there a red error, or does it run and do the wrong thing?
 3. **Red error:** read the message, then look at that line. Sometimes the real mistake is higher up, even a few lines above it.
 4. **Wrong result:** read the code one line at a time and act it out. Find the first line where the computer does something you didn't expect.
 5. Make one small change, then run it again.

 Most bugs can be fixed by changing, moving, or adding a line or two. You never need to rewrite the whole program.

 When a page says to type something like `LEFT`, type it in capital letters, just like your adventure game.

 ## Functions (for the last few pages)
 `func` gives a name to a group of commands, like `forwardUntilWall()` from the slides. Writing a function doesn't run it. Writing its name with `()` does:

 ```
 func turnAround() {
     robot.turnRight()
     robot.turnRight()
 }

 turnAround()   // this line runs it
 ```

 Bugs 26 to 30 are **challenge bugs**. They're extra tricky, so don't worry if you don't get to them.

 Stuck? The **Hints** page at the end has a hint for every bug.
 */
