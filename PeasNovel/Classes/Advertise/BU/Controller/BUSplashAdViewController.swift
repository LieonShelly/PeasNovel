//
//  BUSplashAdViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/28.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class BUSplashAdViewController: UIViewController {

    @IBOutlet weak var bottomView: UIView!
    fileprivate var config: LocalAdvertise?
    var gdtSplash: GDTSplashAd?
    @IBOutlet weak var splashContainerView: UIView!
    @IBOutlet weak var logoBottom: NSLayoutConstraint!
    @IBOutlet weak var containerHeight: NSLayoutConstraint!
    
    convenience init(_ config: LocalAdvertise) {
        self.init(nibName: "GDTSplashAdViewController", bundle: nil)
        self.config = config
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.white
        
    }
    
    override func viewSafeAreaInsetsDidChange() {
        if #available(iOS 11.0, *) {
            super.viewSafeAreaInsetsDidChange()
            containerHeight.constant = 74 + view.safeAreaInsets.bottom
        } else {
            containerHeight.constant = 74
        }
    }
    

}
