# Swift Playgrounds Teaching Templates

An Xcode project for creating Swift Playgrounds templates for teaching Swift programming. Contains two templates: **TextConsole** (text-based REPL) and **TurtleConsole** (PyTurtle-like graphics).

## Project Structure

```
SwiftCodingEnvironmentPlaygroundBook/
├── PlaygroundBook/                    # Main playground book package
│   ├── Chapters/
│   │   ├── Chapter1.playgroundchapter/  # TextConsole template
│   │   └── Chapter2.playgroundchapter/  # TurtleConsole template
│   ├── Modules/
│   │   ├── BookCore.playgroundmodule/   # Core implementations
│   │   ├── BookAPI.playgroundmodule/    # TextConsole API export
│   │   └── TurtleAPI.playgroundmodule/  # TurtleConsole API export
│   ├── PrivateResources/              # Assets, icons
│   └── Manifest.plist
├── PlaygroundBook.xcodeproj/
├── LiveViewTestApp/                   # Debug/testing app
├── ConfigFiles/                       # Build configuration
└── SupportingContent/                 # Frameworks
```

## Architecture Overview

### Communication Flow

```
User Code (student writes)
    ↓
API Module (BookAPI / TurtleAPI)
    ↓ PlaygroundValue messages
LiveViewController (routes messages)
    ↓
Console Implementation (TextConsole / TurtleConsole)
    ↓
SwiftUI/SpriteKit View
```

### Key Components

| Component | Location | Purpose |
|-----------|----------|---------|
| `LiveViewController<CV>` | `BookCore/Sources/LiveViewController.swift` | Generic controller hosting any ConsoleView |
| `LiveViewClient<Req, Res>` | `BookCore/Sources/LiveViewSupport.swift` | Bidirectional messaging base class |
| `Console` protocol | `BookCore/Sources/SwiftCodingEnvironment/Support Code/Console.swift` | Common interface for all consoles |
| `CodeEnvironmentView<CV>` | `BookCore/Sources/SwiftCodingEnvironment/Support Code/CodeEnvironmentView.swift` | Container view with title bar and controls |

## Templates

### TextConsole (Chapter 1)

A text-based REPL console for basic I/O operations.

**Key Files:**
- `BookCore/Sources/SwiftCodingEnvironment/Text Support/TextConsole.swift` - Console implementation
- `BookCore/Sources/SwiftCodingEnvironment/Text Support/TextConsoleView.swift` - SwiftUI view
- `BookAPI/Sources/BookAPI.swift` - Exports `console` variable

**Student API:**
```swift
import BookAPI

console.write("Hello, World!")
console.write("Colored text".colored(.red))
let name = console.read("Enter your name: ")
```

**Commands:**
- `write(String)` - Output plain text
- `write(ColoredString)` - Output colored text
- `read(String) -> String` - Prompt for input, blocks until response

**Implementation Notes:**
- Uses `@Published lines: [Line]` array for display
- Line buffer capped at 100 lines (MAX_LINES)
- Supports colored text via `ColoredString` utility

### TurtleConsole (Chapter 2)

A PyTurtle-like graphics environment using SpriteKit.

**Key Files:**
- `BookCore/Sources/SwiftCodingEnvironment/Turtle Support/TurtleConsole.swift` - Console + Turtle + TurtleScene
- `BookCore/Sources/SwiftCodingEnvironment/Turtle Support/TurtleConsoleView.swift` - SpriteKit view
- `TurtleAPI/Sources/TurtleAPI.swift` - Exports `turtleConsole` variable

**Student API:**
```swift
import TurtleAPI

let turtle = turtleConsole.addTurtle()
turtle.forward(100)
turtle.rotate(90)
turtle.penDown(.red)
turtle.forward(50)
turtle.arc(radius: 50, angle: 180)
turtle.penUp()
turtle.lineColor(.blue)
turtle.lineWidth(3.0)
```

**Commands:**
- `forward(Double)` / `backward(Double)` - Move turtle
- `rotate(Double)` - Rotate by degrees
- `arc(radius:angle:)` - Draw an arc
- `penUp()` / `penDown(Color)` - Control drawing
- `lineColor(Color)` / `lineWidth(Double)` - Set line style

**Implementation Notes:**
- Uses SpriteKit for graphics rendering
- Canvas size: 5000x5000 points
- Supports camera pan/pinch zoom
- Speed control: 0.5x, 1.0x, 2.0x
- All turtle actions are async/await for smooth animation

## Key Protocols

### Console Protocol
```swift
@MainActor
protocol Console: AnyObject, ObservableObject {
    var state: RunState { get set }
    var title: String { get }
    init(colorScheme: ColorScheme)
    func receive(_ message: PlaygroundValue)
    func tick()
    func start()
    func finish(_ state: RunState)
    func clear()
}
```

### ConsoleMessage Protocol
```swift
protocol ConsoleMessage {
    var playgroundValue: PlaygroundValue { get }
    init?(_ playgroundValue: PlaygroundValue)
}
```

### ConsoleView Protocol
```swift
protocol ConsoleView: View {
    associatedtype ConsoleType: Console
    init(console: ConsoleType)
}
```

## RunState Enum

Tracks console execution state:
- `.idle` - Not running
- `.running` - Show progress spinner
- `.success` - Green checkmark + duration
- `.cancel` - Yellow X
- `.failed(String)` - Red X + error message

## Adding a New Template

1. **Create Console Implementation:**
   ```swift
   @MainActor
   public final class MyConsole: BaseConsole<MyConsole>, Console {
       // Implement Console protocol
   }
   ```

2. **Define Commands:**
   ```swift
   enum MyCommand: ConsoleMessage {
       case someAction(String)
       // Implement playgroundValue and init
   }
   ```

3. **Create SwiftUI View:**
   ```swift
   struct MyConsoleView: ConsoleView {
       @ObservedObject var console: MyConsole
       init(console: MyConsole) { self.console = console }
       var body: some View { /* ... */ }
   }
   ```

4. **Create API Module:**
   - Add new module under `PlaygroundBook/Modules/`
   - Export client: `public let myClient = MyLiveViewClient()`

5. **Create Chapter:**
   - Add chapter under `PlaygroundBook/Chapters/`
   - Set `LiveView.swift` to use `LiveViewController<MyConsoleView>()`
   - Configure Manifest.plist

## Build Configuration

**Key Settings (ConfigFiles/BuildSettings.xcconfig):**
```xcconfig
BUNDLE_IDENTIFIER_PREFIX = com.markschmidt
PLAYGROUND_BOOK_FILE_NAME = SwiftCodingEnvironment
```

**Template Selection:**
- `SELECTED_CHAPTER` - Which chapter to include
- `SELECTED_API` - Which API module to auto-import

**Xcode Targets:**
1. `PlaygroundBook` - Main .playgroundbook output
2. `BookCore` - Core library (all implementations)
3. `BookAPI` - TextConsole API export
4. `TurtleAPI` - TurtleConsole API export
5. `LiveViewTestApp` - Development testing app

## Testing During Development

Use LiveViewTestApp to test live views:

1. Open `LiveViewTestApp/AppDelegate.swift`
2. Set the live view type:
   ```swift
   liveViewConfiguration = .fullScreen
   liveView = LiveViewController<TextConsoleView>()
   // or
   liveView = LiveViewController<TurtleConsoleView>()
   ```
3. Run the LiveViewTestApp target

## Utilities

### ColoredString
Location: `BookCore/Sources/SwiftCodingEnvironment/Support Code/ColoredString.swift`

```swift
// Create colored text
let text = "Hello".colored(.red) + " World".colored(.blue)

// Uses ARGB hex encoding for PlaygroundValue serialization
extension Color {
    init(hex: Int)  // From ARGB hex
    var hex: Int    // To ARGB hex
}
```

## Platform Support

- Primary: iPad (iOS)
- iOS Simulator supported
- Mac Catalyst supported

## Important Implementation Details

- All consoles run on `@MainActor`
- PlaygroundValue uses dictionaries with string keys for serialization
- Turtle animations use `withCheckedContinuation` for async/await support
- TextConsole auto-scrolls to bottom with `.defaultScrollAnchor(.bottom)`
- TurtleScene camera follows turtle when locked
