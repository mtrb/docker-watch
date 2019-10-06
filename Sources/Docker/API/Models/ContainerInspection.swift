//
//  ContainerInspection.swift
//  Docker
//
//  Created by Matthias Turber on 08.05.18.
//

import Foundation
import ObjectMapper


/// A container status
public enum ContainerStatus: String {
    case created = "created"
    case running = "running"
    case paused = "paused"
    case restarting = "restarting"
    case removing = "removing"
    case exited = "exited"
    case dead = "dead"
}

/// A state of a container
public struct ContainerState: ImmutableMappable {

    private enum MapKey {
        static let status = "Status"
        static let running = "Running"
        static let paused = "Paused"
        static let restarting = "Restarting"
        static let oomKilled = "OOMKilled"
        static let dead = "Dead"
        static let pid = "Pid"
        static let exitCode = "ExitCode"
        static let error = "Error"
        static let startedAt = "StartedAt"
        static let finishedAt = "FinishedAt"
    }

    /// The status of the container
    let status: ContainerStatus
    /// Whether this container is running
    let running: Bool
    /// Whether this container is paused
    let paused: Bool
    /// Whether this container is restarting
    let restarting: Bool
    /// Whether this container has been killed because it ran out of memory
    let oomKilled: Bool
    /// Whether this container is dead
    let dead: Bool
    /// The process ID of this container
    let pid: Int
    /// The last exit code of this container
    let exitCode: Int
    /// A error message
    let error: String
    /// The time when this container was last started
    let startedAt: String
    /// The time when this conainer was last exited
    let finishedAt: String

    public init(map: Map) throws {
        status = try map.value(MapKey.status)
        running = try map.value(MapKey.running)
        paused = try map.value(MapKey.paused)
        restarting = try map.value(MapKey.restarting)
        oomKilled = try map.value(MapKey.oomKilled)
        dead = try map.value(MapKey.dead)
        pid = try map.value(MapKey.pid)
        exitCode = try map.value(MapKey.exitCode)
        error = try map.value(MapKey.error)
        startedAt = try map.value(MapKey.startedAt)
        finishedAt = try map.value(MapKey.finishedAt)
    }

    public func mapping(map: Map) {
        status >>> map[MapKey.status]
        running >>> map[MapKey.running]
        paused >>> map[MapKey.paused]
        restarting >>> map[MapKey.restarting]
        oomKilled >>> map[MapKey.oomKilled]
        dead >>> map[MapKey.dead]
        pid >>> map[MapKey.pid]
        exitCode >>> map[MapKey.exitCode]
        error >>> map[MapKey.error]
        startedAt >>> map[MapKey.startedAt]
        finishedAt >>> map[MapKey.finishedAt]
    }
}

/// A Container configuration that depends on the host we are running on
public struct MountPoint: ImmutableMappable {

    private enum MapKey {
        static let type = "Type"
        static let name = "Name"
        static let source = "Source"
        static let destination = "Destination"
        static let driver = "Driver"
        static let mode = "Mode"
        static let rw = "RW"
        static let propagation = "Propagation"
    }

    /// The mountpoint type
    public let type: String
    /// The name of the mountpoint
    public private(set) var name: String?
    /// The source path
    public let source: String
    /// The destination path
    public let destination: String
    /// The driver used
    public private(set) var driver: String?
    /// The mode used
    public let mode: String
    /// Whether the mount is read and writeable
    public let rw: Bool
    /// ??
    public let propagation: String

    public init(map: Map) throws {
        type = try map.value(MapKey.type)
        name = try? map.value(MapKey.name)
        source = try map.value(MapKey.source)
        destination = try map.value(MapKey.destination)
        driver = try? map.value(MapKey.driver)
        mode = try map.value(MapKey.mode)
        rw = try map.value(MapKey.rw)
        propagation = try map.value(MapKey.propagation)
    }

    public func mapping(map: Map) {
        type >>> map[MapKey.type]
        name >>> map[MapKey.name]
        source >>> map[MapKey.source]
        destination >>> map[MapKey.destination]
        driver >>> map[MapKey.driver]
        mode >>> map[MapKey.mode]
        rw >>> map[MapKey.rw]
        propagation >>> map[MapKey.propagation]
    }
}

/// A Docker container
public struct ContainerInspection: ImmutableMappable {

    private enum MapKey {
        static let id = "Id"
        static let created = "Created"
        static let path = "Path"
        static let args = "Args"
        static let state = "State"
        static let image = "Image"
        static let resolveConfigPath = "ResolvConfPath"
        static let hostnamePath = "HostnamePath"
        static let hostsPath = "HostsPath"
        static let logPath = "LogPath"
        static let node = "Node"
        static let name = "Name"
        static let restartCount = "RestartCount"
        static let driver = "Driver"
        static let mountLabel = "MountLabel"
        static let processLabel = "ProcessLabel"
        static let appArmorProfile = "AppArmorProfile"
        static let execIDs = "ExecIDs"
        static let hostConfig = "HostConfig"
        static let graphDriver = "GraphDriver"
        static let sizeRw = "SizeRw"
        static let sizeRootFs = "SizeRootFs"
        static let mounts = "Mounts"
        static let config = "Config"
        static let networkSettings = "NetworkSettings"
    }

    /// The ID of the container
    public let id: String
    /// The time the container was created
    public let created: String
    /// The path to the command being run
    public let path: String
    /// The arguments to the command being run
    public let args: [String]
    /// The state of the container
    public let state: ContainerState
    /// The containers image
    public let image: String
    /// ???
    public let resolveConfigPath: String
    /// ???
    public let hostnamePath: String
    /// ???
    public let hostsPath: String
    /// ???
    public let logPath: String
    /// ???
    public private(set) var node: [String : Any]?
    /// The name of the container
    public let name: String
    /// ???
    public let restartCount: Int
    /// ???
    public let driver: String
    /// ???
    public let mountLabel: String
    /// ???
    public let processLabel: String
    /// ???
    public let appArmorProfile: String
    /// ???
    public private(set) var execIDs: String?
    /// The container configuration that depends on the host the container is running on
    public let hostConfig: [String : Any] // TODO: implement a HostConfig
    /// Information about the container's graph driver
    public let graphDriver: [String : Any] // TODO: implement a GraphDriverData
    /// The size of files that have been created or changed by this container
    public private(set) var sizeRw: Int64?
    /// The total size of all the files in this container
    public private(set) var sizeRootFs: Int64?
    /// A list of mountpoints inside the container
    public let mounts: [MountPoint]
    /// Configuration for a container that is portable between hosts
    public let config: [String : Any] // TODO: implement a ContainerConfig
    /// Network settings
    public let networkSettings: [String : Any] // TODO: implement a NetworkSettings

    public init(map: Map) throws {
        id = try map.value(MapKey.id)
        created = try map.value(MapKey.created)
        path = try map.value(MapKey.path)
        args = try map.value(MapKey.args)
        state = try map.value(MapKey.state)
        image = try map.value(MapKey.image)
        resolveConfigPath = try map.value(MapKey.resolveConfigPath)
        hostnamePath = try map.value(MapKey.hostnamePath)
        hostsPath = try map.value(MapKey.hostsPath)
        logPath = try map.value(MapKey.logPath)
        node = try? map.value(MapKey.node)
        name = try map.value(MapKey.name)
        restartCount = try map.value(MapKey.restartCount)
        driver = try map.value(MapKey.driver)
        mountLabel = try map.value(MapKey.mountLabel)
        processLabel = try map.value(MapKey.processLabel)
        appArmorProfile = try map.value(MapKey.appArmorProfile)
        execIDs = try? map.value(MapKey.execIDs)
        hostConfig = try map.value(MapKey.hostConfig)
        graphDriver = try map.value(MapKey.graphDriver)
        sizeRw = try? map.value(MapKey.sizeRw, using: Int64Transform())
        sizeRootFs = try? map.value(MapKey.sizeRootFs, using: Int64Transform())
        mounts = try map.value(MapKey.mounts)
        config = try map.value(MapKey.config)
        networkSettings = try map.value(MapKey.networkSettings)
    }

    public func mapping(map: Map) {
        id >>> map[MapKey.id]
        created >>> map[MapKey.created]
        path >>> map[MapKey.path]
        args >>> map[MapKey.args]
        state >>> map[MapKey.state]
        image >>> map[MapKey.image]
        resolveConfigPath >>> map[MapKey.resolveConfigPath]
        hostnamePath >>> map[MapKey.hostnamePath]
        hostsPath >>> map[MapKey.hostsPath]
        logPath >>> map[MapKey.logPath]
        node >>> map[MapKey.node]
        name >>> map[MapKey.name]
        restartCount >>> map[MapKey.restartCount]
        driver >>> map[MapKey.driver]
        mountLabel >>> map[MapKey.mountLabel]
        processLabel >>> map[MapKey.processLabel]
        appArmorProfile >>> map[MapKey.appArmorProfile]
        execIDs >>> map[MapKey.execIDs]
        hostConfig >>> map[MapKey.hostConfig]
        graphDriver >>> map[MapKey.graphDriver]
        sizeRw >>> (map[MapKey.graphDriver], Int64Transform())
        sizeRootFs >>> (map[MapKey.sizeRootFs], Int64Transform())
        mounts >>> map[MapKey.mounts]
        config >>> map[MapKey.config]
        networkSettings >>> map[MapKey.networkSettings]
    }
}
