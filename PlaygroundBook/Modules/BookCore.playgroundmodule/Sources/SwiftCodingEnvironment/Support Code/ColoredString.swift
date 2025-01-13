//
//  ColoredString.swift
//  StudentCodeTemplate
//
//  Created by Mark Schmidt on 11/15/24.
//

import SwiftUI
import PlaygroundSupport

extension Color {
    init(hex: Int) {
        self.init(
            .sRGB,
            red: Double((hex >> 24) & 0xff) / 255,
            green: Double((hex >> 16) & 0xff) / 255,
            blue: Double((hex >> 08) & 0xff) / 255,
            opacity: Double((hex >> 00) & 0xff) / 255
        )
    }
    
    var hex: Int {
        #if canImport(UIKit)
        let uiColor = UIColor(self)
        #elseif canImport(AppKit)
        let uiColor = NSColor(self)
        #else
        return nil
        #endif
        
        // Extract RGB components
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        // Convert to hex
        let r = Int(red * 255) << 24
        let g = Int(green * 255) << 16
        let b = Int(blue * 255) << 8
        let a = Int(alpha * 255)
        
        return r | g | b | a
    }
}

public struct ColoredString : Sendable {
    struct Substring {
        var string: String
        var color: Color
    }
    
    public init() {
        substrings = []
    }
    
    public init(_ string: String, _ color: Color) {
        substrings = [.init(string: string, color: color)]
    }
    
    public init?(_ value: PlaygroundValue) {
        guard case let .array(array) = value else {
                return nil
        }
        
        var substrings: [Substring] = []
            
        for item in array {
            guard case let .array(substring) = item else {
                return nil
            }
            
            guard case let .string(string) = substring[0] else { return nil }
            guard case let .integer(hex) = substring[1] else { return nil }
            let color = Color(hex: hex)
            
            substrings.append(.init(string: string, color: color))
        }
        
        self.substrings = substrings
    }
    
    
    private init(_ substrings: [Substring]){
        self.substrings = substrings
    }
    
    var substrings: [Substring]
    
    var attributedString: AttributedString {
        return substrings.reduce(into: AttributedString()) { output, substring in
            var attributedSubstring = AttributedString(substring.string)
            attributedSubstring.foregroundColor = substring.color
            output.append(attributedSubstring)
        }
        
    }
    
    var playgroundValue: PlaygroundValue {
        .array(substrings.map({ substring in
                .array([.string(substring.string), .integer(substring.color.hex)])
        }))
    }
    
    public var string: String {
        return substrings.reduce("") { $0 + $1.string }
    }
    
    public static func += (lhs: inout ColoredString, rhs: ColoredString) {
        lhs.substrings.append(contentsOf: rhs.substrings)
    }
    
    public static func += (lhs: inout ColoredString, rhs: String) {
        if var last = lhs.substrings.last {
            last.string += rhs
        } else {
            lhs.substrings.append(.init(string: rhs, color: .primary))
        }
    }
    
    public static func + (lhs: ColoredString, rhs: ColoredString) -> ColoredString {
        return .init(lhs.substrings + rhs.substrings)
    }
    
    public static func + (lhs: ColoredString, rhs: String) -> ColoredString {
        if var last = lhs.substrings.last {
            last.string += rhs
            return lhs
        } else {
            return .init(rhs, .primary)
        }
        
    }
}

extension String {
    public func colored(_ color: Color) -> ColoredString {
        return ColoredString(self, color)
    }
    
    public static func += (lhs: inout String, rhs: ColoredString) {
        if lhs.isEmpty {
            lhs = rhs.string
        }
    }
    
    public static func + (lhs: String, rhs: ColoredString) -> ColoredString {
        if var first = rhs.substrings.first {
            first.string = lhs + first.string
            return rhs
        } else {
            return .init(lhs, .primary)
        }
    }
}
