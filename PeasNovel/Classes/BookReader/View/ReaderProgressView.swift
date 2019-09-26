//
//  ReaderLightView.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/13.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class ReaderProgressView: UIView {
    @IBOutlet weak var preBtn: UIButton!
    @IBOutlet weak var nexBtn: UIButton!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var progreeLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    /// 菜单
    weak var readMenu: ReaderMenuController!

    
    override func awakeFromNib() {
        super.awakeFromNib()
        slider.setThumbImage(UIImage(named: "gray_cycle"), for: .normal)
        slider.addTarget(self, action:  #selector(self.progreesSliderAction(_:for:)), for: .valueChanged)
        nexBtn.addTarget(self, action:  #selector(self.nextBtnAction(_:)), for: .touchUpInside)
        preBtn.addTarget(self, action:  #selector(self.preBtnAction(_:)), for: .touchUpInside)
    }
    
    
    static func loadView(readMenu: ReaderMenuController) -> ReaderProgressView {
        guard let view = Bundle.main.loadNibNamed("ReaderProgressView", owner: nil, options: nil)?.first as? ReaderProgressView else {
            return ReaderProgressView()
        }
        
        view.readMenu = readMenu
        view.backgroundColor = .clear
        return view
    }
    
    func sliderUpdate() {
        if readMenu.vc.readModel != nil, let order = readMenu.vc.readModel.readRecordModel?.readChapterModel?.order {
            titleLabel.text = readMenu.vc.readModel.readRecordModel?.readChapterModel?.name ?? readMenu.vc.readModel.name
            let total = readMenu.vc.allLocalChapterInfo.value.count
            if total > 0 {
                progreeLabel.text =  String(format: "%.1f", ( Float(order) / Float(total) * 1.0) * 100) + "%"
                slider.value = Float(order)
                if order == 0 {
                     titleLabel.text = readMenu.vc.readModel.name
                }
            } else {
                progreeLabel.text = "0%"
            }
        }
    }
    
    /// 上一章
    @objc func preBtnAction(_ sender: UIButton) {
        readMenu.delegate.readMenuClickPreviousChapter?(readMenu: readMenu)
    }

    /// 下一章
    @objc func nextBtnAction(_ sender: UIButton) {
        readMenu.delegate.readMenuClickNextChapter?(readMenu: readMenu)
    }
    
    
    @objc private func progreesSliderAction(_ slider: UISlider, for event: UIEvent) {
        
        guard let touchEvent = event.allTouches?.first else {
            return
        }
        progreeLabel.text =  String(format: "%.1f", (slider.value / slider.maximumValue) * 100) + "%"
        switch touchEvent.phase {
        case .moved:
            readMenu.vc.progressSliderValueInput.onNext(Int(slider.value))
        case .ended:
             readMenu.vc.progressSliderLastValueInput.onNext(Int(slider.value))
        default:
            break
        }
        
    }
    
}
