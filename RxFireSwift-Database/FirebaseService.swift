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

public class FirebaseService {
    public struct DecoderStrategies {
        var dataDecodingStrategy: StructureDecoder.DataDecodingStrategy
        var dateDecodingStrategy: StructureDecoder.DateDecodingStrategy
        var keyDecodingStrategy: StructureDecoder.KeyDecodingStrategy
        var nonConformingFloatDecodingStrategy: StructureDecoder.NonConformingFloatDecodingStrategy
    }

    public struct EncoderStrategies {
        var dataEncodingStrategy: StructureEncoder.DataEncodingStrategy
        var dateEncodingStrategy: StructureEncoder.DateEncodingStrategy
        var keyEncodingStrategy: StructureEncoder.KeyEncodingStrategy
        var nonConformingFloatEncodingStrategy: StructureEncoder.NonConformingFloatEncodingStrategy
    }

    public var decoderStrategies = DecoderStrategies(dataDecodingStrategy: .deferredToData,
                                                     dateDecodingStrategy: .deferredToDate,
                                                     keyDecodingStrategy: .useDefaultKeys,
                                                     nonConformingFloatDecodingStrategy: .throw)

    public var encoderStrategies = EncoderStrategies(dataEncodingStrategy: .deferredToData,
                                                     dateEncodingStrategy: .deferredToDate,
                                                     keyEncodingStrategy: .useDefaultKeys,
                                                     nonConformingFloatEncodingStrategy: .throw)

    private func createEncoder() -> StructureEncoder {
        let encoder = StructureEncoder()
        encoder.dataEncodingStrategy = encoderStrategies.dataEncodingStrategy
        encoder.dateEncodingStrategy = encoderStrategies.dateEncodingStrategy
        encoder.keyEncodingStrategy = encoderStrategies.keyEncodingStrategy
        encoder.nonConformingFloatEncodingStrategy = encoderStrategies.nonConformingFloatEncodingStrategy
        return encoder
    }

    private func createDecoder() -> StructureDecoder {
        let decoder = StructureDecoder()
        decoder.dataDecodingStrategy = decoderStrategies.dataDecodingStrategy
        decoder.dateDecodingStrategy = decoderStrategies.dateDecodingStrategy
        decoder.keyDecodingStrategy = decoderStrategies.keyDecodingStrategy
        decoder.nonConformingFloatDecodingStrategy = decoderStrategies.nonConformingFloatDecodingStrategy
        return decoder
    }

    private let database: Database

    public init(database: Database) {
        self.database = database
    }

    // MARK: Observing Paths
    public func observeSingleEvent<T>(at path: Path<T>) -> Single<T>
        where T: Decodable {
            return database.rx.observeSingleEvent(at: path, using: createDecoder())
    }

    public func observe<T>(at path: Path<T>) -> Observable<DecodeResult<T>>
        where T: Decodable {
            return database.rx.observe(at: path, using: createDecoder())
    }

    // MARK: Observing Collection Paths
    public func observeSingleEvent<T>(of type: CollectionEventType,
                               at path: Path<T>.Collection) -> Single<T>
        where T: Decodable {
            return database.rx.observeSingleEvent(of: type, at: path, using: createDecoder())
    }

    public func observe<T>(eventType type: CollectionEventType,
                    at path: Path<T>.Collection) -> Observable<DecodeResult<T>>
        where T: Decodable {
            return database.rx.observe(eventType: type, at: path, using: createDecoder())
    }

    // MARK: Adding and Setting
    public func setValue<T>(at path: Path<T>, value: T) throws where T: Encodable {
        try database.setValue(at: path, value: value, using: createEncoder())
    }

    public func addValue<T>(at path: Path<T>.Collection, value: T) throws where T: Encodable {
        try database.addValue(at: path, value: value, using: createEncoder())
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
