//
//  ScaleTransitionAnimation.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/17.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class ScaleTransitionAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    
    var isPresent: Bool = true
    var originRect = CGRect.zero
    
    convenience init(from rect: CGRect = CGRect.zero, isPresent: Bool = true) {
        self.init()
        self.isPresent = isPresent
        self.originRect = rect
    }
    
    convenience init(push rect: CGRect = CGRect.zero) {
        self.init()
        self.isPresent = true
        self.originRect = rect
    }
    
    convenience init(pop rect: CGRect = CGRect.zero) {
        self.init()
        self.isPresent = false
        self.originRect = rect
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let fromView = transitionContext.view(forKey: .from) else {
            return
        }
        guard let toView = transitionContext.view(forKey: .to) else {
            return
        }
        
        
        let targetView = isPresent ? toView: fromView
        targetView.frame = UIScreen.main.bounds
        
        let scaleX = originRect.width/targetView.frame.width
        let scaleY = originRect.height/targetView.frame.height
        
        let transform = CGAffineTransform(scaleX: scaleX, y: scaleY)
        
        let originCenter = CGPoint(x: originRect.midX, y: originRect.midY)
        let targetCenter = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
        
        let startTransform = (isPresent ? transform : CGAffineTransform.identity)
        let endTransform = (isPresent ? CGAffineTransform.identity: transform)
        
        let startCenter = (isPresent ? originCenter: targetCenter)
        let endCenter = (isPresent ? targetCenter: originCenter)
        
        let container = transitionContext.containerView
        container.addSubview(toView)
        container.bringSubviewToFront(targetView)
        
        targetView.transform = startTransform
        targetView.center = startCenter
        
        if let tabVC = UIApplication.shared.keyWindow?.rootViewController as? UITabBarController {
            tabVC.tabBar.isHidden = false
            tabVC.tabBar.alpha = isPresent ? 1: 0
            UIView.animate(withDuration: 0.25, animations: {
                tabVC.tabBar.alpha = self.isPresent ? 0: 1
            }, completion: {_ in
                tabVC.tabBar.isHidden = self.isPresent
            })
        }
        
        UIView.animate(withDuration: 0.25, animations: {
            targetView.transform = endTransform;
            targetView.center = endCenter;
        }, completion: { finished in
            let cancel = transitionContext.transitionWasCancelled
            transitionContext.completeTransition(!cancel)
            print(targetView.frame)
        })
    }
    

    deinit {
        print("ScaleTransitionAnimation deinit!!!")
    }
}




class PresentTransitionAnimation: NSObject, UIViewControllerAnimatedTransitioning {
    
    var isPresent: Bool = true
    var originRect = CGRect.zero
    
    convenience init(from rect: CGRect = CGRect.zero, isPresent: Bool = true) {
        self.init()
        self.isPresent = isPresent
        self.originRect = rect
    }
    
    convenience init(push rect: CGRect = CGRect.zero) {
        self.init()
        self.isPresent = true
        self.originRect = rect
    }
    
    convenience init(pop rect: CGRect = CGRect.zero) {
        self.init()
        self.isPresent = false
        self.originRect = rect
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.25
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let fromView = transitionContext.view(forKey: .from) else {
            return
        }
        guard let toView = transitionContext.view(forKey: .to) else {
            return
        }
        print("animateTransition-from:\(fromView.frame)")
        print("animateTransition-toView:\(toView.frame)")
        let cotainerView = transitionContext.containerView
        cotainerView.backgroundColor = UIColor.clear
        if isPresent {
            cotainerView.addSubview(fromView)
            cotainerView.addSubview(toView)
        } else {
            cotainerView.addSubview(toView)
            cotainerView.addSubview(fromView)
        }
        let cancel = transitionContext.transitionWasCancelled
        transitionContext.completeTransition(!cancel)
    }
    
    
    deinit {
        print("ScaleTransitionAnimation deinit!!!")
    }
}
