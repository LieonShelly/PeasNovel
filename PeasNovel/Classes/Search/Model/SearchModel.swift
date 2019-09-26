//
//  SearchModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/16.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class SearchResponse: BaseResponseArray<BookInfo> {
    static func commonError(_ error: Error) -> SearchResponse {
        let response = SearchResponse()
        let status = ReponseResult()
        response.status = status
        status.code = 0
        status.msg = "遇到问题了哦"
        response.data = []
        if let error = error as? AppError {
            status.msg = error.message
        }
        return response
    }
}

class SogouResponse: BaseResponse<SogouAddModel> { }

class SogouAddModel: Model {
    var join_linkcollect: Bool = false
    var collect_title: String?
    
}
