// swift-tools-version:4.0

import PackageDescription

let package = Package(
    name: "DockerWatch",
    products: [
        .executable(name: "docker-watch", targets: ["docker-watch"]),
        .library(name: "Docker", targets: ["Docker"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.9.5"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "1.3.1"),
        .package(url: "https://github.com/Hearst-DD/ObjectMapper.git", from: "3.3.0"),
        .package(url: "https://github.com/ReactiveX/RxSwift.git", from: "5.0.1"),
        .package(url: "https://github.com/IBM-Swift/BlueSignals.git", from: "1.0.1"),
        .package(url: "https://github.com/behrang/YamlSwift.git", from: "3.4.3")
    ],
    targets: [
        .target(
            name: "Docker",
            dependencies: ["NIO", "NIOOpenSSL", "NIOHTTP1", "ObjectMapper", "RxSwift"]
        ),
        .target(
            name: "ANSIColors",
            dependencies: []
        ),
        .target(
            name: "docker-watch",
            dependencies: ["Docker", "Signals", "Yaml", "ANSIColors"],
            path: "Sources/DockerWatch"
        ),
    ]
)
