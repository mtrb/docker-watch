//
//  DockerClient.swift
//  DockerWatch
//
//  Created by Matthias Turber on 05.04.18.
//  Copyright © 2018 Matthias Turber. All rights reserved.
//

import Foundation
import NIO


public enum DockerError: Error {
    case libraryInternal(message: String)
    case apiError(message: String)
    case notFound()
    case invalidHostURL(url: String)
    case clientCertificateMissing(path: String)
    case clientKeyMissing(path: String)
    case caCertificateMissing(path: String)
    case invalidEnvironment()
}


public class DockerClient {
    
    private enum Env {
        static let tlsVerifyVariable = "DOCKER_TLS_VERIFY"
        static let hostVariable = "DOCKER_HOST"
        static let certPathVariable = "DOCKER_CERT_PATH"
        static let clientCert = "cert.pem"
        static let clientKey = "key.pem"
        static let caCert = "ca.pem"
        static let socketPath = "/var/run/docker.sock"
        static let tcpScheme = "tcp"
        static let unixScheme = "unix"
    }
    
    private let apiVersion = "v1.37"
    private let defaultHeaders = ["User-Agent": "DockerWatch/0.0.0 DockerClient"]
    private let group = MultiThreadedEventLoopGroup(numberOfThreads: ProcessInfo.processInfo.activeProcessorCount)
    
    public let system: SystemAPI
    public let containers: ContainersAPI
    
    public init(host: String, port: Int, clientCert: String, clientKey: String, caCert: String) throws {
        let session = try APISession(
            host: host,
            port: port,
            clientCert: clientCert,
            clientKey: clientKey,
            rootCert: caCert,
            group: group)
        
        system = SystemAPI(session: session, apiVersion: apiVersion, defaultHeaders: defaultHeaders, group: group)
        containers = ContainersAPI(session: session, apiVersion: apiVersion, defaultHeaders: defaultHeaders, group: group)
    }
    
    public init(unixDomainSocketPath: String) {
        let session = APISession(unixDomainSocketPath: unixDomainSocketPath, group: group)
        system = SystemAPI(
            session: session,
            apiVersion: apiVersion,
            defaultHeaders: defaultHeaders,
            group: group
        )
        containers = ContainersAPI(session: session, apiVersion: apiVersion, defaultHeaders: defaultHeaders, group: group)
    }
    
    public static func fromEnvironment() throws -> DockerClient {
        let env = ProcessInfo.processInfo.environment
        if let _ = env[Env.tlsVerifyVariable], let hostURL = env[Env.hostVariable], let certPath = env[Env.certPathVariable] {
            
            let clientCert = "\(certPath)/\(Env.clientCert)"
            let clientKey = "\(certPath)/\(Env.clientKey)"
            let caCert = "\(certPath)/\(Env.caCert)"

            guard let url = URL(string: hostURL), let host = url.host, let port = url.port else {
                throw DockerError.invalidHostURL(url: hostURL)
            }
            guard FileManager.default.fileExists(atPath: clientCert) else {
                throw DockerError.clientCertificateMissing(path: clientCert)
            }
            guard FileManager.default.fileExists(atPath: clientKey) else {
                throw DockerError.clientKeyMissing(path: clientKey)
            }
            guard FileManager.default.fileExists(atPath: caCert) else {
                throw DockerError.caCertificateMissing(path: caCert)
            }
            
            return try DockerClient(host: host, port: port, clientCert: clientCert, clientKey: clientKey, caCert: caCert)
            
        } else if FileManager.default.fileExists(atPath: Env.socketPath) {
            return DockerClient(unixDomainSocketPath: Env.socketPath)
        }
        
        throw DockerError.invalidEnvironment()
    }
    
    public func shutdown() throws -> Void {
        try group.syncShutdownGracefully()
    }
}
