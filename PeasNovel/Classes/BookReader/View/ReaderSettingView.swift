//
//  ReaderSettingView.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/13.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import AVKit

class ReaderSettingView: UIView {
    @IBOutlet var fontBtns: [UIButton]!
    @IBOutlet weak var fontLabel: UILabel!
    @IBOutlet var screenLightBtns: [UIButton]!
    @IBOutlet var changePageModetBtns: [UIButton]!
    @IBOutlet var colorsBtns: [UIButton]!
    @IBOutlet var cornorContainerViews: [UIView]!
    private(set) var fontSpace:NSInteger = 1
    private(set) var colors = DZMReadBGColors
    
    /// 菜单
    weak var readMenu: ReaderMenuController!
    
    private var preVolume: Float!
    
    private var isIntoBag: Bool = false
    
    private var isAddNoti: Bool = false
    
    private var timer: Timer?
    
    private var currentTime: Int = 1
    
    var preLight: CGFloat?
    
    @IBOutlet weak var colorContainer: UIScrollView!

    override func awakeFromNib() {
        super.awakeFromNib()
        preVolume = AVAudioSession.sharedInstance().outputVolume
        colorContainer.contentSize = CGSize(width: UIScreen.main.bounds.width * 2, height: 0)
        cornorContainerViews.forEach { (view) in
            view.layer.cornerRadius = 3
            view.layer.borderColor = UIColor(0xADADAD).cgColor
            view.layer.borderWidth = 0.5
        }
        
        changePageModetBtns.forEach { (btn) in
            btn.addTarget(self, action: #selector(adjustPageModeAction(_:)), for: UIControl.Event.touchUpInside)
        }
        
         NotificationCenter.default.addObserver(self, selector: #selector(self.realodTimer), name: Notification.Name.Event.readerIsWorking, object: nil)
        
        screenLightBtns.forEach { (btn) in
            btn.addTarget(self, action: #selector(screenLightBtnAction(_:)), for: UIControl.Event.touchUpInside)
            let sceenTime = DZMReadConfigure.shared().screenLightTime
            btn.isSelected = sceenTime == btn.tag
            if sceenTime != 200 && btn.isSelected {
                configTimer(btn.tag * 60)
            }
        }
        
        
        colorsBtns.forEach { (btn) in
            btn.layer.cornerRadius = 30 * 0.5
            btn.layer.masksToBounds = true
            btn.addTarget(self, action: #selector(adjustColorAction(_:)), for: UIControl.Event.touchUpInside)
        }
        
        fontBtns.forEach { (btn) in
            btn.layer.cornerRadius = 3
            btn.layer.borderWidth = 0.5
            btn.layer.borderColor = UIColor(0xADADAD).cgColor
            btn.layer.masksToBounds = true
            btn.addTarget(self, action: #selector(adjustFontAction(_:)), for: UIControl.Event.touchUpInside)
        }
        fontLabel.text = "\(DZMReadConfigure.shared().fontSize)"
        colorsBtns.forEach {$0.isSelected = false}
        changePageModetBtns.forEach {$0.isSelected = false}
        changePageModetBtns.forEach { (_btn) in
            if _btn.tag == DZMReadConfigure.shared().effectType {
                _btn.isSelected = true
            }
        }
        
        colorsBtns.forEach { (_btn) in
            if _btn.tag == DZMReadConfigure.shared().colorIndex {
                _btn.isSelected = true
            }
        }
        
       UIApplication.shared.isIdleTimerDisabled = true
    }
    
    
    static func loadView(readMenu: ReaderMenuController) -> ReaderSettingView {
        guard let view = Bundle.main.loadNibNamed("ReaderSettingView", owner: nil, options: nil)?.first as? ReaderSettingView else {
            return ReaderSettingView()
        }
        
        view.readMenu = readMenu
        view.backgroundColor = UIColor.menu
        return view
    }
    
    /// 调整字体
    @objc private func adjustFontAction( _ btn: UIButton) {
        if btn.tag == 0 { /// 调小
            // 没有小于最小字体
            if (DZMReadConfigure.shared().fontSize - fontSpace) >= DZMReadMinFontSize {
                DZMReadConfigure.shared().fontSize -= fontSpace
                readMenu.delegate?.readMenuClickSetuptFontSize?(readMenu: readMenu, fontSize: CGFloat(DZMReadConfigure.shared().fontSize))
            }
            
        } else {
            // 没有大于最大字体
            if (DZMReadConfigure.shared().fontSize + fontSpace) <= DZMReadMaxFontSize {
                DZMReadConfigure.shared().fontSize += fontSpace
                readMenu.delegate?.readMenuClickSetuptFontSize?(readMenu: readMenu, fontSize: CGFloat(DZMReadConfigure.shared().fontSize))
            }
        }
        fontLabel.text = "\(DZMReadConfigure.shared().fontSize)"
        
    }
    
    /// 调整颜色
    @objc private func adjustColorAction(_ btn: UIButton) {
         readMenu.delegate?.readMenuClickSetuptColor?(readMenu: readMenu, index: btn.tag, color: colors[btn.tag])
        colorsBtns.forEach {$0.isSelected = false}
        colorsBtns.forEach { (_btn) in
            if _btn.tag == btn.tag {
                _btn.isSelected = true
            }
        }
    }
    
    /// 翻页模式
    @objc private func adjustPageModeAction(_ btn: UIButton) {
        readMenu.delegate?.readMenuClickSetuptEffect?(readMenu: readMenu, index: btn.tag)
        changePageModetBtns.forEach {$0.isSelected = false}
        changePageModetBtns.forEach { (_btn) in
            if _btn.tag == btn.tag {
                _btn.isSelected = true
            }
        }
    }

    /// 屏幕常亮按钮
    @objc private func screenLightBtnAction(_ btn: UIButton) {
        screenLightBtns.forEach {$0.isSelected = false}
        screenLightBtns.forEach { (_btn) in
            if _btn.tag == btn.tag {
                _btn.isSelected = true
            }
        }
        DZMReadConfigure.shared().screenLightTime = btn.tag
        if btn.tag == 200 {
            if (timer?.isValid) ?? false {
                timer!.invalidate()
                timer = nil
            }
            return
        }
        configTimer(btn.tag * 60)
       
    }
    
    private func configTimer( _ endTime: Int) {
        timer?.invalidate()
        timer = nil
        currentTime = 0
        timer = Timer(timeInterval: 1, repeats: true) {[weak self] (_) in
            guard let weakSelf = self else {
                return
            }
            weakSelf.currentTime += 1
            if weakSelf.currentTime >= endTime {
                weakSelf.currentTime = 0
                weakSelf.preLight = UIScreen.main.brightness
                 weakSelf.readMenu.adjustLight(with: 0.2)
            }
        }
        RunLoop.current.add(timer!, forMode: RunLoop.Mode.default)

    }
    
    ///  音量建翻页
//    @objc private func chagePgaeBtnAction(_ btn: UIButton) {
//        changePagetBtns.forEach {$0.isSelected = false}
//        changePagetBtns.forEach { (_btn) in
//            if _btn.tag == btn.tag {
//                _btn.isSelected = true
//            }
//        }

//        if btn.tag == 1 { ///开启
//           DZMReadConfigure.shared().isVolumekeyChangePage = 1
//        } else {
//             DZMReadConfigure.shared().isVolumekeyChangePage = 0
//        }
//    }
    
        deinit {
            if timer != nil {
                timer?.invalidate()
                timer = nil
            }
            
            NotificationCenter.default.post(name: NSNotification.Name.Event.readerIsWorking, object: nil)
           
    }
    
   @objc  func willResignActiveNotification() {
        isIntoBag = true
    }
    
   @objc  func didBecomeActiveNotification() {
        isIntoBag = false
    }
    
    @objc func realodTimer() {
        if let preLight = self.preLight {
              readMenu.adjustLight(with: preLight)
              self.preLight = nil
        }
        currentTime = 0
    }
}
