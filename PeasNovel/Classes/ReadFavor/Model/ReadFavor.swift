//
//  ReadFavor.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/9.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import HandyJSON

///  分类信息
class ReadFavorResponse: BaseResponseArray<CategoryGroup> {
    static func commonError(_ error: Error) -> ReadFavorResponse {
        let response = ReadFavorResponse()
        let status = ReponseResult()
        response.status = status
        status.code = -1
        status.msg = "遇到问题了哦"
        response.data = []
        if let error = error as? AppError {
            status.msg = error.message
        }
        return response
    }
}

/// 获取用户设定
class UserReadFavorResponse: BaseResponseArray<Category> { }

class Category: Model {
    var id: String?
    var category_id_1: String?
    var category_id_2: String?
    var name: String?
    var short_name: String?
    var pvuv_key: String?
    var isSelected: Bool = false
    var category_img: String?
    var category_id: String?
    var sex: Int?
}

class CategoryGroup: Model {
    var name: String?
    var category: [Category]?
}
