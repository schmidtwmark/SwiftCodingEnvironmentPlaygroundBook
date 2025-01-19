/*:

 # Text Console Documentation
 
 This playground provides a `console` object that enables writing and reading data from the console.
 
 */



/*:
 # `console.write(_ text: String)`
 
 Displays the provided text to the user.
 
 ```
 console.write("Hello World 🦕")
 
 let greeting = "Hello"
 console.write(greeting + " Mr. Schmidt!")
 ```
 
 */



/*:
 # `console.write(_ coloredText: ColoredString)`
 
 Displays the provided colored text. A `ColoredString` object is made up of multiple colored substrings, so a single line can be multicolored.
 
 ```
 console.write(ColoredString("This text is blue", .blue))
 
 console.write(ColoredString("Red", .red) + ColoredString("Green", .green)
 ```
 
 */



/*:
 # `console.read(_ prompt: String) -> String`
 
 Displays the provided prompt, waits for the user to enter text, then returns that text.
 
 ```
 let name = console.read("What is your name?")
 
 console.write("Hello " + name)
 ```
 
 */

