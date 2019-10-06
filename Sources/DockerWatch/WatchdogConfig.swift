//
//  WatchdogConfig.swift
//  docker-watch
//
//  Created by Matthias Turber on 11.05.18.
//

import Foundation
import Yaml


public enum WatchdogConfigError: Error {
    case configDoesNotExist(path: String)
    case configNotReadable(path: String)
    case configParsingError(message: String)
}


/// A watchdog configuration
public struct WatchdogConfig {
    
    private enum YAMLKey {
        static let containers:Yaml = "containers"
        static let networks:Yaml = "networks"
        static let display: Yaml = "display"
        static let removePrefix: Yaml = "remove_prefix"
        static let prefixEnd: Yaml = "prefix_end"
        static let emojis: Yaml = "emojis"
        static let colors: Yaml = "colors"
        static let filter: Yaml = "filter"
    }
    
    /// A list with names of containers to watch
    public var containers: [String]
    /// A list with names of networks to watch
    public var networks: [String]
    /// Whether to display the name prefix. (e.g. 'my_container'. prefix is 'my_')
    public var removePrefix: Bool
    /// The character indicating the end of the prefix
    public var prefixEnd: Character
    /// Whether to display emojis
    public var emojis: Bool
    /// Whether to use colored messages
    public var colors: Bool
    /// Filter logs containing a string from this list
    public var filter: [String]
    
    public static func load(from yaml: String) throws -> WatchdogConfig {
        var containers = [String]()
        var networks = [String]()
        var removePrefix = true
        var prefixEnd: Character = "_"
        var emojis = false
        var colors = false
        var filter = [String]()
        
        let yml = try Yaml.load(yaml)
        
        if let containersCfg = yml[YAMLKey.containers].array {
            for config in containersCfg {
                guard let container = config.string else {
                    throw WatchdogConfigError.configParsingError(message: "Container name is not a string")
                }
                containers.append(container)
            }
        }
        
        if let networksCfg = yml[YAMLKey.networks].array {
            for config in networksCfg {
                guard let network = config.string else {
                    throw WatchdogConfigError.configParsingError(message: "Network name is not a string")
                }
                networks.append(network)
            }
        }
        
        if let displayCfg = yml[YAMLKey.display].dictionary {
            if let removePrefixOpt = displayCfg[YAMLKey.removePrefix] {
                guard let opt = removePrefixOpt.bool else {
                    throw WatchdogConfigError.configParsingError(message: "remove_prefix is not a boolean")
                }
                removePrefix = opt
            }
            if let prefixEndOpt = displayCfg[YAMLKey.prefixEnd] {
                guard var opt = prefixEndOpt.string, opt.count == 1 else {
                    throw WatchdogConfigError.configParsingError(message: "prefix_end is not a single character")
                }
                prefixEnd = opt.removeFirst()
            }
            if let emojisOpt = displayCfg[YAMLKey.emojis] {
                guard let opt = emojisOpt.bool else {
                    throw WatchdogConfigError.configParsingError(message: "emojis is not a boolean")
                }
                emojis = opt
            }
            if let colorsOpt = displayCfg[YAMLKey.colors] {
                guard let opt = colorsOpt.bool else {
                    throw WatchdogConfigError.configParsingError(message: "color is not a boolean")
                }
                colors = opt
            }
        }
        
        if let filterCfg = yml[YAMLKey.filter].array {
            for value in filterCfg {
                guard let item = value.string else {
                    throw WatchdogConfigError.configParsingError(message: "filter item is not a string")
                }
                filter.append(item)
            }
        }
        
        return WatchdogConfig(containers: containers,
                              networks: networks,
                              removePrefix: removePrefix,
                              prefixEnd: prefixEnd,
                              emojis: emojis,
                              colors: colors,
                              filter: filter
        )
    }
    
    public static func load(from url: URL) throws -> WatchdogConfig {
        guard FileManager.default.fileExists(atPath: url.path) else {
            throw WatchdogConfigError.configDoesNotExist(path: url.path)
        }
        guard FileManager.default.isReadableFile(atPath: url.path) else {
            throw WatchdogConfigError.configNotReadable(path: url.path)
        }
        return try load(from: String(contentsOf: url, encoding: .utf8))
    }
}
