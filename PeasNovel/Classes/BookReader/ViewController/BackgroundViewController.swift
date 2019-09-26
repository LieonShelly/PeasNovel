//
//  BackgroundViewController.swift
//  ReaderKit
//
//  Created by lieon on 2017/12/20.
//  Copyright © 2018年lieon. All rights reserved.
//

import UIKit

class BackgroundViewController: UIViewController {

    /// 目标视图(无值则跟阅读背景颜色保持一致)
    weak var targetView:UIView?
    
    /// imageView
    private(set) var imageView:UIImageView!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        // imageView
        imageView = UIImageView()
        imageView.backgroundColor = DZMReadConfigure.shared().readColor()
        imageView.frame = view.bounds
        imageView.layer.transform = CATransform3DMakeRotation(CGFloat.pi, 0, 1, 0)
        view.addSubview(imageView)
        
        // 展示图片
        if targetView != nil { imageView.image = ScreenCapture(targetView) }
    }

    override func didReceiveMemoryWarning() {
        
        super.didReceiveMemoryWarning()
    }
}
