//
//  DismissBtn.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/19.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class DismissBtn: UIView {
    var timer: Timer?
    var btnAction: (() -> Void)?
    fileprivate lazy var btn: UIButton = {
        let btn = UIButton()
        btn.setBackgroundImage(UIImage(named: "back_top"), for: .normal)
        return btn
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setupUI()
    }
    
    private func setupUI() {
        addSubview(btn)
        btn.addTarget(self, action: #selector(self.btnTap), for: .touchUpInside)
    }
    
   @objc private func btnTap() {
        btnAction?()
    }
    
    func hidden(_ isHidden: Bool) {
        self.isHidden = isHidden
        if isHidden {
            removeTimer()
        }
    }
    
    func addTimer(_ timeInterval: Double) {
        timer = Timer(timeInterval: timeInterval, repeats: true, block: {[weak self] (timer) in
            guard let weakSelf = self else {
                return
            }
            weakSelf.isHidden = true
            timer.invalidate()
            weakSelf.timer = nil
        })
    }
    
    func fireTimer() {
        removeTimer()
        addTimer(3)
        RunLoop.current.add(timer!, forMode: .common)
    }
    
   func removeTimer() {
        timer?.invalidate()
        timer = nil
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        btn.frame = CGRect(x: 0, y: 0, width: 70, height: 70)
        btn.center = CGPoint(x: width * 0.5, y: height * 0.5)
    }
    
    deinit {
        removeTimer()
    }
}
