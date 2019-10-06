//
//  Int64Transform.swift
//  Docker
//
//  Created by Matthias Turber on 05.05.18.
//

import ObjectMapper


public class Int64Transform: TransformType {
    public typealias Object = Int64
    public typealias JSON = Int

    public init() {}

    open func transformFromJSON(_ value: Any?) -> Int64? {
        if let int64Value = value as? Int {
            return Int64(int64Value)
        }
        return nil
    }

    open func transformToJSON(_ value: Int64?) -> Int? {
        if let int64Value = value {
            return Int(int64Value)
        }
        return nil
    }
}
