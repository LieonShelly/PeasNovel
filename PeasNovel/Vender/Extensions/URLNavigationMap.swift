
//
//  URLNavigator.swift
//  Arab
//
//  Created by lieon on 2018/10/11.
//  Copyright © 2018 kanshu.com. All rights reserved.
//

import Foundation
import UIKit
import Moya

struct URLNavigationMap {
    
    static func initialize(navigator: NavigatorType) {
        navigator.register("client://kanshu/book_detail") { url, values, context in
            if let bookId = url.queryParameters["book_id"] {
                 BookReaderHandler.jump(bookId)
            }
           return nil
        }
        
        navigator.register("client://kanshu/reader") { url, values, context in
            if let bookId = url.queryParameters["book_id"] {
                let content_id = url.queryParameters["content_id"]
                BookReaderHandler.jump(bookId, contentId: content_id, toReader: true)
            }
            return nil
        }

    
        
        navigator.register("client://kanshu/comm_url") { url, values, context in
            if let urlStr = url.queryParameters["url"] {
                let title = url.queryParameters["title"]
                let vc = CommonWebViewController(WebViewModel(URL(string: urlStr)))
                vc.title = title
                return vc
            }
            return nil
        }
        
        navigator.register("client://kanshu/book_menu_horizontal_list") { (url, param, context) -> UIViewController? in
            print(url)
            if  let vm = context as? BookSheetDetailViewModel {
                return BookSheetHorizontalController(vm)
            }
            if let id = url.queryParameters["id"] {
                let model = BookSheetModel()
                model.id = id
                let title = url.queryParameters["title"]
                let vm = BookSheetDetailViewModel(model)
                let vcc = BookSheetHorizontalController(vm)
                vcc.title = title
                return vcc
            }
             return nil
        }
        
        navigator.register("client://kanshu/book_menu_vertical_list") { (url, param, context) -> UIViewController? in
            print(url)
            if  let vm = context as? BookSheetDetailViewModel {
                 return BookSheetVerticalController(vm)
            }
            if let id = url.queryParameters["id"] {
                let model = BookSheetModel()
                model.id = id
                let title = url.queryParameters["title"]
                let vm = BookSheetDetailViewModel(model)
                let vcc = BookSheetVerticalController(vm)
                vcc.title = title
                return vcc
            }
           return nil
        }
        
        navigator.register("client://kanshu/selected_book_menu_list") { (url, param, context) -> UIViewController? in
            print(url)
            let vm = BookSheetChoiceViewModel()
            return BookSheetChoiceController(vm)
        }
        
        navigator.register("client://kanshu/comm_url") { (url, param, context) -> UIViewController? in
            let param = url.queryParameters
            guard let http = param["url"] else {
                return nil
            }
            let vm = WebViewModel(URL(string: http))
            return CommonWebViewController(vm)
        }
        
        navigator.register("client://kanshu/main") { (url, param, context) -> UIViewController? in
            guard let tabIndex = Int(url.queryParameters["tab_index"] ?? "100") else {
                return nil
            }
            guard let rootVC = UIApplication.shared.keyWindow?.rootViewController as? TabBarController else {
                return nil
            }
            if tabIndex < (rootVC.viewControllers?.count ?? 0) {
                rootVC.selectedIndex = tabIndex
               if let selectedNav = rootVC.selectedViewController as? NavigationViewController {
                    selectedNav.popToRootViewController(animated: true)
                }
            }
            return nil
        }
        
        navigator.register("client://kanshu/charge_no_ad") { (url, param, context) -> UIViewController? in
            let vm = ChargeViewModel()
            return ChargeViewController(vm)
        }
        
        navigator.register("doudou://kanshu/book_detail") { url, values, context in
            if let bookId = url.queryParameters["book_id"] {
                BookReaderHandler.jump(bookId)
            }
            return nil
        }
        
        navigator.register("doudou://kanshu/reader") { url, values, context in
            if let bookId = url.queryParameters["book_id"] {
                let content_id = url.queryParameters["content_id"]
                BookReaderHandler.jump(bookId, contentId: content_id, toReader: true)
            }
            return nil
        }
        
        
        
        navigator.register("doudou://kanshu/comm_url") { url, values, context in
            if let urlStr = url.queryParameters["url"] {
                let title = url.queryParameters["title"]
                let vc = CommonWebViewController(WebViewModel(URL(string: urlStr)))
                vc.title = title
                return vc
            }
            return nil
        }
        
        navigator.register("doudou://kanshu/book_menu_horizontal_list") { (url, param, context) -> UIViewController? in
            print(url)
            if  let vm = context as? BookSheetDetailViewModel {
                return BookSheetHorizontalController(vm)
            }
            if let id = url.queryParameters["id"] {
                let model = BookSheetModel()
                model.id = id
                let title = url.queryParameters["title"]
                let vm = BookSheetDetailViewModel(model)
                let vcc = BookSheetHorizontalController(vm)
                vcc.title = title
                return vcc
            }
            return nil
        }
        
        navigator.register("doudou://kanshu/book_menu_vertical_list") { (url, param, context) -> UIViewController? in
            print(url)
            if  let vm = context as? BookSheetDetailViewModel {
                return BookSheetVerticalController(vm)
            }
            if let id = url.queryParameters["id"] {
                let model = BookSheetModel()
                model.id = id
                let title = url.queryParameters["title"]
                let vm = BookSheetDetailViewModel(model)
                let vcc = BookSheetVerticalController(vm)
                vcc.title = title
                return vcc
            }
            return nil
        }
        
        navigator.register("doudou://kanshu/selected_book_menu_list") { (url, param, context) -> UIViewController? in
            print(url)
            let vm = BookSheetChoiceViewModel()
            return BookSheetChoiceController(vm)
        }
        
        navigator.register("doudou://kanshu/comm_url") { (url, param, context) -> UIViewController? in
            let param = url.queryParameters
            guard let http = param["url"] else {
                return nil
            }
            let vm = WebViewModel(URL(string: http))
            return CommonWebViewController(vm)
        }
        
        navigator.register("doudou://kanshu/main") { (url, param, context) -> UIViewController? in
            guard let tabIndex = Int(url.queryParameters["tab_index"] ?? "100") else {
                return nil
            }
            guard let rootVC = UIApplication.shared.keyWindow?.rootViewController as? TabBarController else {
                return nil
            }
            if tabIndex < (rootVC.viewControllers?.count ?? 0) {
                rootVC.selectedIndex = tabIndex
                if let selectedNav = rootVC.selectedViewController as? NavigationViewController {
                    selectedNav.popToRootViewController(animated: true)
                }
            }
            return nil
        }
        
        navigator.register("doudou://kanshu/charge_no_ad") { (url, param, context) -> UIViewController? in
            let vm = ChargeViewModel()
            return ChargeViewController(vm)
        }
        
        
        navigator.register("doudou://kanshu/reader") { url, values, context in
            if let bookId = url.queryParameters["book_id"] {
                let content_id = url.queryParameters["content_id"]
                BookReaderHandler.jump(bookId, contentId: content_id, toReader: true)
            }
            return nil
        }
        navigator.register("doudou://kanshu/splash") { url, values, context in
            if let origin = url.queryParameters["origin"],
                let jump_url = url.queryParameters["jump_url"],
                let newJumpURLStr = jump_url.removingPercentEncoding?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed),
                 let newJumpURL = URL(string: newJumpURLStr) {
                    me.origin = origin
                    let isLogin = me.isLogin
                    me.isLogin = true /// isLogin为true时，保证user_id能够带到参数中去
                    NotificationCenter.default.post(name: Notification.Name.Advertise.configNeedUpdate, object: nil)
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2, execute: {
                        navigator.push(newJumpURL)
                        me.origin = nil
                        me.isLogin = isLogin
                    })
                }
            return nil
        }
    }

}

extension Navigator {
    func pushChargeVC() {
        let vm = ChargeViewModel()
        let vcc = ChargeViewController(vm)
        push(vcc)
    }
}
