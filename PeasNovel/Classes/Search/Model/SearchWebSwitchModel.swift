//
//  SearchWebSwitchModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/16.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class SearchWebSwitchResponse: BaseResponse<SearchWebSwitchModel> {
    
}

class SearchWebSwitchModel: Model {
    var id: String? //": "4",
    var app_id: String? //": "61096114",
    var app_version: String? //": "4.0.0",
    var enter_page: String? //": "2",
    var search: Int = 2 //": "2", 默认是2，表示开启三方搜索
    var bookcase_hlxs: String? //": "1",
    var lottery_h5_link: String? //": "https://activity.xyxsc.com/draw1?app_id=61096114&channel_id=1&version_name=1.0.0",
    var wechat: String? //": "",
    var qq: String? //": "3470657031",
    var ad_minute: String? //": "10",
    var ad_type: String? //": "2"
}
