//
//  BookSheetVerticalView.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/22.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import FSPagerView

class BookSheetVerticalView: FSPagerViewCell {

    @IBOutlet weak var readNumLabel: UILabel!
    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var introLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var readButton: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        addButton.layer.borderWidth = 5
        addButton.layer.borderColor = UIColor.theme.cgColor
        
        readButton.layer.borderWidth = 5
        readButton.layer.borderColor = UIColor.theme.cgColor
        
    }
    
    private class func loadNib() -> BookSheetVerticalView {
        let frame = UIScreen.main.bounds
        let nib = UINib(nibName: "BookSheetVerticalView", bundle: nil)
        guard let view = nib.instantiate(withOwner: self, options: nil).last as? BookSheetVerticalView else {
            fatalError()
        }
        view.frame = CGRect(origin: .zero, size: frame.size)
        return view
    }

}
