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

extension Reactive where Base: Database {
    func observeSingleEvent<T>(at path: Path<T>, using decoder: StructureDecoder = .init()) -> Single<T> where T: Decodable {
        return Single.create { single in
            self.base.observeSingleEvent(at: path, using: decoder, with: { (result: DecodeResult<T>) in
                single(result.asSingleEvent)
            })
            return Disposables.create()
        }
    }

    func observe<T>(at path: Path<T>, using decoder: StructureDecoder = .init()) -> Observable<DecodeResult<T>> where T: Decodable {
        return Observable.create { observer in
            let handle = self.base.observe(at: path, using: decoder, with: { (result: DecodeResult<T>) in
                observer.onNext(result)
            })
            return Disposables.create {
                self.base[path].removeObserver(withHandle: handle)
            }
        }
    }

    func observeSingleEvent<T>(of eventType: CollectionEventType, at path: Path<T>.Collection, using decoder: StructureDecoder = .init()) -> Single<T> where T: Decodable {
        return Single.create { single in
            self.base.observeSingleEvent(of: eventType, at: path, using: decoder, with: { (result: DecodeResult<T>) in
                single(result.asSingleEvent)
            })
            return Disposables.create()
        }
    }

    func observe<T>(eventType: CollectionEventType, at path: Path<T>.Collection, using decoder: StructureDecoder = .init()) -> Observable<DecodeResult<T>> where T: Decodable {
        return Observable.create { observer in
            let handle = self.base.observe(eventType: eventType, at: path, using: decoder, with: { (result: DecodeResult<T>) in
                observer.onNext(result)
            })
            return Disposables.create {
                self.base[path].removeObserver(withHandle: handle)
            }
        }
    }
}
