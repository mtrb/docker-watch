//
//  APIResponse.swift
//  Docker
//
//  Created by Matthias Turber on 01.05.18.
//

import NIO
import NIOHTTP1
import RxSwift


public struct APIResponse {
    public var head: HTTPResponseHead
    public var body: String

    public func isOk() -> Bool {
        return self.head.status == .ok
    }
}


public class APIStream {
    internal var head: HTTPResponseHead
    internal var channel: Channel
    private var observable: Observable<String>
    private var subject = PublishSubject<String>()
    private var disposable: Disposable?
    private var buffer = ""

    init(head: HTTPResponseHead, observable: Observable<String>, channel: Channel) {
        self.head = head
        self.observable = observable
        self.channel = channel
    }

    func isOk() -> Bool {
        return self.head.status == .ok
    }

    public func close() throws {
        try channel.close().wait()
    }

    public func isActive() -> Bool {
        return channel.isActive
    }

    public func asObservable() -> Observable<String> {
        if disposable == nil {
            self.disposable = self.observable.subscribe(
                onNext: { body in
                    self.buffer.append(body)
                    while let index = self.buffer.index(of: "\n") {
                        let next = String(self.buffer[self.buffer.startIndex..<index])
                        self.subject.onNext(next)
                        self.buffer.removeSubrange(self.buffer.startIndex..<self.buffer.index(after: index))
                    }
                },
                onError: { error in
                    self.subject.onError(error)
                },
                onCompleted: {
                    self.subject.onCompleted()
                })
        }
        return subject
    }
}


public class APIEventStream {
    private var stream: APIStream
    private var subject = PublishSubject<SystemEvent>()
    private var disposeable: Disposable?

    public init(stream: APIStream) {
        self.stream = stream
    }

    public func asObservable() -> Observable<SystemEvent> {
        if disposeable == nil {
            self.disposeable = self.stream.asObservable().subscribe(
                onNext: { body in
                    do {
                        try self.subject.onNext(SystemEvent(JSONString: body))
                    } catch {
                        self.subject.onError(error)
                    }
            },
                onError: { error in
                    self.subject.onError(error)

            },
                onCompleted: {
                    self.subject.onCompleted()
            })
        }
        return subject
    }

    public func close() throws {
        disposeable?.dispose()
        subject.onCompleted()
        try stream.close()
    }
}
