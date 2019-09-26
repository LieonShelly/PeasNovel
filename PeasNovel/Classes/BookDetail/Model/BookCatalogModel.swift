//
//  BookCatalogModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/17.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class BookCatalogResponse: BaseResponseArray<BookCatalogModel> {

}

class BookCatalogModel: Model {
    var book_id: String = "" //": "2039327",
    var content_id: String = "" //": "14968779",
    var title: String? //": "第2813章 反杀两人",
    var words_count: String? //": "3140",
    var order: String? //": "2813",
    var creator: String? //": "system",
    var createtime: String? //": "2019-04-16 09:02:07",
    var price: String? //": 15,
    var book_title: String? //": "无上神帝"
}
