//
//  ANSIColor.swift
//  ANSIColors
//
//  Created by Matthias Turber on 13.05.18.
//

import Foundation


public enum ANSIColor: String {
    
    static let end = "\u{001B}[0m"
    
    case black = "\u{001B}[0;30m"
    case red = "\u{001B}[0;31m"
    case green = "\u{001B}[0;32m"
    case yellow = "\u{001B}[0;33m"
    case blue = "\u{001B}[0;34m"
    case magenta = "\u{001B}[0;35m"
    case cyan = "\u{001B}[0;36m"
    case white = "\u{001B}[0;37m"
    case brightBlack = "\u{001B}[0;90m"
    case brightRed = "\u{001B}[0;91m"
    case brightGreen = "\u{001B}[0;92m"
    case brightYellow = "\u{001B}[0;93m"
    case brightBlue = "\u{001B}[0;94m"
    case brightMagenta = "\u{001B}[0;95m"
    case brightCyan = "\u{001B}[0;96m"
    case brightWhite = "\u{001B}[0;97m"
    
    public var name: String {
        switch self {
        case .black: return "Black"
        case .red: return "Red"
        case .green: return "Green"
        case .yellow: return "Yellow"
        case .blue: return "Blue"
        case .magenta: return "Magenta"
        case .cyan: return "Cyan"
        case .white: return "White"
        case .brightBlack: return "Bright Black"
        case .brightRed: return "Bright Red"
        case .brightGreen: return "Bright Green"
        case .brightYellow: return "Bright Yellow"
        case .brightBlue: return "Bright Blue"
        case .brightMagenta: return "Bright Magenta"
        case .brightCyan: return "Bright Cyan"
        case .brightWhite: return "Bright White"
        }
    }
    
    public static var basicColors: [ANSIColor] {
        return [.black, .red, .green, .yellow, .blue, .magenta, .cyan, .white]
    }
    
    public static var brightColors: [ANSIColor] {
        return [.brightBlue, .brightRed, .brightGreen, .brightYellow, .brightBlue, .brightMagenta, .brightCyan, .brightWhite]
    }
    
    public static var allColors: [ANSIColor] {
        return basicColors + brightColors
    }
}
