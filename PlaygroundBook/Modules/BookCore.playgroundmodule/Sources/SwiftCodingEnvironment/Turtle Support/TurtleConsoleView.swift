//
//  TurtleConsoleView.swift
//  StudentCodeTemplate
//
//  Created by Mark Schmidt on 11/16/24.
//

import SwiftUI
import SpriteKit

enum Speed : CGFloat, CaseIterable, Identifiable {
    var id: CGFloat {
        self.rawValue
    }
    
    case slow = 0.5
    case normal = 1.0
    case fast = 2.0
    
    var title: String {
        switch self {
            case .slow: return "Slow"
            case .normal: return "Normal"
            case .fast: return "Fast"
        }
    }
    
    var systemImage: String {
        switch self {
        case .slow: return "tortoise.fill"
        case .normal: return "figure.run"
        case .fast: return "hare.fill"
        }
    }
}

public struct TurtleConsoleView: ConsoleView {
    
    public init(console: TurtleConsole) {
        self.console = console 
    }
    
    @State var speedButtonOpen: Bool = false
    @State var sceneSpeed: Speed = .normal
    
    @ObservedObject var console: TurtleConsole
    @Environment(\.colorScheme) var colorScheme: ColorScheme
    
    public var body: some View{
        SpriteView(scene: console.scene)
            .onTapGesture {
                withAnimation {
                    speedButtonOpen.toggle()
                }
            }
            .onChange(of: colorScheme, {
                console.updateBackground(colorScheme)
            }).overlay(alignment: .bottomTrailing) {
                if speedButtonOpen {
                    HStack(spacing: 10) {
                        ForEach(Speed.allCases) { speed in
                            Button(action: {
                                withAnimation {
                                    console.scene.speed = speed.rawValue
                                    sceneSpeed = speed
                                }
                            }) {
                                Image(systemName: speed.systemImage)
                                    .font(.title2)
                                    .padding(12)
                                    .background(
                                        sceneSpeed == speed
                                        ? Color.blue
                                        : Color.gray.opacity(0.2)
                                    )
                                    .foregroundColor(sceneSpeed == speed ? .white : .primary)
                                    .clipShape(Capsule())
                            }
                        }
                    }
                    .padding()
                    .background(Capsule().fill(Color.gray.opacity(0.1)))
                    .overlay(
                        Capsule()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                    .padding()
                }
            }
            .overlay(alignment: .topTrailing) {
//                Button {
////                    let t = console.addTurtle()
////                    Task {
////                        await t.forward(100)
////                    }
//                    console.addTurtle()
//                } label: {
//                    Text("Test Button")
//                }
                    Button {
                        console.scene.lockCamera()
                    } label: {
                        Image(systemName: "camera.fill")
                            .font(.title2)
                            .padding(12)
                            .background(
                                Color.gray.opacity(0.2)
                            )
                            .foregroundColor(.white)
                            .clipShape(Capsule())

                    }
                    .padding()
                    .opacity(console.scene.showCameraLock ? 1 : 0)
                    .animation(.easeInOut(duration: 0.5), value: console.scene.showCameraLock)
                    
            }
    }
}
