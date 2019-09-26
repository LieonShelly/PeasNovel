//
//  SearchKeyModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/23.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import HandyJSON
import RealmSwift

struct SearchKeyList: HandyJSON {
    var list: [SearchKeyModel]?
    
    mutating func add(_ model: SearchKeyModel, update: Bool = false) {
        if let index = list?.index(where: { $0.keyword == model.keyword }) {
            self.list?[index].date = Date()
        }else{
            self.list?.append(model)
        }
    }
}

class SearchKeyModel: Object {
    
    @objc dynamic var keyword: String = ""
    @objc dynamic var date: Date = Date()
    
    override static func primaryKey() -> String? {
        return "keyword"
    }
    
    convenience init(_ keyword: String) {
        self.init() // 请注意这里使用的是 'self' 而不是 'super'
        self.keyword = keyword
    }
}
