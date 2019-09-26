//
//  ContactServiceAlertViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/25.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift

class ContactServiceAlertViewController: BaseViewController {
    @IBOutlet weak var cancleBtn: UIButton!
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var contactLabel: UILabel!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var contactBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        cancleBtn.layer.cornerRadius = 21
        cancleBtn.layer.borderColor = UIColor.theme.cgColor
        cancleBtn.layer.borderWidth = 1
        containerView.layer.cornerRadius = 4
        containerView.layer.masksToBounds = true
        closeBtn.layer.cornerRadius = 21
        closeBtn.layer.masksToBounds = true
        contactBtn.layer.cornerRadius = 21
        contactBtn.layer.masksToBounds = true
        contactBtn.setTitleColor(UIColor.white, for: .normal)
        closeBtn.rx.tap.mapToVoid()
            .subscribe(onNext: { (_) in
                self.dismiss(animated: true, completion: nil)
            })
            .disposed(by: bag)
        
        cancleBtn.rx.tap.mapToVoid()
            .subscribe(onNext: { (_) in
                self.dismiss(animated: true, completion: nil)
            })
            .disposed(by: bag)
        
        if let switcher =  CommomData.share.switcherConfig.value, let  attributeText = contactLabel.attributedText {
           let wechatStr = switcher.wechat ?? ""
            
            let newText = NSMutableAttributedString(attributedString: attributeText)
            let wechatAttrtext = NSMutableAttributedString(string: wechatStr)
            wechatAttrtext.setAttributes([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15)], range: NSRange(location: 0, length: wechatStr.count))
                wechatAttrtext.setAttributes([NSAttributedString.Key.foregroundColor : UIColor(0xFF5A41)], range: NSRange(location: 0, length: wechatStr.count))

            let wechatAttrtext1 = NSMutableAttributedString(string: "->点击")
            wechatAttrtext1.setAttributes([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15)], range: NSRange(location: 0, length: wechatAttrtext1.string.count))
            wechatAttrtext1.setAttributes([NSAttributedString.Key.foregroundColor : UIColor(0x999999)], range: NSRange(location: 0, length: wechatAttrtext1.string.count))
            
            let wechatAttrtext2 = NSMutableAttributedString(string: "搜索")
            wechatAttrtext2.setAttributes([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15)], range: NSRange(location: 0, length: wechatAttrtext2.string.count))
            wechatAttrtext2.setAttributes([NSAttributedString.Key.foregroundColor : UIColor(0xFF5A41)], range: NSRange(location: 0, length: wechatAttrtext2.string.count))
            
            let wechatAttrtext3 = NSMutableAttributedString(string: "即可发消息")
            wechatAttrtext3.setAttributes([NSAttributedString.Key.font : UIFont.systemFont(ofSize: 15)], range: NSRange(location: 0, length: wechatAttrtext3.string.count))
            wechatAttrtext3.setAttributes([NSAttributedString.Key.foregroundColor : UIColor(0x999999)], range: NSRange(location: 0, length: wechatAttrtext3.string.count))

            newText.append(wechatAttrtext)
            newText.append(wechatAttrtext1)
            newText.append(wechatAttrtext2)
            newText.append(wechatAttrtext3)
            contactLabel.attributedText = newText
            
            contactBtn.rx.tap.mapToVoid()
                .subscribe(onNext: { _ in
                    let pasteboard = UIPasteboard.general
                    pasteboard.string = wechatStr
                    if let wechaURL = URL(string: "weixin://"), UIApplication.shared.canOpenURL(wechaURL) {
                        UIApplication.shared.open(wechaURL)
                    } else {
                        DefaultWireframe.presentAlert(title: "未安装微信", message: "")
                    }
                })
                .disposed(by: bag)
            
        }
    }

}
