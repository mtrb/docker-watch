//
//  SystemAPI.swift
//  Docker
//
//  Created by Matthias Turber on 08.05.18.
//

import Foundation
import NIO

public class SystemAPI {

    private let session: APISession
    private let apiVersion: String
    private let defaultHeaders: [String : String]

    public init(session: APISession, apiVersion: String, defaultHeaders: [String : String], group: MultiThreadedEventLoopGroup) {
        self.session = session
        self.apiVersion = apiVersion
        self.defaultHeaders = defaultHeaders
    }

    public func version() throws -> SystemVersion {
        let response: APIResponse = try session.get(uri: "/\(apiVersion)/version", params: [:], headers: defaultHeaders)
        guard response.isOk() else {
            throw DockerError.apiError(message: try APIError(JSONString: response.body).message)
        }
        return try SystemVersion(JSONString: response.body)
    }

    public func ping() throws -> Bool {
        let response: APIResponse = try session.get(uri: "/\(apiVersion)/_ping", params: [:], headers: defaultHeaders)
        guard response.isOk() else {
            throw DockerError.apiError(message: try APIError(JSONString: response.body).message)
        }
        return true
    }

    public func events() throws -> APIEventStream {
        let stream: APIStream = try session.get(uri: "/\(apiVersion)/events", params: [:], headers: defaultHeaders)
        guard stream.isOk() else {
            throw DockerError.apiError(message: "\(self).\(#function): received HTTP status code \(stream.head.status)")
        }
        return APIEventStream(stream: stream)
    }
}
