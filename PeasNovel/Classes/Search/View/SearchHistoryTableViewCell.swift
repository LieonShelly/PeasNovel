//
//  SearchHistoryTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/1.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import TagListView
import RxSwift

class SearchHistoryTableViewCell: UITableViewCell {

    @IBOutlet weak var tagListView: TagListView!
    let tagTapped: PublishSubject<String> = .init()
    
    var bag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        tagListView.textColor = UIColor(0x999999)
        tagListView.selectedTextColor = UIColor(0x999999)
        tagListView.textFont = UIFont.systemFont(ofSize: 15)
        tagListView.cornerRadius = 3
        tagListView.borderColor = UIColor(0x999999)
        tagListView.borderWidth = 1
        tagListView.paddingY = 4
        tagListView.paddingX = 8
        tagListView.marginX = 16
        tagListView.marginY = 8
        tagListView.tagBackgroundColor = UIColor.white
        tagListView.delegate = self
        selectionStyle = .none
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }
    
    func set(_ items: [SearchKeyModel]) {
        tagListView.removeAllTags()
        tagListView.addTags(items.map{ $0.keyword })
    }
}

extension SearchHistoryTableViewCell: TagListViewDelegate {
    
    func tagPressed(_ title: String, tagView: TagView, sender: TagListView) {
        tagTapped.on(.next(title))
        UIApplication.shared.keyWindow?.endEditing(true)
    }
}
