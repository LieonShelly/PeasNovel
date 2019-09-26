//
//  HandyJSON+Rx.swift
//  Arab
//
//  Created by lieon on 2018/9/14.
//  Copyright © 2018年 kanshu.com. All rights reserved.
//

import HandyJSON
import Result
import RxSwift
import Moya
import RxMoya

extension ObservableType where Element: HandyJSON {
    
    public func filterError() -> Observable<Element> {
        return flatMap { model -> Observable<Element> in
            return Observable.create { observer -> Disposable in
                
                let result = model.filterError()
                if case Result.success(_) = result {
                    observer.onNext(model)
                    observer.onCompleted()
                }
                if case Result.failure(let error) = result {
                    observer.onError(error)
                }
                
                return Disposables.create { }
            }
        }
    }
    
    internal func trackMapError(_ errorTracker: ErrorTracker) -> Observable<Element> {
        return flatMap { model -> Observable<Element> in
            return Observable.create { observer -> Disposable in
                
                let result = model.filterError()
                if case Result.success(_) = result {
                    observer.onNext(model)
                    observer.onCompleted()
                }
                if case Result.failure(let error) = result {
                    observer.onError(error)
                }
                
                return Disposables.create { }
            }
            }
            .trackError(errorTracker)
            .catchError { (error) -> Observable<Element> in
                return Observable.never()
        }
        
    }
    
    
    
    
}

extension HandyJSON {
    
    func filterError() -> Result<HandyJSON, NetError> {
        guard let json = toJSON() else {
            return .failure(NetError.unknown)
        }
        
        if let code = json["code"] as? Int, code != 0 {
            return .failure(NetError.unknown)
        }
        return .success(self)
    }
}
