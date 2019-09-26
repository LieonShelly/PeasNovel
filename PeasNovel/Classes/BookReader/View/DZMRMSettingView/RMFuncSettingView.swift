//
//  RMFuncSettingView.swift
//  Arab
//
//  Created by lieon on 2018/11/20.
//  Copyright © 2018 kanshu.com. All rights reserved.
//

import UIKit

class RMFuncSettingView: DZMRMBaseView {
    
    /// 字体大小
    private(set) var fontSizeView:DZMRMFuncView!
    private(set) var lightView: DZMRMLightView!
    
    /// 添加控件
    override func addSubviews() {
        
        super.addSubviews()
        
        lightView = DZMRMLightView(frame: CGRect(x: 0, y: 0, width: ScreenWidth, height: 44))
        
        addSubview(lightView)
        
//        lightView.frame = CGRect(x: 0, y: 0, width: ScreenWidth, height: 44)
        
        // 字体大小
        fontSizeView = DZMRMFuncView(frame:CGRect(x: 0, y: 44, width: ScreenWidth, height: 44), readMenu:readMenu, funcType: .fontSize, title: "")
        addSubview(fontSizeView)
    }
    
}
