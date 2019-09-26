//
//  BookReaderHandler.swift
//  Arab
//
//  Created by weicheng wang on 2018/10/11.
//  Copyright © 2018年 kanshu.com. All rights reserved.
//

import UIKit
import RxSwift
import PKHUD

class BookReaderHandler {
    /// 跳转到阅读器或者书籍详情
    class func jump(_ bookId: String, contentId: String? = nil, toReader: Bool = false) {
        if toReader {
             HUD.show(.progress)
        }
        if DZMReadModel.IsExistReadModel(bookID: bookId) || toReader {
            DZMReadParser.getBookDetail(bookID: bookId, contentId: contentId, completion: {
                if toReader {
                    HUD.hide()
                }
                let vm = ReaderViewModel($0)
                let reader = ReaderController(vm)
                navigator.push(reader, animated: false)
                if let rootVC = UIApplication.shared.keyWindow?.rootViewController as? TabBarController, let childVCs = rootVC.viewControllers {
                    for child in childVCs {
                        guard let nav = child as? NavigationViewController else {
                            continue
                        }
                  
                        if let startIndex = nav.viewControllers.firstIndex(where: {$0 is ReaderController}) {
                            let endIndex =  nav.viewControllers.count - startIndex - 1 - 1
                            if endIndex > startIndex {
                                 let vccs = nav.viewControllers[startIndex ... endIndex]
                                for vc in vccs {
                                    if let vcc = vc as? BaseViewController {
                                        vcc.bag = DisposeBag()
                                    }
                                    for subView in vc.view.subviews {
                                        subView.removeFromSuperview()
                                    }
                                }
                            }
                            let upperBounds = nav.viewControllers.count - startIndex - 1
                            if upperBounds > startIndex {
                                let removesvc = nav.viewControllers[startIndex ..< upperBounds]
                                removesvc.forEach({ (vcc) in
                                    if let vc = vcc as? BaseViewController {
                                        vc.bag = DisposeBag()
                                    }
                                })
                            }
                            nav.viewControllers.removeSubrange(Range(NSRange(location: startIndex, length: nav.viewControllers.count - startIndex - 1))!)
                        }
                    }
                }
            })

        }else{
            let vm = BookDetailViewModel(bookId)
            let detailVC = BookDetailViewController(vm)
            navigator.push(detailVC, animated: false)
        }
    }
}

