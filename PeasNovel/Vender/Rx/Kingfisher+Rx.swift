//
//  Kingfisher+Rx.swift
//  Arab
//
//  Created by lieon on 2018/11/1.
//  Copyright © 2018 kanshu.com. All rights reserved.
//

import Kingfisher
import UIKit
import RxSwift
import RxCocoa

extension Reactive where Base: UIButton {
    
    func setBackgroundImage(_ state: UIControl.State) -> Binder<(URL, UIImage?)> {
        return Binder<(URL, UIImage?)>(base, scheduler: MainScheduler.instance, binding: { (control, value) in
            print(value)
//            control.kf.setBackgroundImage(with: value.0, for: state, placeholder: value.1)
            control.contentMode = UIView.ContentMode.center
            _ = control.kf.setBackgroundImage(with: value.0, for: state, placeholder: value.1, completionHandler: { (img, err, type, url) in
                control.contentMode = UIView.ContentMode.scaleAspectFit
            })
        })
    }
}

extension ObservableType where Element == URL {
    func retrieveImage() -> Observable<UIImage?> {
        return flatMap { url in
            return Observable<UIImage?>.create({ (oberver) -> Disposable in
                ImageCache.default.retrieveImage(forKey: url.absoluteString, completionHandler: { (result) in
                    switch result {
                    case .success(let value):
                        oberver.onNext(value.image)
                        oberver.onCompleted()
                    case .failure:
                        ImageDownloader.default.downloadImage(with: url, completionHandler: { (result) in
                            switch result {
                            case .success(let value):
                                ImageCache.default.store(value.image, forKey: url.absoluteString)
                                oberver.onNext(value.image)
                                oberver.onCompleted()
                            case .failure(let error):
                                oberver.onError(error)
                            }
                        })
                    }
                })
                return Disposables.create {}
            })
        }
    }
    
    func downlaodImage() ->  Observable<UIImage?>  {
        return  flatMap { (url)  in
            return Observable<UIImage?>.create({ (observer) -> Disposable in
                ImageDownloader.default.downloadImage(with: url, completionHandler: { (result) in
                    switch result {
                    case .success(let value):
                        ImageCache.default.store(value.image, forKey: url.absoluteString)
                        observer.onNext(value.image)
                        observer.onCompleted()
                    case .failure(let error):
                        observer.onError(error)
                    }
                })
                return Disposables.create {}
            })
        }
        
    }
    
}

