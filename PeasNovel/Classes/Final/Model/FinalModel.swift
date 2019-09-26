//
//  FinalModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/18.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class FinalResponse: BaseResponseArray<FinalData> {
    static func commonError(_ error: Error) -> FinalResponse {
        let response = FinalResponse()
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

class FinalData: Model {
    var page_info: SearchPageInfo?
    var name: String? //": "经典完结",
    var sub_name: String? //": "",
    var type: String? //": "jingxuan_nanpinjingdianwanben",
    var list: [BookInfo] = [BookInfo]() //":
}
