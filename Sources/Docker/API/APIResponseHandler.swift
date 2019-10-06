//
//  APIResponseHandler.swift
//  Docker
//
//  Created by Matthias Turber on 01.05.18.
//

import Dispatch
import NIO
import NIOHTTP1
import RxSwift


internal class APIResponseHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPClientResponsePart
    private var receivedParts: [HTTPClientResponsePart] = []
    private var head: HTTPResponseHead?
    private var body = ""
    private var allDoneBlock: DispatchWorkItem! = nil
    private var error: Error?

    public init(completion: @escaping (_ head: HTTPResponseHead?, _ body: String, _ error: Error?) -> Void) {
        self.allDoneBlock = DispatchWorkItem { [unowned self] () -> Void in
            completion(self.head, self.body, self.error)
        }
    }

    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        let responsePart = self.unwrapInboundIn(data)
        self.receivedParts.append(responsePart)

        switch responsePart {
        case .head(let head):
            self.head = head
        case .body(var buffer):
            self.body.append(buffer.readString(length: buffer.readableBytes) ?? "")
        case .end(nil):
            self.allDoneBlock.perform()
        default:
            ctx.close(promise: nil)
            fatalError("\(self).\(#function):\(#line) Received invalid HTTP response part")
        }
    }

    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        self.error = error
        self.allDoneBlock.perform()
        ctx.fireErrorCaught(error)
    }
}

internal class APIStreamHandler: ChannelInboundHandler {
    typealias InboundIn = HTTPClientResponsePart
    private var head: HTTPResponseHead?
    private var allDoneBlock: DispatchWorkItem! = nil
    private var error: Error?
    private var subject = PublishSubject<String>()

    public init(completion: @escaping (_ head: HTTPResponseHead?, _ observable: Observable<String>, _ error: Error?) -> Void) {
        self.allDoneBlock = DispatchWorkItem { [unowned self] () -> Void in
            completion(self.head, self.subject, self.error)
        }
    }

    public func channelRead(ctx: ChannelHandlerContext, data: NIOAny) {
        switch self.unwrapInboundIn(data) {
        case .head(let head):
            self.head = head
            allDoneBlock.perform()

        case .body(var bodyBuffer):
            guard let bodyPart = bodyBuffer.readString(length: bodyBuffer.readableBytes) else {
                subject.onError(DockerError.libraryInternal(
                    message: "\(self).\(#function):\(#line) buffer not Utf8 string convertible")
                )
                return
            }
            subject.onNext(bodyPart)

        case .end(nil):
            subject.onCompleted()
            allDoneBlock.perform()

        default:
            subject.onCompleted()
            ctx.close(promise: nil)
            fatalError("\(self).\(#function):\(#line): Received invalid HTTP response part")
        }
    }

    public func channelActive(ctx: ChannelHandlerContext) {
        ctx.fireChannelActive()
    }

    public func channelInactive(ctx: ChannelHandlerContext) {
        subject.onCompleted()
        ctx.fireChannelInactive()
    }

    public func errorCaught(ctx: ChannelHandlerContext, error: Error) {
        self.error = error
        self.allDoneBlock.perform()
        ctx.fireErrorCaught(error)
    }
}
