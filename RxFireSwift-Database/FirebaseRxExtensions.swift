//
//  FirebaseRxExtensions.swift
//  RxFireSwift-Database
//
//  Created by Morten Bek Ditlevsen on 30/09/2018.
//  Copyright © 2018 Ka-ching. All rights reserved.
//

import FirebaseDatabase
import FireSwift_Database
import Foundation
import RxSwift

extension DecodeResult {
    // A small convenience to re-wrap a `DecodeResult` as a `SingleEvent`
    var asSingleEvent: SingleEvent<Value> {
        switch self {
        case .success(let v):
            return .success(v)
        case .failure(let e):
            return .error(e)
        }
    }
}

/**
 Convenience extensions for `DatabaseQuery` (and thus also `DatabaseReference`)
 */
extension Reactive where Base: DatabaseQuery {
    /**
     Creates a `Single` representing the asynchronous fetch of a value from the Realtime Database

     - Parameter type: The `DataEventType` to listen for.

     - Parameter decoder: An optional custom configured StructureDecoder instance to use for decoding.

     - Returns: A `Single` of the requested generic type.
     */
    public func observeSingleEvent<T>(of type: DataEventType,
                                      using decoder: StructureDecoder = .init()) -> Single<T>
        where T: Decodable {
        return Single.create { single in
            self.base.observeSingleEvent(of: type, using: decoder, with: { (result: DecodeResult<T>) in
                single(result.asSingleEvent)
            })
            return Disposables.create()
        }
    }

    /**
     Creates an `Observable` representing the stream of changes to a value from the Realtime Database

     - Parameter type: The `DataEventType` to listen for.

     - Parameter decoder: An optional custom configured StructureDecoder instance to use for decoding.

     - Returns: An `Observable` of the requested generic type wrapped in a `DecodeResult`.
     */
    public func observe<T>(eventType: DataEventType,
                           using decoder: StructureDecoder = .init()) -> Observable<DecodeResult<T>>
        where T: Decodable {
        return Observable.create { observer in
            let handle = self.base.observe(eventType: eventType,
                                           using: decoder,
                                           with: { (result: DecodeResult<T>) in
                                            observer.onNext(result)
            })
            return Disposables.create {
                self.base.removeObserver(withHandle: handle)
            }
        }
    }
}

/**
 Convenience extensions for `Database`
 */
extension Reactive where Base: Database {

    /**
     Creates a `Single` representing the asynchronous fetch of a value from the Realtime Database

     - Parameter path: The path to the value in the Realtime Database hierarchy.

     - Parameter decoder: An optional custom configured StructureDecoder instance to use for decoding.

     - Returns: A `Single` of the generic type matching that of the supplied `path` parameter.
     */
    public func observeSingleEvent<T>(at path: Path<T>,
                               using decoder: StructureDecoder = .init()) -> Single<T>
        where T: Decodable {
        return Single.create { single in
            self.base.observeSingleEvent(at: path,
                                         using: decoder,
                                         with: { (result: DecodeResult<T>) in
                single(result.asSingleEvent)
            })
            return Disposables.create()
        }
    }

    /**
     Creates an `Observable` representing the stream of changes to a value from the Realtime Database

     - Parameter path: The path to the value in the Realtime Database hierarchy.

     - Parameter decoder: An optional custom configured StructureDecoder instance to use for decoding.

     - Returns: An `Observable` of the generic type matching that of the supplied `path` parameter, wrapped in a `DecodeResult`.
     */
    public func observe<T>(at path: Path<T>,
                    using decoder: StructureDecoder = .init()) -> Observable<DecodeResult<T>>
        where T: Decodable {
        return Observable.create { observer in
            let handle = self.base.observe(at: path,
                                           using: decoder,
                                           with: { (result: DecodeResult<T>) in
                observer.onNext(result)
            })
            return Disposables.create {
                self.base[path].removeObserver(withHandle: handle)
            }
        }
    }

    /**
     Creates a `Single` representing the asynchronous fetch of a value from the Realtime Database

     - Parameter eventType: The `CollectionEventType` to listen for.

     - Parameter path: The path to a collection of values in the Realtime Database hierarchy.

     - Parameter decoder: An optional custom configured StructureDecoder instance to use for decoding.

     - Returns: A `Single` of the generic type matching that of the supplied collection `path` parameter.
     */
    public func observeSingleEvent<T>(of eventType: CollectionEventType,
                               at path: Path<T>.Collection,
                               using decoder: StructureDecoder = .init()) -> Single<T>
        where T: Decodable {
        return Single.create { single in
            self.base.observeSingleEvent(of: eventType,
                                         at: path,
                                         using: decoder,
                                         with: { (result: DecodeResult<T>) in
                single(result.asSingleEvent)
            })
            return Disposables.create()
        }
    }

    /**
     Creates an `Observable` representing the stream of changes to a value from the Realtime Database

     - Parameter eventType: The `CollectionEventType` to listen for.

     - Parameter path: The path to a collection of values in the Realtime Database hierarchy.

     - Parameter decoder: An optional custom configured StructureDecoder instance to use for decoding.

     - Returns: An `Observable` of the generic type matching that of the supplied collection `path` parameter, wrapped in a `DecodeResult`.
     */
    public func observe<T>(eventType: CollectionEventType,
                    at path: Path<T>.Collection,
                    using decoder: StructureDecoder = .init()) -> Observable<DecodeResult<T>>
        where T: Decodable {
        return Observable.create { observer in
            let handle = self.base.observe(eventType: eventType,
                                           at: path,
                                           using: decoder,
                                           with: { (result: DecodeResult<T>) in
                observer.onNext(result)
            })
            return Disposables.create {
                self.base[path].removeObserver(withHandle: handle)
            }
        }
    }
}
