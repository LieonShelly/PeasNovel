//
//  DZMRMBaseView.swift
//  ReaderKit
//
//  Created by lieon on 2017/5/11.
//  Copyright © 2018年lieon. All rights reserved.
//

import UIKit

class DZMRMBaseView: UIControl {

    /// 菜单
    weak var readMenu: ReaderMenuController!
    
    /// 初始化方法
    convenience init(readMenu:ReaderMenuController) {
        
        self.init(frame:CGRect.zero,readMenu:readMenu)
    }
    
    /// 初始化方法
    init(frame:CGRect,readMenu:ReaderMenuController) {
        
        self.readMenu = readMenu
        
        super.init(frame: frame)
        
        addSubviews()
    }
    
    /// 初始化方法
    override init(frame: CGRect) {
        
        super.init(frame: frame)
        
        addSubviews()
    }
    
    /// 添加子控件
    func addSubviews() {
        
        backgroundColor = UIColor.menu
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
