//
//  UITableViewExtension.swift
//  Arab
//
//  Created by lieon on 2018/9/6.
//  Copyright © 2018年lieon. All rights reserved.
//

import UIKit

extension UITableView {
    //MARK: - Cell
    func registerNibWithCell<T: UITableViewCell>(_ cell: T.Type) {
        register(UINib(nibName: String(describing: cell), bundle: nil), forCellReuseIdentifier: String(describing: cell))
    }
    
    func registerClassWithCell<T: UITableViewCell>(_ cell: T.Type) {
        register(cell, forCellReuseIdentifier: String(describing: cell))
    }
    
    func dequeueCell<T: UITableViewCell>(_ cell: T.Type) -> T {
        return dequeueReusableCell(withIdentifier: String(describing: cell)) as! T
    }
    
    func dequeueCell<T: UITableViewCell>(_ cell: T.Type, for indexPath: IndexPath) -> T {
        return dequeueReusableCell(withIdentifier: String(describing: cell), for: indexPath) as! T
    }
    
    //MARK: - HeaderFooterView
    func registerNibWithHeaderFooterView<T: UITableViewHeaderFooterView>(_ headerFooterView: T.Type) {
        register(UINib(nibName: String(describing: headerFooterView), bundle: nil), forHeaderFooterViewReuseIdentifier: String(describing: headerFooterView))
    }
    
    func registerClassWithHeaderFooterView<T: UITableViewHeaderFooterView>(_ headerFooterView: T.Type) {
        register(headerFooterView, forHeaderFooterViewReuseIdentifier: String(describing: headerFooterView))
    }
    
    func dequeueHeaderFooterView<T: UITableViewHeaderFooterView>(_ headerFooterView: T.Type) -> T {
        return dequeueReusableHeaderFooterView(withIdentifier: String(describing: headerFooterView)) as! T
    }
}

//extension UITableView {
//    /**
//     获取当前显示最小的IndexPath
//     
//     - returns: 最小的indexPath
//     */
//    func minVisibleIndexPath() ->IndexPath? {
//        
//        if indexPathsForVisibleRows != nil && !indexPathsForVisibleRows!.isEmpty {
//            
//            var minIndexPath:IndexPath! = indexPathsForVisibleRows!.first
//            
//            for indexPath in indexPathsForVisibleRows! {
//                
//                let reuslt = minIndexPath.compare(indexPath) // 比较
//                
//                if reuslt == ComparisonResult.orderedSame { // 相等
//                    
//                }else if reuslt == ComparisonResult.orderedDescending { // 左边的操作对象大于右边的对象
//                    
//                    minIndexPath = indexPath
//                    
//                }else if reuslt == ComparisonResult.orderedAscending { // 左边的操作对象小于右边的对象
//                    
//                }else{}
//            }
//            
//            return minIndexPath
//        }
//        
//        return nil
//    }
//    
//    /**
//     获取当前显示最大的IndexPath
//     
//     - returns: 最大的indexPath
//     */
//    func maxVisibleIndexPath() ->IndexPath? {
//        
//        if indexPathsForVisibleRows != nil && !indexPathsForVisibleRows!.isEmpty {
//            
//            var maxIndexPath:IndexPath! = indexPathsForVisibleRows!.first
//            
//            for indexPath in indexPathsForVisibleRows! {
//                
//                let reuslt = maxIndexPath.compare(indexPath) // 比较
//                
//                if reuslt == ComparisonResult.orderedSame { // 相等
//                    
//                }else if reuslt == ComparisonResult.orderedDescending { // 左边的操作对象大于右边的对象
//                    
//                }else if reuslt == ComparisonResult.orderedAscending { // 左边的操作对象小于右边的对象
//                    
//                    maxIndexPath = indexPath
//                    
//                }else{}
//            }
//            
//            return maxIndexPath
//        }
//        
//        return nil
//    }
//}

extension UIViewController {
    class func current(base: UIViewController? = UIApplication.shared.keyWindow?.rootViewController) -> UIViewController? {
        if let nav = base as? UINavigationController {
            return current(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            return current(base: tab.selectedViewController)
        }
        if let presented = base?.presentedViewController {
            return current(base: presented)
        }
        return base
    }
}

