//
//  Console.swift
//  StudentCodeTemplate
//
//  Created by Mark Schmidt on 11/16/24.
//

import SwiftUI
import PlaygroundSupport

func timeDisplay(_ start: Date, _ end: Date) -> String{
    
    let interval = end.timeIntervalSince(start)
    if interval < 1 {
        return String(format: "%.0fms", interval * 1000)
    } else {
        return String(format: "%.2fs", interval)
    }
}

public enum RunState : Equatable {
    case idle
    case running
    case success
    case cancel
    case failed(String)
    
    
    var displayString: String {
        switch self {
        case .running: return "Running for "
        case .idle: return "Idle for "
        case .success: return "Success in "
        case .cancel: return "Canceled in "
        case .failed(let message): return message
        }
    }
    
    var color: Color {
        switch self {
        case .running, .idle: return .gray
        case .success: return .green
        case .failed: return .red
        case .cancel: return .yellow
       }
    }
    
    var icon: String {
        switch self {
        case .running, .idle: return "circle"
        case .success: return "checkmark.circle.fill"
        case .failed, .cancel: return "xmark.circle.fill"
        }
    }
    
    var isFailure: Bool {
        switch self {
        case .failed(_): return true
        default:  return false
        }
    }
}

@MainActor
public protocol Console : ObservableObject {
    
    init(colorScheme: ColorScheme)
    
    func tick()
    
    var state: RunState { get }
    
    var durationString: String { get }
    
    var title: String { get }
    
    var messageHandler: (any PlaygroundLiveViewMessageHandler)? { get set }
    
    func receive(_ message: PlaygroundSupport.PlaygroundValue)
    
    func start(messageHandler: any PlaygroundLiveViewMessageHandler)

    func finish(_ newState: RunState)
    
    func clear()
    
    var disableClear: Bool { get }
}

struct ConsoleError: Error {
    var message: String
}


@MainActor
public class BaseConsole<C: Console> {
    
    
    @Published public var state: RunState = .idle
    @Published var startTime : Date? = nil
    @Published var endTime : Date? = nil
    @Published var timeString = ""
    
    
    public var durationString: String {
        if let startTime = startTime,
           let endTime = endTime {
            return timeDisplay(startTime, endTime)
        }
        return timeString
    }
    
    public func tick() {
        if let start = startTime {
            timeString = timeDisplay(start, Date())
        }
    }
    
    public func start(messageHandler: any PlaygroundLiveViewMessageHandler) {
        self.messageHandler = messageHandler
        state = .running
        startTime = Date()
    }
    
    public func finish(_ newState: RunState) {
        state = newState
        endTime = Date()
    }
    
    public var messageHandler: (any PlaygroundLiveViewMessageHandler)?
    

    public func clear() {
        startTime = nil
        endTime = nil
        state = .idle
    }
}

public protocol ConsoleView: View {
    associatedtype ConsoleType : Console
    init(console: ConsoleType)
}

public protocol ConsoleMessage {
    var playgroundValue: PlaygroundValue { get }
    
    init?(_ playgroundValue: PlaygroundValue)
}

extension PlaygroundRemoteLiveViewProxy {
    func send(_ message: ConsoleMessage) {
        send(message.playgroundValue)
    }
}

extension PlaygroundLiveViewMessageHandler {
    func send(_ message: ConsoleMessage) {
        send(message.playgroundValue)
    }
}
