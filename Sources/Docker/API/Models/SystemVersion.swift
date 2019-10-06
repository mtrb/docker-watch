//
//  SystemVersion.swift
//  Docker
//
//  Created by Matthias Turber on 30.04.18.
//

import ObjectMapper
import Foundation


/// The version of Docker that is running and various information about the system that Docker is running on
public struct SystemVersion: ImmutableMappable {

    private enum MapKey {
        static let version = "Version"
        static let kernelVersion = "KernelVersion"
        static let goVersion = "GoVersion"
        static let gitCommit = "GitCommit"
        static let arch = "Arch"
        static let apiVersion = "ApiVersion"
        static let minAPIVersion = "MinAPIVersion"
        static let buildTime = "BuildTime"
        static let os = "Os"
    }

    /// The Docker version
    public let version: String
    /// The operating system's kernel version
    public let kernelVersion: String
    /// The GO version the docker Daemon was implemented
    public let goVersion: String
    /// The Git repository commit
    public let gitCommit: String
    /// The system's architecture
    public let arch: String
    /// The Docker API version
    public let apiVersion: String
    /// The minimal Docker API version provided by the Daemon
    public let minAPIVersion: String
    /// The build time of the Docker Daemon
    public let buildTime: String
    /// The operating system the Docker Daemon is running
    public let os: String

    public init(map: Map) throws {
        version = try map.value(MapKey.version)
        kernelVersion = try map.value(MapKey.kernelVersion)
        goVersion = try map.value(MapKey.goVersion)
        gitCommit = try map.value(MapKey.gitCommit)
        arch = try map.value(MapKey.arch)
        apiVersion = try map.value(MapKey.apiVersion)
        minAPIVersion = try map.value(MapKey.minAPIVersion)
        buildTime = try map.value(MapKey.buildTime)
        os = try map.value(MapKey.os)
    }

    public func mapping(map: Map) {
        version >>> map[MapKey.version]
        kernelVersion >>> map[MapKey.kernelVersion]
        goVersion >>> map[MapKey.goVersion]
        gitCommit >>> map[MapKey.gitCommit]
        arch >>> map[MapKey.arch]
        apiVersion >>> map[MapKey.apiVersion]
        minAPIVersion >>> map[MapKey.minAPIVersion]
        buildTime >>> map[MapKey.buildTime]
        os >>> map[MapKey.os]
    }
}
