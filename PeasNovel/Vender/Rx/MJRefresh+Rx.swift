//
//  MJRefresh+Rx.swift
//  Arab
//
//  Created by lieon on 2018/10/12.
//  Copyright © 2018年 kanshu.com. All rights reserved.
//

import MJRefresh
import RxCocoa
import RxSwift

extension Reactive where Base: MJRefreshComponent {
    //正在刷新事件
    var start: ControlEvent<Void> {
        let source: Observable<Void> = Observable.create { [weak control = self.base] observer  in
            if let control = control {
                control.refreshingBlock = {
                    observer.on(.next(()))
                }
            }
            return Disposables.create()
        }
        return ControlEvent(events: source)
    }
    
    //停止刷新
    var end: Binder<Void> {
        return Binder(base) { refresh, _ in
//            if isEnd {
                refresh.endRefreshing()

//            }
        }
    }
}

extension Reactive where Base: MJRefreshFooter {
    /// 停止刷新，true表示还有数据，false表示没有更多数据
    var endNoMoreData: Binder<Bool> {
        return Binder(base) { refresh, isMore in
            if isMore {
                refresh.resetNoMoreData()
                refresh.endRefreshing()
            }else{
                refresh.endRefreshingWithNoMoreData()
            }
        }
    }
    
    var resetNoMoreData: Binder<Void> {
        return Binder<Void>(base, binding: { (refresh, _) in
            refresh.resetNoMoreData()
        })
    }
}
