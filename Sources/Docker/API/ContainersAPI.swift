//
//  ContainersAPI.swift
//  Docker
//
//  Created by Matthias Turber on 08.05.18.
//

import Foundation
import NIO


public typealias ContainerLogStream = APIStream


public class ContainersAPI {
    private let session: APISession
    private let apiVersion: String
    private let defaultHeaders: [String : String]

    public init(session: APISession, apiVersion: String, defaultHeaders: [String : String], group: MultiThreadedEventLoopGroup) {
        self.session = session
        self.apiVersion = apiVersion
        self.defaultHeaders = defaultHeaders
    }

    public func inspect(_ nameOrID: String) throws -> ContainerInspection {
        let response: APIResponse = try session.get(
            uri: "/\(apiVersion)/containers/\(nameOrID)/json",
            params: [:],
            headers: defaultHeaders
        )
        switch response.head.status {
        case .ok:
            return try ContainerInspection(JSONString: response.body)
        case .notFound:
            throw DockerError.notFound()
        case .internalServerError:
            throw DockerError.apiError(message: try APIError(JSONString: response.body).message)
        default:
            throw DockerError.apiError(message: "received unexpected status \"\(response.head.status)\"")
        }
    }

    public func logs(_ nameOrID: String, tail: String = "all") throws -> ContainerLogStream {
        let stream: APIStream = try session.get(
            uri: "/\(apiVersion)/containers/\(nameOrID)/logs",
            params: [
                "follow": "true",
                "stdout": "true",
                "stderr": "true",
                "tail": "0"
            ],
            headers: defaultHeaders
        )

        switch stream.head.status {
        case .ok:
            return stream
        case .notFound:
            throw DockerError.notFound()
        default:
            throw DockerError.apiError(message: "received unexpected status \"\(stream.head.status)\"")
        }
    }
}
