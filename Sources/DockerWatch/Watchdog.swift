//
//  Watchdog.swift
//  docker-watch
//
//  Created by Matthias Turber on 11.05.18.
//

import Foundation
import Dispatch
import Docker
import RxSwift
import ANSIColors


public struct WatchdogError: Error {
    let message: String
}


public enum WatchdogEvent {
    case containerEvent(container: ContainerInspection?, event: SystemEvent, message: String)
    case containerLog(container: ContainerInspection?, message: String)
    
    public var message: String {
        switch self {
        case .containerEvent(_ , _, let message):
            return message
        case .containerLog(_, let message):
            return message
        }
    }
}


fileprivate class ContainerWatchItem {
    var container: ContainerInspection?
    var stream: ContainerLogStream?
    var subscription: Disposable?
    let displayName: String
    var displayColor: ANSIColor?
    
    init(container: ContainerInspection?, stream: ContainerLogStream?, subscription: Disposable?, displayName: String,
         displayColor: ANSIColor?) {
        self.container = container
        self.stream = stream
        self.subscription = subscription
        self.displayName = displayName
        self.displayColor = displayColor
    }
}


public class Watchdog {
    private var client: DockerClient
    private let config: WatchdogConfig
    public var eventStream: APIEventStream?
    private var eventSubscription: Disposable?
    private let subject = PublishSubject<WatchdogEvent>()
    private var watchedContainers = [String : ContainerWatchItem]()
    private let workerQueue = DispatchQueue(
        label: "de.dockerwatch.watchdog.workerqueue",
        attributes: .concurrent
    )
    private var maxNameLength = 0
    
    public init(client: DockerClient, config: WatchdogConfig) {
        self.client = client
        self.config = config
    }
    
    public func watch() throws -> Observable<WatchdogEvent> {
        for name in config.containers {
            watch(container: name)
        }
        
        var ansiColors = ANSIColor.allColors
        while ansiColors.count < watchedContainers.count {
            ansiColors += ANSIColor.allColors
        }
        
        for (_, item) in watchedContainers {
            if item.displayName.count > maxNameLength {
                maxNameLength = item.displayName.count
            }
            item.displayColor = ansiColors.removeFirst()
        }
        
        if self.eventStream == nil {
            self.eventStream = try self.client.system.events()
        }
        
        if self.eventSubscription == nil {
            self.eventSubscription = self.eventStream?.asObservable().subscribe(
                onNext: { event in
                    self.workerQueue.async {
                        switch event.type {
                        case .container:
                            self.onContainer(event: event)
                        default:
                            break
                        }
                    }
                },
                onError: { error in
                    self.workerQueue.async {
                        self.subject.onError(error)
                    }
                },
                onCompleted: { /*print("eventSubscription onCompleted")*/ },
                onDisposed: { /*print("eventSubscription onDisposed")*/  }
            )
        }
        
        return self.subject
    }
    
    public func shutdown() throws {
        try eventStream?.close()
        eventSubscription?.dispose()
        eventSubscription = nil
        eventStream = nil
        for (_, item) in watchedContainers {
            if item.stream?.isActive() == true {
                try item.stream?.close()
            }
            item.subscription?.dispose()
        }
        watchedContainers.removeAll()
        subject.onCompleted()
        maxNameLength = 0
    }
    
    private func watch(container name: String, displayColor: ANSIColor? = nil) {
        var displayName = name
        if config.removePrefix == true, var idx = name.index(of: "_") {
            idx = name.index(after: idx)
            displayName = String(name[idx...])
        }
        let container = try? client.containers.inspect(name)
        let stream = try? client.containers.logs(name)
        let subscription = stream?.asObservable().subscribe(
            onNext: { log in
                self.workerQueue.async {
                    self.on(container: name, log: log)
                }
            },
            onError: { error in
                self.workerQueue.async {
                    self.subject.onError(error)
                }
            },
            onCompleted: { /*print("\(displayName) onCompleted")*/ },
            onDisposed: { /*print("\(displayName) onDisposed")*/ }
        )
        watchedContainers[name] = ContainerWatchItem(container: container,
                                                     stream: stream,
                                                     subscription: subscription,
                                                     displayName: displayName,
                                                     displayColor: displayColor)
    }
    
    private func unwatch(container name: String) {
        if let item = watchedContainers[name], item.stream?.isActive() == true {
            self.workerQueue.async {
                do {
                    try item.stream?.close()
                } catch {
                    self.subject.onError(WatchdogError(
                        message: "\(self).\(#function):\(#line) \(error)")
                    )
                }
            }
        }
    }
    
    private func onContainer(event: SystemEvent) {
        var message = config.emojis ? "🐳  | " : "C | "
        guard let name = event.actor.attributes["name"] as? String else {
            self.subject.onError(WatchdogError(
                message: "\(self).\(#function):\(#line) event.actor.attributes[\"name\"] == nil")
            )
            return
        }
        guard let watchItem = self.watchedContainers[name] else {
            return
        }
        
        switch event.action {
        case .create:
            message += config.emojis ? "🛠  | " : "created   | "
        case .destroy:
            message += config.emojis ? "🗑  | " : "destroyed | "
        case .die:
            message += config.emojis ? "☠️  | " : "died      | "
        case .kill:
            message += config.emojis ? "🔪  | " : "killed    | "
        case .pause:
            message += config.emojis ? "💤  | " : "paused    | "
        case .restart:
            message += config.emojis ? "♻️  | " : "restarted | "
        case .start:
            message += config.emojis ? "🏁  | " : "started   | "
            unwatch(container: name)
            watch(container: name, displayColor: watchItem.displayColor)
        case .stop:
            message += config.emojis ? "✋  | " : "stopped   | "
        case .unpause:
            message += config.emojis ? "🤤  | " : "unpaused  | "
        default:
            return
        }
        
        var namePart = watchItem.displayName + String(repeating: " ", count: maxNameLength - watchItem.displayName.count) + "| "
        if let color = watchItem.displayColor {
            namePart = namePart.coloredANSIString(color)
        }
        message += namePart
        self.subject.onNext(WatchdogEvent.containerEvent(container: watchItem.container, event: event, message: message))
    }
    
    private func on(container: String, log: String) {
        guard let watchItem = self.watchedContainers[container] else {
            return
        }
        for item in self.config.filter {
            if log.contains(item) { return }
        }
        var message = config.emojis ? "🐳  | 💬  | " : "C | log       | "
        var namePart = "\(watchItem.displayName)" + String(repeating: " ", count: maxNameLength - watchItem.displayName.count) + "| "
        if let color = watchItem.displayColor {
            namePart = namePart.coloredANSIString(color)
        }
        message += namePart + log
        if message.hasSuffix("\n") {
            message.removeLast()
        }
        subject.onNext(WatchdogEvent.containerLog(container: watchItem.container, message: message))
    }
}
