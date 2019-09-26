//
//  SearchHotModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/16.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import HandyJSON

class SearchHotResponse: BaseResponseArray<SearchHotData> {
    
}

class SearchHotData: Model {
    var page_info: SearchPageInfo? 
    var name: String? //": "大家都在搜",
    var sub_name: String? //": "",
    var type: String? //": "search_remenbiaoqian",
    var list: [SearchHotModel]? //":
}

class SearchHotModel: HandyJSON {
    var id: String? //": "220",
    var app_id: String? //": "82524829",
    var type_name: String? //": "search_remenbiaoqian",
    var title: String? //": "女神的妖孽保镖",
    var jump_url: String? //": "client://kanshu/book_detail?book_id=2057442",
    var is_delete: String? //": "0",
    var sort: Int = 0 //": "1",
    var edit_time: String? //": "2019-02-22 18:11:53"
    
    func mapping(mapper: HelpingMapper) {
        mapper <<<
            jump_url <-- StringPercentEndingTransform()
        
    }
    
    public required init() {}
}

class SearchPageInfo: Model {
    
    var num: Int = 0 //": "6",
    var cur_page: Int = 0 //": "1",
    var total_num: Int = 0 // ": 11,
    var total_page: Int = 0 //": 2
}
