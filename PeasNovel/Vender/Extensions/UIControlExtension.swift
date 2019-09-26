//
//  UIControlExtension.swift
//  PeasNovel
//
//  Created by lieon on 2019/3/28.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import UIKit
import RxSwift
import RxCocoa

extension UIButton {
    static func countDown(_ timeout: Int,
                          inputView: UIButton,
                          countDownTitle: String,
                          normalTitle: String,
                          completion: ((Bool) -> Void)?) {
        var total = timeout
        let queue = DispatchQueue(label: "countdown")
    
        let timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags.init(rawValue: 0), queue: queue)
        
        timer.schedule(deadline: .now(), repeating: .milliseconds(1000))
        timer.setEventHandler {
            DispatchQueue.main.async {
                if total == 0 {
                    inputView.isUserInteractionEnabled = true
                    inputView.setTitle(normalTitle, for: UIControl.State.normal)
                    timer.cancel()
                    completion?(true)
                } else {
                    inputView.isUserInteractionEnabled = false
                    inputView.setTitle( "\(total)" + countDownTitle, for: UIControl.State.normal)
                     completion?(false)
                }
                total = total - 1
            }
        }
        timer.resume()
    }
    
    static func countDown(_ timeout: Int,
                          inputView: UIButton,
                          countDownTitle: String,
                          normalTitle: String,
                          isEnableWhenCounting: Bool = false,
                          countDownFinish: (() -> (Void))?) {
        var total = timeout
        let queue = DispatchQueue(label: "countdown")
        let timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags.init(rawValue: 0), queue: queue)
        timer.schedule(deadline: .now(), repeating: .milliseconds(1000))
        timer.setEventHandler {
            DispatchQueue.main.async {
                if total == 0 {
                    inputView.isUserInteractionEnabled = true
                    inputView.setTitle(normalTitle, for: UIControl.State.normal)
                    timer.cancel()
                    countDownFinish?()
                } else {
                    inputView.isUserInteractionEnabled = isEnableWhenCounting
                    inputView.setTitle( "\(total)" + countDownTitle, for: UIControl.State.normal)
                }
                total = total - 1
            }
        }
        timer.resume()
    }
}


extension UITabBar {
    static var height: CGFloat {
        if UIDevice.current.isiPhoneXSeries {
           return 49 + UIDevice.current.safeAreaInsets.bottom
        }
        return 49
    }
}

extension UINavigationBar {
    static var height: CGFloat {
        if UIDevice.current.isiPhoneXSeries {
            return 44 + UIDevice.current.safeAreaInsets.top + UIApplication.shared.statusBarFrame.height
        }
        return 44 + UIApplication.shared.statusBarFrame.height
    }
}

extension UIView {

    static func copyView(_ view: UIView? ) -> UIView? {
        guard let view = view else {
            return nil
        }
        let data = NSKeyedArchiver.archivedData(withRootObject: view)
       return NSKeyedUnarchiver.unarchiveObject(with: data) as? UIView
    }
}


extension UIApplication {
    
}
