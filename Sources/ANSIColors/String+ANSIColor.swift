//
//  String+ANSIColor.swift
//  ANSIColors
//
//  Created by Matthias Turber on 13.05.18.
//

import Foundation

public extension String {
    
    public init(_ string: String, colored color: ANSIColor) {
        self.init(color.rawValue + string + ANSIColor.end)
    }
    
    public static func color(_ string: String, ANSI color: ANSIColor) -> String {
        return color.rawValue + string + ANSIColor.end
    }
    
    public mutating func colorANSI(_ color: ANSIColor) {
        self = color.rawValue + self + ANSIColor.end
    }
    
    public func coloredANSIString(_ color: ANSIColor) -> String {
        return color.rawValue + self + ANSIColor.end
    }
}
