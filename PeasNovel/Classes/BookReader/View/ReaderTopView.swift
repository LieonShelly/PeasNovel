//
//  ReaderTopView.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/12.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class ReaderTopView: UIView {
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var listenBtn: UIButton!
    @IBOutlet weak var mroeBtn: UIButton!
    @IBOutlet weak var backBtn: UIButton!
    /// 菜单
    weak var readMenu: ReaderMenuController!
    
    static func loadView(readMenu:ReaderMenuController) -> ReaderTopView {
        guard let view = Bundle.main.loadNibNamed("ReaderTopView", owner: nil, options: nil)?.first as? ReaderTopView else {
            return ReaderTopView()
        }
        
        view.readMenu = readMenu
        view.backgroundColor = UIColor.menu
        return view
    }
    
}
