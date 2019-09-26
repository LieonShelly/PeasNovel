//
//  ReaderCoverView.swift
//  Arab
//
//  Created by lieon on 2018/11/5.
//  Copyright © 2018 kanshu.com. All rights reserved.
//

import UIKit

class ReaderCoverView: UIView {

    @IBOutlet weak var settingLabel: UILabel!
    @IBOutlet weak var leadingLabel: UILabel!
    @IBOutlet weak var trailingLabel: UILabel!
    @IBOutlet weak var sureButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        sureButton.layer.borderColor = UIColor.white.cgColor
        sureButton.layer.borderWidth = 1
        sureButton.layer.masksToBounds = true
        sureButton.layer.cornerRadius = 5
    }
    
    class func loadNib() -> ReaderCoverView? {
        let frame = UIScreen.main.bounds
        let nib = UINib(nibName: "ReaderCoverView", bundle: nil)
        guard let view = nib.instantiate(withOwner: self, options: nil).last as? ReaderCoverView else {
            return nil
        }
        view.frame = CGRect(origin: .zero, size: frame.size)
        view.sureButton.setTitle(NSLocalizedString("know", comment: ""),
                            for: .normal)
        view.leadingLabel.text = NSLocalizedString("turnleading", comment: "")
        view.settingLabel.text = NSLocalizedString("middleClick", comment: "")
        view.trailingLabel.text = NSLocalizedString("turntrailing", comment: "")
        return view
    }
    
    @IBAction func sureAction(_ sender: UIButton) {
        if self.superview != nil {
            UIView.animate(withDuration: 0.25, animations: {
                self.alpha = 0
            }, completion: { _ in
                self.removeFromSuperview()
            })
        }
    }
}
