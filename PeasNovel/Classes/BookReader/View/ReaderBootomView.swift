//
//  ReaderBootomView.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/12.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class ReaderBootomView: UIView {

    @IBOutlet weak var top: NSLayoutConstraint!
    @IBOutlet weak var progresstBtn: UIButton!
    
    @IBOutlet weak var ligghtBtn: UIButton!
    
    @IBOutlet weak var bookMarkBtn: UIButton!
    
    @IBOutlet weak var settingBtn: UIButton!
    
    /// 菜单
    weak var readMenu: ReaderMenuController!
    
    override func awakeFromNib() {
        super.awakeFromNib()
            settingBtn.addTarget(self, action: #selector(clickSetup(_:)), for: UIControl.Event.touchUpInside)
            ligghtBtn.addTarget(self, action: #selector(ligghtBtnAction(_:)), for: UIControl.Event.touchUpInside)
            progresstBtn.addTarget(self, action: #selector(progressBtnAction(_:)), for: UIControl.Event.touchUpInside)
            bookMarkBtn.addTarget(self, action: #selector(bookMarkBtnAction(_:)), for: UIControl.Event.touchUpInside)
        top.constant = UIDevice.current.isiPhoneXSeries ? 10: 0
    }
    
    static func loadView(readMenu: ReaderMenuController) -> ReaderBootomView {
        guard let view = Bundle.main.loadNibNamed("ReaderBootomView", owner: nil, options: nil)?.first as? ReaderBootomView else {
            return ReaderBootomView()
        }
        view.readMenu = readMenu
        view.backgroundColor = UIColor.menu
        return view
    }
    
 
    func setSelected(_ isSelected: Bool) {
        ligghtBtn.isSelected = isSelected
        progresstBtn.isSelected = isSelected
        settingBtn.isSelected = isSelected
        bookMarkBtn.isSelected = isSelected
    }
    
    /// 设置
  @objc func clickSetup(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        ligghtBtn.isSelected = false
        progresstBtn.isSelected = false
        bookMarkBtn.isSelected = false
        readMenu.novelsSettingView(isShow: sender.isSelected , complete: nil)
    
    }
    
    /// 亮度View
    @objc func ligghtBtnAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        progresstBtn.isSelected = false
        settingBtn.isSelected = false
        bookMarkBtn.isSelected = false
        readMenu.lightView(isShow: sender.isSelected, complete: nil)
    }
    
    /// 进度View
    @objc func progressBtnAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        ligghtBtn.isSelected = false
        settingBtn.isSelected = false
        bookMarkBtn.isSelected = false
        readMenu.progressView(isShow: sender.isSelected, complete: nil)
    }
    
    
    /// 书签View
    @objc func bookMarkBtnAction(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        progresstBtn.isSelected = false
        settingBtn.isSelected = false
        ligghtBtn.isSelected = false
        readMenu.bookMarkView(isShow: sender.isSelected, complete: nil)
    }
    
   
    
}
