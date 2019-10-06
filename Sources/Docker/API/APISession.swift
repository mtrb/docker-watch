//
//  APISession.swift
//  DockerWatch
//
//  Created by Matthias Turber on 21.04.18.
//

import Foundation
import Dispatch
import NIO
import NIOOpenSSL
import NIOHTTP1
import RxSwift


public class APISession {

    private let host: String?
    private let port: Int?
    private let sslConfig: TLSConfiguration?

    private let unixDomainSocketPath: String?

    private let group: MultiThreadedEventLoopGroup

    // throws NIOOpenSSLError.failedToLoadCertificate
    init(host: String, port: Int, clientCert: String, clientKey: String, rootCert: String,
         group: MultiThreadedEventLoopGroup) throws {
        self.host = host
        self.port = port
        self.unixDomainSocketPath = nil
        let serverCertificate = try OpenSSLCertificate(file: rootCert, format: .pem)
        self.sslConfig = TLSConfiguration.forClient(
            certificateVerification: .fullVerification,
            trustRoots: .certificates([serverCertificate]),
            certificateChain: [.file(clientCert)],
            privateKey: .file(clientKey)
        )
        self.group = group
    }

    init(unixDomainSocketPath: String, group: MultiThreadedEventLoopGroup) {
        self.host = nil
        self.port = nil
        self.sslConfig = nil
        self.unixDomainSocketPath = unixDomainSocketPath
        self.group = group
    }

    private func connect(with handler: ChannelHandler) throws -> Channel {
        let channel: Channel

        if let socketPath = unixDomainSocketPath {
            channel = try ClientBootstrap(group: group)
            .channelInitializer { channel in
                channel.pipeline.addHTTPClientHandlers().then {
                    channel.pipeline.add(handler: handler)
                }
            }
            .connect(unixDomainSocketPath: socketPath)
            .wait()
        } else {
            let sslHandler = try OpenSSLClientHandler(context: SSLContext(configuration: sslConfig!))
            channel = try ClientBootstrap(group: group)
            .channelInitializer { channel in
                channel.pipeline.add(handler: sslHandler).then {
                    channel.pipeline.addHTTPClientHandlers().then {
                        channel.pipeline.add(handler: handler)
                    }
                }
            }
            .connect(host: host!, port: port!)
            .wait()
        }

        return channel
    }

    private func addQuery(_ params: [String : String], to uri: String) -> String {
        guard params.count > 0 else {
            return uri
        }

        var query = "?"

        for (key, value) in params {
            query += "\(key)=\(value)"
            if params.index(after: params.index(forKey: key)!) < params.endIndex {
                query += "&"
            }
        }

        return "\(uri)\(query)"
    }

    func get(uri: String, params: [String: String], headers: [String: String]) throws -> APIResponse {
        let semaphore = DispatchSemaphore(value: 0)
        var requestHead = HTTPRequestHead(version: HTTPVersion(major: 1, minor: 1),
                                          method: .GET,
                                          uri: addQuery(params, to: uri))
        var responseError: Error?
        var responseHead: HTTPResponseHead?
        var responseBody: String?

        let responseHandler = APIResponseHandler { head, body, error in
            responseHead = head
            responseBody = body
            responseError = error
            semaphore.signal()
        }

        let channel = try self.connect(with: responseHandler)

        defer {
            do {
                try channel.close().wait()
            } catch ChannelError.alreadyClosed {
                /* we're happy with this one */
            } catch {
                fatalError(String(describing: error))
            }
        }

        requestHead.headers.add(name: "HOST", value: host ?? "localhost")
        for (name, value) in headers {
            requestHead.headers.replaceOrAdd(name: name, value: value)
        }
        requestHead.headers.add(name: "Connection", value: "close")
        channel.write(NIOAny(HTTPClientRequestPart.head(requestHead)), promise: nil)
        try channel.writeAndFlush(NIOAny(HTTPClientRequestPart.end(nil))).wait()

        semaphore.wait()

        guard responseError == nil else {
            throw responseError!
        }

        guard responseHead != nil else {
            throw DockerError.libraryInternal(message: "No HTTP Head received")
        }

        guard responseBody != nil else {
            throw DockerError.libraryInternal(message: "No HTTP Body received")
        }

        return APIResponse(head: responseHead!, body: responseBody!)
    }

    func get(uri: String, params: [String: String], headers: [String: String]) throws -> APIStream {
        let semaphore = DispatchSemaphore(value: 0)
        var requestHead = HTTPRequestHead(version: HTTPVersion(major: 1, minor: 1),
                                          method: .GET,
                                          uri: addQuery(params, to: uri))
        var responseError: Error?
        var responseHead: HTTPResponseHead?
        var responseObservable: Observable<String>?

        let streamHandler = APIStreamHandler { head, observable, error in
            responseHead = head
            responseObservable = observable
            responseError = error
            semaphore.signal()
        }

        let channel = try self.connect(with: streamHandler)

        requestHead.headers.add(name: "HOST", value: host ?? "localhost")
        for (name, value) in headers {
            requestHead.headers.replaceOrAdd(name: name, value: value)
        }
        requestHead.headers.add(name: "Connection", value: "close")
        channel.write(NIOAny(HTTPClientRequestPart.head(requestHead)), promise: nil)
        try channel.writeAndFlush(NIOAny(HTTPClientRequestPart.end(nil))).wait()

        semaphore.wait()

        guard responseError == nil else {
            throw responseError!
        }

        guard responseHead != nil else {
            throw DockerError.libraryInternal(message: "No HTTP head received")
        }

        guard responseObservable != nil else {
            throw DockerError.libraryInternal(message: "No HTTP body received")
        }

        return APIStream(head: responseHead!, observable: responseObservable!, channel: channel)
    }
}
