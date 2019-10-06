//
//  APIError.swift
//  Docker
//
//  Created by Matthias Turber on 30.04.18.
//

import ObjectMapper


public struct APIError: ImmutableMappable {

    private enum MapKey {
        static let message = "message"
    }

    let message: String

    public init(map: Map) throws {
        message = try map.value(MapKey.message)
    }

    public func mapping(map: Map) {
        message >>> map[MapKey.message]
    }
}
