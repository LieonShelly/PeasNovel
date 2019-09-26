//
//  SearchHeaderView.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/16.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RealmSwift

class SearchHeaderView: UITableViewHeaderFooterView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var clearButton: UIButton!
    
//    override func prepareForReuse() {
//        super.prepareForReuse()
//        clearButton.addTarget(self, action: #selector(clearAction(_:)), for: .touchUpInside)
//    }
//
//    override func awakeFromNib() {
//
//    }
//
//    @objc func clearAction(_ sender: Any) {
//        let realm = try! Realm()
//        let keywords = realm.objects(SearchKeyModel.self)
//
//        try! realm.write {
//            realm.delete(keywords)
//        }
//    }
}
