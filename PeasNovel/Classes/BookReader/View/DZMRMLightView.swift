//
//  DZMRMLightView.swift
//  ReaderKit
//
//  Created by lieon on 2017/5/11.
//  Copyright © 2018年lieon. All rights reserved.
//

import UIKit

class DZMRMLightView: DZMRMBaseView {

    /// 左
    private(set) var leftImageView: UIImageView!
    
    /// 进度条
    private(set) var slider:UISlider!
    
    /// 右
    private(set) var rightImageView: UIImageView!
    
    override func addSubviews() {
        
        super.addSubviews()
        
        leftImageView = UIImageView(image: UIImage(named: "light1"))
        addSubview(leftImageView)
        
        rightImageView = UIImageView(image: UIImage(named: "light"))
        addSubview(rightImageView)
        
        // 进度条
        slider = UISlider()
        slider.minimumValue = 0.0
        slider.maximumValue = 1.0
        slider.tintColor = DZMColor_253_85_103
        slider.setThumbImage(UIImage(named: "RM_3")!, for: .normal)
        slider.addTarget(self, action: #selector(DZMRMLightView.sliderChanged(_:)), for: UIControl.Event.valueChanged)
        slider.value = Float(UIScreen.main.brightness)
        addSubview(slider)
        
        backgroundColor = UIColor.clear
//        addConstraint()
    }
    
    func addConstraint() {
        leftImageView.snp.makeConstraints {
            $0.leading.equalTo(16)
            $0.width.height.equalTo(20)
            $0.top.equalTo(20)
        }
        
        rightImageView.snp.makeConstraints {
            $0.trailing.equalTo(-16)
            $0.width.height.equalTo(20)
            $0.top.equalTo(20)
        }
        
        slider.snp.makeConstraints {
            $0.leading.equalTo(leftImageView.snp.trailing).offset(20)
            $0.trailing.equalTo(rightImageView.snp.leading).offset(-20)
            $0.centerY.equalTo(leftImageView.snp.centerY)
        }
    }
    
    override func layoutSubviews() {
        addConstraint()
        
    }
    
    /// 滑动方法
    @objc private func sliderChanged(_ slider:UISlider) {
        
        UIScreen.main.brightness = CGFloat(slider.value)
    }
}
