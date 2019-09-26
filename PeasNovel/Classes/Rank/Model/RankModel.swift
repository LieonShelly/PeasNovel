//
//  RankModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/19.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class RankResponse: BaseResponseArray<RankModel> {
    
}

class RankModel: BookInfo {
    var collect_user: [RankUserModel]?
    var edittime: String?
}

class RankUserModel: Model {
    var user_id: String = "" //: "43744930",
    var headimgurl: String? //": "",
    var nickname: String? //": "APP22950425",
    var sex: Int = 0 //": "0"
}
