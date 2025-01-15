//
//  Console.swift
//  StudentCodeTemplate
//
//  Created by Mark Schmidt on 11/16/24.
//

import SwiftUI
import Combine
import PlaygroundSupport

let MAX_LINES = 100

public enum TextCommand{
    case write(String)
    case read(String)
    case writeColor(ColoredString)
}

extension TextCommand : ConsoleMessage {
    public init?(_ value: PlaygroundValue) {
        guard case let .dictionary(dict) = value else {
            return nil
        }
        
        guard case let .string(command)? = dict["Command"] else {
            return nil
        }
        
        switch command {
            case "Write":
                guard case let .string(text)? = dict["Text"] else { return nil }
                self = .write(text)
            case "Read":
                guard case let .string(text)? = dict["Prompt"] else { return nil }
                self = .read(text)
            case "WriteColor":
                guard let array = dict["ColoredText"] else { return nil }
                guard let coloredString = ColoredString(array) else { return nil }
                self = .writeColor(coloredString)
            default: return nil
        }
    }
    
    public var playgroundValue: PlaygroundValue {
        
        switch self {
        case .write(let text): return .dictionary(["Command": .string("Write"), "Text": .string(text)])
        case .read(let text): return .dictionary(["Command": .string("Read"), "Prompt": .string(text)])
        case .writeColor(let coloredString): return .dictionary(["Command": .string("WriteColor"), "ColoredText": coloredString.playgroundValue])
        }
    }
}

public enum TextResponse {
    case submit(String)
}
extension TextResponse : ConsoleMessage {
    public init?(_ value: PlaygroundValue) {
        guard case let .dictionary(dict) = value else {
            return nil
        }
        
        guard case let .string(command)? = dict["Command"] else {
            return nil
        }
        
        switch command {
        case "Submit":
            guard case let .string(text)? = dict["Text"] else { return nil }
            self = .submit(text)
        default: return nil
        }
    }
    
    public var playgroundValue: PlaygroundValue {
        
        switch self {
        case .submit(let text): return .dictionary(["Command": .string("Submit"), "Text": .string(text)])
        }
    }
}
    

@MainActor
public final class TextConsole: BaseConsole<TextConsole>, Console {
    
    struct Line : Identifiable {
        
        enum LineContent : Equatable {
            case output(AttributedString)
            case input
        }
        var id = UUID()
        var content: LineContent
    }
    
    public init(colorScheme: ColorScheme) {
        super.init()
    }
    
    var setFocus: ((Bool) -> Void)? = nil
    
    @Published var lines: Array<Line> = Array()
    @Published var userInput = ""
    
    private func append(_ line: Line) {
        if lines.count >= MAX_LINES {
            lines.removeFirst()
        }
        lines.append(line)
    }
    
    public func write(_ line: String) {
        self.append(Line(content: .output(.init(stringLiteral: line))))
    }
    public func write(_ colored: ColoredString) {
        self.append(Line(content: .output(colored.attributedString)))
    }
    
    public func read(_ prompt: String) {
        self.append(Line(content: .output(.init(stringLiteral: prompt))))
        self.append(Line(content: .input))
        self.setFocus?(true)
    }
    
    public override func start(messageHandler: any PlaygroundLiveViewMessageHandler) {
        lines = []
        userInput = ""
        super.start(messageHandler: messageHandler)
    }
    
    public override func finish(_ newState: RunState) {
        submitInput(false)
        super.finish(newState)
    }
    
    public override func clear() {
        super.clear()
        lines = []
        userInput = ""
    }
    
    func submitInput(_ resume: Bool) {
        if lines.count > 0 {
            if lines[lines.count - 1].content == .input {
                lines[lines.count - 1].content = .output(.init(stringLiteral: userInput))
            }
            
        }
        if resume {
            messageHandler?.send(TextResponse.submit(userInput))
        }
        userInput = ""
    }
    
    public var disableClear: Bool {
        lines.isEmpty
    }
    
    public var title: String { "Console" }
    
    
    public func receive(_ message: PlaygroundValue) {
        guard let textCommand = TextCommand(message) else {
            self.write("Invalid message \(message)")
            return }
        switch textCommand {
        case .write(let text):
            self.write(text)
        case .read(let prompt):
            self.read(prompt)
        case .writeColor(let text):
            self.write(text)
        }
    }
}
