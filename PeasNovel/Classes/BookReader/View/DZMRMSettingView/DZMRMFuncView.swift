//
//  DZMRMFuncView.swift
//  ReaderKit
//
//  Created by lieon on 2017/5/11.
//  Copyright © 2018年lieon. All rights reserved.
//

/// 小说FuncView支持类型
enum DZMRMFuncViewType:NSInteger {
    case effect
    case font
    case fontSize
}

import UIKit

class DZMRMFuncView: DZMRMBaseView {
    
    /// 标题
    private(set) var title:String!
    
    /// 标签数组
    private(set) var labels:[String] = []
    
    /// 选中索引
    private(set) var selectIndex:NSInteger = 0
    
    /// 类型
    private(set) var funcType:DZMRMFuncViewType!
    
    /// 选中按钮
    private(set) var selectButton:UIButton?
    
    /// titleLabel
    private(set) var titleLabel:UILabel!
    
    /// 字号按钮
    private(set) var leftButton:UIButton!
    private(set) var rightButton:UIButton!
    
    /// 字体大小增减间隙
    private(set) var fontSpace:NSInteger = 1
    
    /// 初始化方法
    convenience init(frame:CGRect,readMenu:ReaderMenuController,funcType:DZMRMFuncViewType,title:String) {
        
        self.init(frame:frame,readMenu:readMenu,funcType:funcType,title:title,labels:[],selectIndex:0)
    }
    
    /// 初始化方法
    init(frame:CGRect,readMenu:ReaderMenuController,funcType:DZMRMFuncViewType,title:String,labels:[String],selectIndex:NSInteger) {
        
        self.funcType = funcType
        
        self.title = title
        
        self.labels = labels
        
        self.selectIndex = selectIndex
        
        super.init(frame: frame, readMenu: readMenu)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        leftButton.snp.makeConstraints {
            $0.leading.equalTo(16)
            $0.top.equalTo(0)
            $0.height.equalTo(height)
            $0.width.equalTo((ScreenWidth-32)/2)
        }
        
        rightButton.snp.makeConstraints {
            $0.trailing.equalTo(-16)
            $0.top.equalTo(0)
            $0.height.equalTo(height)
            $0.width.equalTo((ScreenWidth-32)/2)
        }
    }
    
    override func addSubviews() {
        // 标题
        titleLabel = UILabel()
        titleLabel.textColor = UIColor.white
        titleLabel.font = UIFont.size_12
        titleLabel.text = title
//        addSubview(titleLabel)
//        titleLabel.frame = CGRect(x: DZMSpace_25, y: 0, width: 55, height: height)
        
        // 布局
        let tempX:CGFloat = titleLabel.frame.maxX + DZMSizeW(50)
        let contentW:CGFloat = ScreenWidth - tempX
        
        if funcType == .font || funcType == .effect {
            
            let count = labels.count
            
            let buttonW:CGFloat = contentW / CGFloat(count)
            
            for i in 0..<count {
                
                let label = labels[i]
                
                let button = UIButton(type: .custom)
                
                button.tag = i
                
                button.titleLabel?.font = UIFont.size_12
                
                button.contentHorizontalAlignment = .left
                
                button.setTitle(label, for: .normal)
                
                button.setTitleColor(UIColor.white, for: .normal)
                
                button.setTitleColor(DZMColor_253_85_103, for: .selected)
                
                button.frame = CGRect(x: tempX + CGFloat(i) * buttonW, y: 0, width: buttonW, height: height)
                
                button.addTarget(self, action: #selector(clickButton(button:)), for: .touchUpInside)
                
                addSubview(button)
                
                if i == selectIndex {
                    
                    selectButton(button: button)
                }
            }
            
        }else{ // 字体大小
            // left
            leftButton = UIButton(type: .custom)
            leftButton.tag = 0
            leftButton.setTitle("A-", for: .normal)
            leftButton.setTitleColor(UIColor(0xD8D8D8), for: .normal)
            leftButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
            leftButton.addTarget(self, action: #selector(clickFontSize(button:)), for: .touchUpInside)
            addSubview(leftButton)
            
            // right
            rightButton = UIButton(type: .custom)
            rightButton.tag = 1
            rightButton.setTitle("A+", for: .normal)
            rightButton.setTitleColor(UIColor(0xD8D8D8), for: .normal)
            rightButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
            rightButton.addTarget(self, action: #selector(clickFontSize(button:)), for: .touchUpInside)
            addSubview(rightButton)
        }
    }
    
    /// .fontSize
    @objc func clickFontSize(button:UIButton) {
        
        if button.tag == 0 { // left
            
            // 没有小于最小字体
            if (DZMReadConfigure.shared().fontSize - fontSpace) >= DZMReadMinFontSize {
                
                DZMReadConfigure.shared().fontSize -= fontSpace
                
                readMenu.delegate?.readMenuClickSetuptFontSize?(readMenu: readMenu, fontSize: CGFloat(DZMReadConfigure.shared().fontSize))
            }
            
        }else{ // right
            
            // 没有大于最大字体
            if (DZMReadConfigure.shared().fontSize + fontSpace) <= DZMReadMaxFontSize {
                
                DZMReadConfigure.shared().fontSize += fontSpace
                
                readMenu.delegate?.readMenuClickSetuptFontSize?(readMenu: readMenu, fontSize: CGFloat(DZMReadConfigure.shared().fontSize))
            }
        }   
    }
    
    /// .font .effect
    @objc func clickButton(button:UIButton) {
        
        if button.isSelected {return}
        
        // 选中按钮
        selectButton(button: button)
        
        // 判断
        if funcType == .font {
            
            readMenu.delegate?.readMenuClickSetuptFont?(readMenu: readMenu, index: button.tag)
            
        }else{
            
            readMenu.delegate?.readMenuClickSetuptEffect?(readMenu: readMenu, index: button.tag)
        }
    }
    
    /// 选中按钮
    private func selectButton(button:UIButton) {
        
        if button.isSelected {return}
        
        selectButton?.isSelected = false
        
        button.isSelected = true
        
        selectButton = button
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

}
