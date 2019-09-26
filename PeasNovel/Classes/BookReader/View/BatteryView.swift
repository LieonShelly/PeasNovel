//
//  BatteryView.swift
//  ReaderKit
//
//  Created by lieon on 2017/5/11.
//  Copyright © 2018年lieon. All rights reserved.
//

import UIKit

class BatteryView: UIImageView {

    /// 颜色
    override var tintColor: UIColor! {
        didSet{
            levelView.backgroundColor = tintColor
        }
    }
    
    /// BatteryLevel
    var level: Float {
        get{
            let level = UIDevice.current.batteryLevel
            if level < 0 {
                return 0
            }else if level > 1 {
                return 1
            }
            return level
        }
    }
    
    /// 初始化
    convenience init() {
        self.init(frame: CGRect(origin: CGPoint.zero, size: Config.Battery.Size))
    }
    
    /// 初始化
    override init(frame: CGRect) {
        super.init(frame: CGRect(origin: frame.origin, size: Config.Battery.Size))
        image = UIImage(named: "icon_battery_black")?.withRenderingMode(.alwaysTemplate)
        tintColor = UIColor.white
        addSubview(levelView)
        addConstraints()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(lowPowerModeChange),
                                               name: Notification.Name.NSProcessInfoPowerStateDidChange,
                                               object: nil)
        lowPowerModeChange()
    }
    
    private func addConstraints() {
        
        let w = (Config.Battery.Size.width-8) * CGFloat(level)
        levelView.snp.makeConstraints {
            $0.leading.equalTo(3)
            $0.top.equalTo(2)
            $0.height.equalTo(Config.Battery.Size.height-4)
            $0.width.equalTo(w)
        }
    }
    
    func update() {
        
        let w = (Config.Battery.Size.width-8) * CGFloat(level)
        levelView.snp.updateConstraints {
            $0.width.equalTo(w)
        }
    }
    
    @objc func lowPowerModeChange() {
        if ProcessInfo.processInfo.isLowPowerModeEnabled {
            tintColor = UIColor.orange
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// BatteryLevelView
    private lazy var levelView: UIView = {
        // 进度
        let view = UIView()
        view.layer.masksToBounds = true
        
        let spaceW = (Config.Battery.Size.width - 5) / Config.Battery.Size.width
        let height = frame.height - 3.4*spaceW
        view.layer.cornerRadius = height * 0.125
        return view
    }()


}
