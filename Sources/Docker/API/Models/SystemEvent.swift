//
//  SystemEvent.swift
//  Docker
//
//  Created by Matthias Turber on 03.05.18.
//

import ObjectMapper
import Foundation


/// The type of object emitting a event
public enum EventType: String {
    /// Event emitted by Container
    case container = "container"
    /// Event emitted by Image
    case image = "image"
    /// Event emitted by Volume
    case volume = "volume"
    /// Event emitted by Network
    case network = "network"
    /// Event emitted by Daemon
    case daemon = "daemon"
    /// Event emitted by Plugin
    case plugin = "plugin"
    /// Event emitted by Node
    case node = "node"
    /// Event emitted by Service
    case service = "service"
    /// Event emitted by Secret
    case secret = "secret"
    /// Event emitted by Config
    case config = "config"
}

/// A type of an event
public enum EventAction: String {
    /// Reported by Containers
    case attach = "attach"
    /// Reported by Containers
    case commit = "commit"
    /// Reported by Containers
    case copy = "copy"
    /// Reported by Containers, Volumes, Networks, Services, Nodes, Secrets and Configs
    case create = "create"
    /// Reported by Containers, Volumes, Networks
    case destroy = "destroy"
    /// Reported by Containers
    case detach = "detach"
    /// Reported by Containers
    case die = "die"
    /// Reported by Containers
    case execCreate = "exec_create"
    /// Reported by Containers
    case execDetach = "exec_detach"
    /// Reported by Containers
    case execStart = "exec_start"
    /// Reported by Containers
    case execDie = "exec_die"
    /// Reported by Containers
    case export = "export"
    /// Reported by Containers
    case health_status = "health_status"
    /// Reported by Containers
    case kill = "kill"
    /// Reported by Containers
    case oom = "oom"
    /// Reported by Containers
    case pause = "pause"
    /// Reported by Containers
    case rename = "rename"
    /// Reported by Containers
    case resize = "resize"
    /// Reported by Containers
    case restart = "restart"
    /// Reported by Containers
    case start = "start"
    /// Reported by Containers
    case stop = "stop"
    /// Reported by Containers
    case top = "top"
    /// Reported by Containers
    case unpause = "unpause"
    /// Reported by Containers, Networks, Services, Nodes, Secrets and Configs
    case update = "update"
    /// Reported by Images
    case delete = "delete"
    /// Reported by Images
    case import_ = "import"
    /// Reported by Images
    case load = "load"
    /// Reported by Images
    case pull = "pull"
    /// Reported by Images
    case push = "push"
    /// Reported by Images
    case save = "save"
    /// Reported by Images
    case tag = "tag"
    /// Reported by Images
    case untag = "untag"
    /// Reported by Volumes
    case mount = "mount"
    /// Reported by Volumes
    case unmount = "unmount"
    /// Reported by Netwoks
    case connect = "connect"
    /// Reported by Netwoks
    case disconnect = "disconnect"
    /// Reported by Netwoks, Services, Nodes, Secrets and Configs
    case remove = "remove"
    /// Reported by Daemon
    case reload = "reload"
}

/// An actor who emitted an event
public struct EventActor: ImmutableMappable {

    private enum MapKey {
        static let id = "ID"
        static let attributes = "Attributes"
    }

    /// The ID of the object emitting the event
    public let id: String
    /// Various key/value attributes of the object, depending on its type
    public let attributes: [String : Any]

    public init(map: Map) throws {
        id = try map.value(MapKey.id)
        attributes = try map.value(MapKey.attributes)
    }

    public func mapping(map: Map) {
        id >>> map[MapKey.id]
        attributes >>> map[MapKey.attributes]
    }
}

/// A Docker event
public struct SystemEvent: ImmutableMappable {

    private enum MapKey {
        static let type = "Type"
        static let action = "Action"
        static let actor = "Actor"
        static let time = "time"
        static let timeNano = "timeNano"
    }

    /// The type of object emitting the event
    public let type: EventType
    /// The type of event
    public let action: EventAction
    /// An optional command if the action is an docker exec action
    public private(set) var command: String?
    /// The object emitting the event
    public let actor: EventActor
    /// Timestamp of event
    public let time: Int
    /// Timestamp of event with nanosecond accuracy
    public let timeNano: Int64

    public init(map: Map) throws {
        type = try map.value(MapKey.type)
        // split the action string in action and command. Needed for exec_create and exec_start.
        let actionValue: String = try map.value(MapKey.action)
        var actionParts = actionValue.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: true)
        if actionParts.count == 2 {
            actionParts[1].removeFirst()
            action = EventAction(rawValue: String(actionParts[0]))!
            command = String(actionParts[1])
        } else {
            action = EventAction(rawValue: actionValue)!
        }
        actor = try map.value(MapKey.actor)
        time = try map.value(MapKey.time)
        timeNano = try map.value(MapKey.timeNano, using: Int64Transform())
    }

    public func mapping(map: Map) {
        type >>> map[MapKey.type]
        // rebuild the original action string
        if command != nil {
            let actionValue = "\(action): \(command!)"
            actionValue >>> map[MapKey.action]
        } else {
            action >>> map[MapKey.action]
        }
        actor >>> map[MapKey.actor]
        time >>> map[MapKey.time]
        timeNano >>> (map[MapKey.timeNano], Int64Transform())
    }
}
