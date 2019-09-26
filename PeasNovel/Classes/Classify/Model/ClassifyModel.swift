//
//  ClassifyModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/21.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class ClassifyResponse: BaseResponseArray<ClassifyData> {
}

class ClassifyModelReponse: BaseResponse<ClassifyModel> {
}

class ClassifyData: Model {
    var page_info: SearchPageInfo?
    var name: String? //": "男频",
    var sub_name: String? //": "",
    var type: String? //": "jingxuan_nanpinfenlei",
    var list: [ClassifyModel]? //": [
}
    
class ClassifyModel: Model {
    var category_id: String? //": "38",
    var site: String? //": "1",
    var level: String? //": "2",
    var parent_id: String? //": "7",
    var name: String? //": "灵异惊悚",
    var short_name: String? //": "灵异",
    var category_img: String? //": ""
    var next_category: [ClassifyModel]?
}
