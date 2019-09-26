//
//  ReaderLightView.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/13.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class ReaderLightView: UIView {
    @IBOutlet weak var nightBtn: UIButton!
    @IBOutlet weak var careEyeBtn: UIButton!
    @IBOutlet weak var sysBtn: UIButton!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var leftLabel: UILabel!
    @IBOutlet weak var rightLabel: UILabel!
    
    /// 菜单
    weak var readMenu: ReaderMenuController!
    

    func normalStyle() {
        nightBtn.layer.cornerRadius = 3
        nightBtn.layer.borderColor = UIColor(0xADADAD).cgColor
        nightBtn.layer.borderWidth = 0.5
        
        careEyeBtn.layer.cornerRadius = 3
        careEyeBtn.layer.borderColor = UIColor(0xADADAD).cgColor
        careEyeBtn.layer.borderWidth = 0.5
        
        sysBtn.layer.cornerRadius = 3
        sysBtn.layer.borderColor = UIColor(0xADADAD).cgColor
        sysBtn.layer.borderWidth = 0.5
        
        sysBtn.isSelected = false
        careEyeBtn.isSelected = false
        nightBtn.isSelected = false
        
    }
    
    fileprivate func selectedStyle( _ btn: UIButton) {
        btn.isSelected = true
        btn.layer.cornerRadius = 3
        btn.layer.borderColor = UIColor(0x00CF7A).cgColor
        btn.layer.borderWidth = 0.5
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        normalStyle()
        slider.setThumbImage(UIImage(named: "gray_cycle"), for: .normal)
        nightBtn.addTarget(self, action: #selector(adjustLightAction(_:)), for: UIControl.Event.touchUpInside)
        careEyeBtn.addTarget(self, action: #selector(adjustLightAction(_:)), for: UIControl.Event.touchUpInside)
        sysBtn.addTarget(self, action: #selector(adjustLightAction(_:)), for: UIControl.Event.touchUpInside)
        slider.addTarget(self, action:  #selector(self.sliderAction(_:for:)), for: .valueChanged)
        
    }
    
    static func loadView(readMenu: ReaderMenuController) -> ReaderLightView {
        guard let view = Bundle.main.loadNibNamed("ReaderLightView", owner: nil, options: nil)?.first as? ReaderLightView else {
            return ReaderLightView()
        }
        view.readMenu = readMenu
        view.backgroundColor = UIColor.menu
        let sliderValue = 1 - DZMUserDefaults.floatForKey(ReaderBrightnessKey)
        view.slider.setValue(sliderValue, animated: true)
        let selectedTag = DZMUserDefaults.integerForKey(ReaderBrightnessBtnKey)
        if selectedTag == 1 {
            view.nightBtn.isSelected = true
        } else if selectedTag == 2 {
            view.careEyeBtn.isSelected = true
        } else if selectedTag == 3 {
             view.sysBtn.isSelected = true
        }
        return view
    }
    
    @objc private func adjustLightAction(_ btn: UIButton) {
        normalStyle()
        selectedStyle(btn)
        readMenu.clickLightButton(button: btn)
        if  btn.tag == 1 {
            slider.value = 0
        } else if btn.tag == 2 {
            slider.value = 0.3
        } else {
            slider.value = Float(UIScreen.main.brightness)
        }
        DZMUserDefaults.setInteger(btn.tag, key: ReaderBrightnessBtnKey)
    }
    
    @objc private func sliderAction(_ slider: UISlider, for event: UIEvent) {
        
        guard let touchEvent = event.allTouches?.first else {
            return
        }
        switch touchEvent.phase {
        case .moved:
            readMenu.adjustLightWithSlider(slider)
        case .ended:
            readMenu.adjustLightWithSliderExit(slider)
        default:
            break
        }
        
    }
}
