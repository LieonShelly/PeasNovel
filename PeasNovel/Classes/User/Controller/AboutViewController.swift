//
//  AboutViewController.swift
//  ClassicalMusic
//
//  Created by weicheng wang on 2019/1/17.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift


class AboutViewController: BaseViewController {
    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var descLabel: UILabel!
    @IBOutlet weak var btn: UIButton!
    
    @IBOutlet weak var buildLabel: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        versionLabel.text = "豆豆小说" + " V" + (Bundle.main.infoDictionary!["CFBundleShortVersionString"] as? String ?? "1.0.0")
        buildLabel.text =  "BUILD " + (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "")
        btn.setTitle(NSLocalizedString("privacyAgreement", comment: ""), for: UIControl.State.normal)
        btn.rx.tap
            .mapToVoid()
            .subscribe(onNext: { [weak self] in
                let privacy = PrivacyViewController()
                self?.navigationController?.pushViewController(privacy, animated: true)
            })
            .disposed(by: bag)
        
//        descLabel.attributedText = NSLocalizedString("aboutUsDesc", comment: "").withlineSpacing(8)
    }

}
