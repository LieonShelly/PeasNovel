//
//  AnimationUtl.swift
//  Arab
//
//  Created by lieon on 2018/10/12.
//  Copyright © 2018 kanshu.com. All rights reserved.
//

import Foundation
import UIKit

class AnimationUtl {
    static func addAttackAnimation(with image: UIImage,
                                   animationView: UIView,
                                   startPoint: CGPoint,
                                   endPoint: CGPoint,
                                   completion: (() -> Void)?) {
        let animationLayer = CAShapeLayer()
        animationLayer.frame = CGRect(x: startPoint.x - 20, y: startPoint.y - 20, width: 40, height: 40)
        animationLayer.contents = image.cgImage
        animationView.layer.addSublayer(animationLayer)
        let movePath = UIBezierPath()
        movePath.move(to: startPoint)
        movePath.addQuadCurve(to: endPoint, controlPoint: CGPoint(x: 200, y: 100))
        let pathAnimation = CAKeyframeAnimation(keyPath: "position")
        let durationTime: CGFloat = 1 // 动画时间1秒
        pathAnimation.duration = CFTimeInterval(durationTime)
        pathAnimation.isRemovedOnCompletion = true
        pathAnimation.fillMode = CAMediaTimingFillMode(rawValue: "forwards")
        pathAnimation.path = movePath.cgPath
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 1.0
        scaleAnimation.toValue = 0.5
        scaleAnimation.duration = 1.0
        scaleAnimation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName(rawValue: "easeInEaseOut"))
        scaleAnimation.isRemovedOnCompletion = true
        scaleAnimation.fillMode = CAMediaTimingFillMode(rawValue: "forwards")
        animationLayer.add(pathAnimation, forKey: nil)
        animationLayer.add(scaleAnimation, forKey: nil)
        DispatchQueue.main.async {
            completion?()
        }
    }
    
}
