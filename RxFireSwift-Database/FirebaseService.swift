//
//  FirebaseService.swift
//  RxFireSwift-Database
//
//  Created by Morten Bek Ditlevsen on 30/09/2018.
//  Copyright © 2018 Ka-ching. All rights reserved.
//

import FirebaseDatabase
import FireSwift_Database
import Foundation
import Result
import RxSwift

// A small wrapper so that we prevent the user from calling collection observation with .value
public enum CollectionEventType {
    case childAdded, childChanged, childRemoved
    var firebaseEventType: DataEventType {
        switch self {
        case .childAdded:
            return .childAdded
        case .childChanged:
            return .childChanged
        case .childRemoved:
            return .childRemoved
        }
    }
}

public class FirebaseService {
    private let rootRef: DatabaseReference
    public init(ref: DatabaseReference) {
        self.rootRef = ref.root
    }

    // MARK: Observing Paths
    public func observeSingleEvent<T>(at path: Path<T>) -> Single<T>
        where T: Decodable {
            return rootRef[path].rx.observeSingleEvent(of: .value)
    }

    public func observe<T>(at path: Path<T>) -> Observable<DecodeResult<T>>
        where T: Decodable {
            return rootRef[path].rx.observe(eventType: .value)
    }

    // MARK: Observing Collection Paths
    public func observeSingleEvent<T>(of type: CollectionEventType,
                               at path: Path<T>) -> Single<T>
        where T: Decodable {
            return rootRef[path].rx.observeSingleEvent(of: type.firebaseEventType)
    }

    public func observe<T>(eventType type: CollectionEventType,
                    at path: Path<T>.Collection) -> Observable<DecodeResult<T>>
        where T: Decodable {
            return rootRef[path].rx.observe(eventType: type.firebaseEventType)
    }

    // MARK: Adding and Setting
    public func setValue<T>(at path: Path<T>, value: T) throws where T: Encodable {
        try rootRef[path].setValue(value)
    }

    public func addValue<T>(at path: Path<T>.Collection, value: T) throws where T: Encodable {
        let childRef = rootRef[path].childByAutoId()
        try childRef.setValue(value)
    }
}

public protocol ResultProtocol {
    associatedtype WrappedType
    associatedtype ErrorType
    var value: WrappedType? { get }
    var error: ErrorType? { get }
}

extension Result: ResultProtocol {
    public typealias WrappedType = Value
    public typealias ErrorType = Error
}

extension Observable where Element: ResultProtocol, Element.ErrorType == DecodeError {

    public func ifPresent() -> Observable<Element.WrappedType?> {
        return self.filter { result in
            switch (result.error, result.value) {
            case (_, .some), (.some(.noValuePresent), _):
                // Actual values and 'missing values' are passed through
                // Other errors are filtered away
                return true
            default:
                return false
            }
            }
            .map { result in
                return result.value
        }
    }

    public func ifPresent(handlingErrors handler: @escaping (Element.ErrorType) -> Void) -> Observable<Element.WrappedType?> {
        return self
            .do(onNext: { result in
                guard let error = result.error else { return }
                // Don't log 'no value present' errors, they will be treated as proper values
                if case .noValuePresent = error { return }
                handler(error)
            })
            .ifPresent()
    }

    public func successes() -> Observable<Element.WrappedType> {
        return self.filter { $0.value != nil }.map { $0.value! }
    }

    public func successes(handlingErrors handler: @escaping (Element.ErrorType) -> Void) -> Observable<Element.WrappedType> {
        return self
            .do(onNext: { result in
                guard let error = result.error else { return }
                handler(error)
            })
            .successes()
    }
}
