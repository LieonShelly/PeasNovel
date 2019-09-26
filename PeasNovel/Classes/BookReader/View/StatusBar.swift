//
//  StatusBar.swift
//  ReaderKit
//
//  Created by lieon on 2017/5/11.
//  Copyright © 2018年lieon. All rights reserved.
//

import UIKit

class StatusBar: UIView {
    
    var readRecordModel: DZMReadRecordModel! {
        didSet{
            DispatchQueue.main.async {
                self.timeLabel.text =  self.readRecordModel.readChapterModel?.name
                self.titleLabel.text = self.readRecordModel.readChapterModel?.bookInfo?.book_title
            }
        }
    }
    
    /// 初始化方法
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubviews()
    }
   
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func addSubviews() {
        backgroundColor = UIColor.clear
        // 背景颜色
//        backgroundColor = DZMColor_51_51_51.withAlphaComponent(0.4)
//        addSubview(batteryView)
        addSubview(timeLabel)
        addSubview(titleLabel)
        // 初始化调用
//        timeDidChangeTime()
        addConstraint()
    }
    
    func addConstraint() {
        
//        batteryView.snp.makeConstraints {
//            $0.trailing.equalTo(-16)
//            $0.centerY.equalToSuperview()
//        }
        
        timeLabel.snp.makeConstraints {
            $0.right.equalTo(-16)
            $0.top.equalToSuperview()
            $0.left.equalTo(titleLabel.snp.right)
            $0.width.equalTo(titleLabel.snp.width)
//            $0.bottom.equalToSuperview()
//            $0.width.equalTo(50)
        }
        
        titleLabel.snp.makeConstraints {
            $0.leading.equalTo(16)
            $0.top.equalTo(0)
            $0.right.equalTo(timeLabel.snp.left)
            $0.width.equalTo(timeLabel.snp.width)
        }
    }
    
    /// 时间变化
//    func timeDidChangeTime() {
//
//        let dateformatter = DateFormatter()
//        dateformatter.dateFormat = "HH:mm"
//        timeLabel.text = dateformatter.string(from: Date())
//        batteryView.update()
//
//        let date = Date()
//        let time = Int(date.timeIntervalSince1970)%60
//
//        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + TimeInterval(time)) { [weak self] in
//            self?.timeDidChangeTime()
//        }
//    }
    
//    /// 电池
//    private(set) lazy var batteryView: BatteryView = {
//        // 电池
//        let batteryView = BatteryView()
//        batteryView.tintColor = DZMColor_127_136_138
//        return batteryView
//    }()
//
    /// 时间
    private(set) var timeLabel: UILabel = {
        // 时间
        let timeLabel = UILabel()
        timeLabel.textAlignment = .right
        timeLabel.font = UIFont.size_12
        timeLabel.textColor = DZMColor_127_136_138
        return timeLabel
    }()
    
    /// 标题
    private(set) var titleLabel: UILabel = {
        // 标题
        let titleLabel = UILabel()
        titleLabel.font = UIFont.size_12
        titleLabel.textAlignment = .left
        titleLabel.textColor = DZMColor_127_136_138
        return titleLabel
    }()
    
    /// 销毁
    deinit {
        
    }
}
