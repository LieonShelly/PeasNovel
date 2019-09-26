//
//  NavigationViewController.swift
//  Arab
//
//  Created by lieon on 2018/9/19.
//  Copyright © 2018年 kanshu.com. All rights reserved.
//

import UIKit

class NavigationViewController: UINavigationController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let navImage = UIImage(color: 0xFFFFFF)?.resizableImage(withCapInsets: UIEdgeInsets.zero, resizingMode: .stretch)
        navigationBar.setBackgroundImage(navImage, for: UIBarMetrics.default)
//        navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.black,
//                                             NSAttributedString.Key.font: UIFont.systemFont(ofSize: 18)]
        navigationBar.backIndicatorImage = UIImage(named: "back")?.withRenderingMode(.alwaysOriginal)
        navigationBar.backIndicatorTransitionMaskImage =  UIImage(named: "back")?.withRenderingMode(.alwaysOriginal)
        navigationBar.tintColor = UIColor(0x3C425B)
        navigationBar.shadowImage = UIImage(color: 0xeeeeee)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func pushViewController(_ viewController: UIViewController, animated: Bool) {
        if viewController is BookSheetViewController {
            
        } else if viewControllers.count >= 1 {
            viewController.hidesBottomBarWhenPushed = true
        }
        viewController.navigationItem.backBarButtonItem =  UIBarButtonItem(title: " ", style: .plain, target: nil, action: nil)
        return super.pushViewController(viewController, animated: animated)
    }
    
    
}


extension NavigationViewController: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == self.interactivePopGestureRecognizer {
            if self.viewControllers.count < 2 ||
                self.visibleViewController == viewControllers.first {
                return false;
            }
        }
        return true
    }
}

