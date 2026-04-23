//
//  ColoredString.swift
//  StudentCodeTemplate
//
//  Created by Mark Schmidt on 11/15/24.
//

import SwiftUI
import PlaygroundSupport

extension Color {
    /// Initialize from a 32-bit ARGB integer, e.g. `0xFF0000FF` for opaque red.
    /// Byte order: red, green, blue, alpha (high to low).
    public init(hex: Int) {
        self.init(
            .sRGB,
            red: Double((hex >> 24) & 0xff) / 255,
            green: Double((hex >> 16) & 0xff) / 255,
            blue: Double((hex >> 08) & 0xff) / 255,
            opacity: Double((hex >> 00) & 0xff) / 255
        )
    }

    /// Initialize from a CSS-style hex string: "#RRGGBB", "RRGGBB", "#RRGGBBAA", or "RRGGBBAA".
    /// Returns an opaque black color if the string cannot be parsed.
    public init(hex: String) {
        var trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("#") {
            trimmed.removeFirst()
        }
        guard trimmed.count == 6 || trimmed.count == 8,
              let value = UInt64(trimmed, radix: 16) else {
            self.init(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)
            return
        }
        let r, g, b, a: Double
        if trimmed.count == 6 {
            r = Double((value >> 16) & 0xff) / 255
            g = Double((value >> 08) & 0xff) / 255
            b = Double((value >> 00) & 0xff) / 255
            a = 1.0
        } else {
            r = Double((value >> 24) & 0xff) / 255
            g = Double((value >> 16) & 0xff) / 255
            b = Double((value >> 08) & 0xff) / 255
            a = Double((value >> 00) & 0xff) / 255
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    /// Factory form of `Color(hex:)` that enables leading-dot syntax,
    /// e.g. `turtle.lineColor(.hex("ffaabb"))`.
    public static func hex(_ string: String) -> Color {
        Color(hex: string)
    }

    /// Factory form of `Color(hex:)` that enables leading-dot syntax,
    /// e.g. `turtle.lineColor(.hex(0xffaabbff))`.
    public static func hex(_ value: Int) -> Color {
        Color(hex: value)
    }

    /// Factory form of `Color(red:green:blue:alpha:)` for leading-dot syntax,
    /// e.g. `turtle.lineColor(.rgb(255, 170, 187))`.
    public static func rgb(_ red: Int, _ green: Int, _ blue: Int, alpha: Int = 255) -> Color {
        Color(red: red, green: green, blue: blue, alpha: alpha)
    }

    /// Initialize from 0-255 RGB byte components, with optional 0-255 alpha.
    public init(red: Int, green: Int, blue: Int, alpha: Int = 255) {
        self.init(
            .sRGB,
            red: Double(red) / 255,
            green: Double(green) / 255,
            blue: Double(blue) / 255,
            opacity: Double(alpha) / 255
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

public struct ColoredString : @unchecked Sendable {
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
