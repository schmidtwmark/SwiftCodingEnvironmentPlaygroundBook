//
//  TextConsoleView.swift
//  StudentCodeTemplate
//
//  Created by Mark Schmidt on 11/16/24.
//

import SwiftUI
import Combine

public struct TextConsoleView: ConsoleView {
    public init(console: TextConsole) {
        self.console = console
    }
    
    
    @ObservedObject var console: TextConsole
    @FocusState private var isTextFieldFocused: Bool

    private var hasActiveInput: Bool {
        console.lines.last?.content == .input
    }

    public var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack (alignment: .leading, spacing: 0.0) {
                    ForEach(console.lines) { line in
                        switch line.content {
                        case .output(let text):
                            Text(text)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .fixedSize(horizontal: false, vertical: true)
                        case .input:
                            TextField("", text: $console.userInput)
                                .onSubmit {
                                    console.submitInput(true)
                                }
                                .focused($isTextFieldFocused)
                                .id("activeInput")
                        }
                    }
                }
                .padding()
                .font(.system(size: 17 * console.zoomLevel, design: .monospaced))
                .contentShape(Rectangle())
                .onTapGesture {
                    if hasActiveInput {
                        isTextFieldFocused = true
                    }
                }
            }
            .defaultScrollAnchor(.bottom)
            .scrollIndicators(.visible)
            .onChange(of: console.lines.count) {
                if hasActiveInput {
                    withAnimation {
                        proxy.scrollTo("activeInput", anchor: .bottom)
                    }
                }
            }
        }
        .task {
            console.setFocus = { focus in
                isTextFieldFocused = focus
            }
        }
    }
    
}
