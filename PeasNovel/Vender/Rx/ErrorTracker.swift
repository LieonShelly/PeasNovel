//
// Created by sergdort on 03/02/2017.
// Copyright (c) 2017 sergdort. All rights reserved.
//


import Foundation
import RxSwift
import RxCocoa
import PKHUD
import StatefulViewController

public class ErrorTracker: SharedSequenceConvertibleType {
    public typealias SharingStrategy = DriverSharingStrategy
    private let _subject = PublishSubject<Error>()
    
    func trackError<O: ObservableConvertibleType>(from source: O) -> Observable<O.Element> {
        return source
            .asObservable()
            .do(onError: onError)
    }
    
    public func asSharedSequence() -> SharedSequence<SharingStrategy, Error> {
        return _subject.asObservable().asDriverOnErrorJustComplete()
    }
    
    public func asObservable() -> Observable<Error> {
        return _subject.asObservable()
    }
    
    func asDriver() -> Driver<HUDValue> {
        return _subject.asObservable()
            .map { error -> HUDValue in
                if let error = error as? AppError {
                    return HUDValue(.label(error.message))
                }
                return HUDValue(.label(error.localizedDescription))
            }
            .asDriver(onErrorJustReturn: HUDValue(.errorTip("Error")))
    }
    
    
    private func onError(_ error: Error) {
        _subject.on(.next(error))
    }
    
    deinit {
        _subject.onCompleted()
    }
}

extension ObservableConvertibleType {
    func trackError(_ errorTracker: ErrorTracker) -> Observable<Element> {
        return errorTracker.trackError(from: self)//.catchError{_ in Observable.never() }
    }
}
