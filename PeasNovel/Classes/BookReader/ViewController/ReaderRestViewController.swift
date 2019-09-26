//
//  ReaderRestViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/6/11.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RealmSwift

class ReaderRestViewController: BaseViewController {
    @IBOutlet weak var cancleBtn: UIButton!
    @IBOutlet weak var faceBtn: UIButton!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var contactLabel: UILabel!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var contactBtn: UIButton!
    var enterAction: (() -> Void)?
    var cancleAction: (() -> Void)?
    var forceAction: (() -> Void)?
    var closeAction: (() -> Void)?
    override func viewDidLoad() {
        super.viewDidLoad()
        let enterAction = self.enterAction
        let cancleAction = self.cancleAction
        let forceAction = self.forceAction
        let closeAction = self.closeAction
        
        cancleBtn.layer.cornerRadius = 21
        cancleBtn.layer.borderColor = UIColor.theme.cgColor
        cancleBtn.layer.borderWidth = 1
        containerView.layer.cornerRadius = 4
        containerView.layer.masksToBounds = true
        contactBtn.layer.cornerRadius = 21
        contactBtn.layer.masksToBounds = true
        faceBtn.layer.cornerRadius = 21
        faceBtn.layer.masksToBounds = true
        contactBtn.setTitleColor(UIColor.white, for: .normal)
        faceBtn.setTitleColor(UIColor.white, for: .normal)
        closeBtn.rx.tap.mapToVoid()
            .subscribe(onNext: { (_) in
                self.dismiss(animated: true, completion: closeAction)
            })
            .disposed(by: bag)
       
        contactBtn.rx.tap.mapToVoid()
            .subscribe(onNext: { (_) in
                self.dismiss(animated: true, completion: enterAction)
            })
            .disposed(by: bag)
        
        cancleBtn.rx.tap.mapToVoid()
            .subscribe(onNext: { (_) in
                self.dismiss(animated: true, completion: cancleAction)
            })
            .disposed(by: bag)
        
        faceBtn.rx.tap.mapToVoid()
            .subscribe(onNext: { (_) in
                self.dismiss(animated: true, completion: forceAction)
            })
            .disposed(by: bag)
        
        /// 弹出之后，清空数据
        let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
        let record = FullScreenBookReadingTime()
        try? realm.write {
            realm.add(record, update: .all)
        }
    }


}
