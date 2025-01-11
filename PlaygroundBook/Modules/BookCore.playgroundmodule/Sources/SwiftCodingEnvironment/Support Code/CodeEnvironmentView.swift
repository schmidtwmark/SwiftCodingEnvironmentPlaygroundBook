//
//  CodeEnvironmentView.swift
//  StudentCodeTemplate
//
//  Created by Mark Schmidt on 11/14/24.
//

import SwiftUI
import Combine


let CORNER_RADIUS = 8.0

public struct CodeEnvironmentView<CV: ConsoleView>: View {
    
    
    @Environment(\.colorScheme) var colorScheme
    @ObservedObject var console: CV.ConsoleType
    let timer = Timer.publish(every: 0.01, on: .main, in: .common).autoconnect()
    
    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(console.title)
                        .padding()
                        .background(Color(uiColor: .secondarySystemBackground))
                        .clipShape(.rect(topLeadingRadius: CORNER_RADIUS, topTrailingRadius: CORNER_RADIUS))
                Spacer()
                if console.state != .idle {
                    HStack {
                        if console.state == .running {
                            ProgressView()
                        } else {
                            Image(systemName: console.state.icon)
                        }
                        Text("\(console.state.displayString)\(!console.state.isFailure ?  console.durationString : "")")
                    }
                    .padding(5)
                    .background(console.state.color)
                    .clipShape(.rect(cornerRadius: CORNER_RADIUS))
                }
            }
            CV(console: console)
                .background(Color(uiColor: .secondarySystemBackground))
                .clipShape(.rect(bottomLeadingRadius: CORNER_RADIUS, bottomTrailingRadius: CORNER_RADIUS, topTrailingRadius: CORNER_RADIUS))
            Spacer(minLength: CORNER_RADIUS)
                Button(role: .destructive) {
                    withAnimation {
                        console.clear()
                    }
                } label: {
                    Label("Clear", systemImage: "trash")
                        .padding(10)
                        .frame(maxWidth: .infinity)
                        .fontWeight(.heavy)
                }
                .disabled(console.disableClear)
                .frame(maxWidth: .infinity)
        }
        .onReceive(timer) { _ in
            console.tick()
        }
        .font(.system(.body, design: .monospaced))
        .padding()
    }
}
