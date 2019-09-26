//
//  PlaceholderView.swift
//  Arab
//
//  Created by lieon on 2018/10/24.
//  Copyright © 2018 kanshu.com. All rights reserved.
//

import UIKit

class PlaceholderView: UIView {

    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var infoLabel: UILabel!
    @IBOutlet weak var button: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        button.layer.cornerRadius = 5
        button.layer.masksToBounds = true
        button.layer.borderColor = UIColor.theme.cgColor
        button.layer.borderWidth = 1
    }
    
    private class func loadNib() -> PlaceholderView {
        let frame = UIScreen.main.bounds
        guard let view = Bundle.main.loadNibNamed("PlaceholderView", owner: nil, options: nil)?.first as? PlaceholderView else {
            fatalError()
        }
        view.button.isHidden = true
        view.frame = CGRect(origin: .zero, size: frame.size)
        return view
    }
    /// config error view.
    class func error(_ error: Error?, placeholder: UIImage? = nil) -> PlaceholderView {
        let view = PlaceholderView.loadNib()
        
        if let error = error {
            view.infoLabel.text = error.localizedDescription
        }
        if let placeholder = placeholder {
            view.coverImageView.image = placeholder
        }else{
            view.coverImageView.image = UIImage(named: "img_exception")
        }
        
        return view
    }
    /// config empty view
    class func empty(_ text: String?, placeholder: UIImage? = nil) -> PlaceholderView {
        let empty = PlaceholderView.loadNib()
        if let text = text {
            empty.infoLabel.text = text
        }
        if let placeholder = placeholder {
            empty.coverImageView.image = placeholder
        }
        return empty
    }
    /// 重新加载数据
    func reload(_ text: String?, error: Error? = nil, placeholder: UIImage? = nil) {
        if let text = text {
            infoLabel.text = text
        }
        if let error = error {
            infoLabel.text = error.localizedDescription
        }
        if let placeholder = placeholder {
            coverImageView.image = placeholder
        }
    }
    /// add button action
    func addTarget(_ target: Any?, action:Selector) {
        guard let target = target else {
            return
        }
        button.isHidden = false
        button.addTarget(target, action: action, for: .touchUpInside)
    }
    
}
