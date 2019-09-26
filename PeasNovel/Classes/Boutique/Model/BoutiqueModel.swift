//
//  BoutiqueModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/14.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import HandyJSON

class BoutiqueResponse: BaseResponseArray<BoutiqueModel> {
    
}

class BoutiqueModel: HandyJSON {
    
    var id: Int = 0 //:String? //": "17",
    var boutique_title: String? //:String? //": "标题1活动2",
    var boutique_img: String? //:String? //": "https://file.kxxsc.com/upload/tmp/2017-08/c4bd25661fc17e2a0e5dd9d5360889e9.jpg",
    var boutique_intro: String? //:String? //": "简介7",
    var sortorder: Int32 = 0
    var recommend_word: String? //:String? //": "关键词7",
    var type_id: String? //:String? //": "3",
    var app_id: String? //:String? //": "82524829",
    var jump_url: String? //:String? //": "client://kanshu/book_menu_list?id=7&title=七期 腹黑总裁霸上我"

    func mapping(mapper: HelpingMapper) {
        mapper <<<
            jump_url <-- StringPercentEndingTransform()
        
    }
    
    public required init() {}
}
