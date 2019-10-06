//
//  main.swift
//  DockerWatch
//
//  Created by Matthias Turber on 05.04.18.
//  Copyright © 2018 Matthias Turber. All rights reserved.
//

import Foundation
import Dispatch
import Docker
import Signals
import RxSwift
import ANSIColors


let semaphore = DispatchSemaphore(value: 0)
let configFile = "docker-watch.yml"

Signals.trap(signals: [.int, .quit, .kill]) { signal in
    print("Quit Docker Watch")
    semaphore.signal()
}

do {
    
    let dockerClient = try DockerClient.fromEnvironment()
    let config = try WatchdogConfig.load(
        from: URL(fileURLWithPath: FileManager.default.currentDirectoryPath).appendingPathComponent(configFile)
    )
    let watchdog = Watchdog(
        client: dockerClient,
        config: config
    )
    let disposeBag = DisposeBag()
    
    guard try dockerClient.system.ping() == true else {
        print("Can not ping the Docker daemon")
        exit(1)
    }
    
    let version = try dockerClient.system.version()
    
    let welcomeMessage =
                 """
                 [-----------------------------------------------------------------]
                 
                 
                                      ****  Docker Watch  ****
                 
                 
                                   Docker Version: \(version.version)
                                      API Version: \(version.apiVersion)
                                  Min API Version: \(version.minAPIVersion)
                                               OS: \(version.os)
                                     Architecture: \(version.arch)
                                   Kernel Version: \(version.kernelVersion)
                 
                 
                 [-----------------------------------------------------------------]
                 """
    if config.colors == true {
        print(welcomeMessage.coloredANSIString(.yellow))
    } else {
        print(welcomeMessage)
    }
    
    #if os(Linux)
    /*
     This fixes the following bug (no idea why):
     
    swift: /home/buildnode/jenkins/workspace/oss-swift-4.1-package-linux-ubuntu-16_04/swift/lib/IRGen/IRGenSIL.cpp:2145: void (anonymous namespace)::IRGenSILFunction::visitFullApplySite(swift::FullApplySite): Assertion `origConv.getNumSILArguments() == args.size()' failed.
    /usr/bin/swift[0x3f24d54]
    /usr/bin/swift[0x3f25096]
    /lib/x86_64-linux-gnu/libpthread.so.0(+0x11390)[0x7fdd42840390]
    /lib/x86_64-linux-gnu/libc.so.6(gsignal+0x38)[0x7fdd40f7f428]
    /lib/x86_64-linux-gnu/libc.so.6(abort+0x16a)[0x7fdd40f8102a]
    /lib/x86_64-linux-gnu/libc.so.6(+0x2dbd7)[0x7fdd40f77bd7]
    /lib/x86_64-linux-gnu/libc.so.6(+0x2dc82)[0x7fdd40f77c82]
    /usr/bin/swift[0x5f20e9]
    /usr/bin/swift[0x5d6202]
    /usr/bin/swift[0x5d3cfb]
    /usr/bin/swift[0x4e5ae5]
    /usr/bin/swift[0x5ad73f]
    /usr/bin/swift[0x5adfb7]
    /usr/bin/swift[0x4c36c7]
    /usr/bin/swift[0x4beecc]
    /usr/bin/swift[0x4778c4]
    /lib/x86_64-linux-gnu/libc.so.6(__libc_start_main+0xf0)[0x7fdd40f6a830]
    /usr/bin/swift[0x475179]
    ...
    1.    While emitting IR SIL function "@main".
    <unknown>:0: error: unable to execute command: Aborted
    <unknown>:0: error: compile command failed due to signal 6
     */
    watchdog.eventStream = try dockerClient.system.events()
    watchdog.eventStream?.asObservable().subscribe().disposed(by: disposeBag)
    #endif
    
    try watchdog.watch().subscribe(
        onNext: { event in
            print(event.message)
            
        },
        onError: { error in
            if let watchdogError = error as? WatchdogError {
                print(watchdogError.message)
            } else {
                let message = "Watchdog Error:\n\(error)"
                print(config.colors == true ? message.coloredANSIString(.red) : message)
            }
        },
        onCompleted: { /*print("watchdog subscription onCompleted")*/ },
        onDisposed: { /*print("watchdog subscription onDisposed")*/ }
    ).disposed(by: disposeBag)
    
    semaphore.wait()
    
    try watchdog.shutdown()
    try dockerClient.shutdown()
    
} catch {
    print("Fatal error: \(error)")
}

