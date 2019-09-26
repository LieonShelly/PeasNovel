//
//  BookshelfModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/14.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import HandyJSON
import RealmSwift


class BookshelfInfoResponse: BaseResponse<BookshelfData> {
}

class BookshelfListResponse: BaseResponseArray<BookInfo> {
    
    static func commonError(_ error: Error) -> BookshelfListResponse {
        let response = BookshelfListResponse()
        let status = ReponseResult()
        response.status = status
        status.code = -1
        status.msg = "遇到问题了哦"
        if let error = error as? AppError {
            status.msg = error.message
        }
        response.data = []
        return response
    }
}

class BookshelfData: Model {
    var bianji_haoshu: [BookInfo]?
    var haoli_xiangsong: [BookInfo]?
    var zuijin_yuedu: [BookInfo]?
}


class ReadRecord: Object {
    @objc dynamic var book_id: String = ""
    @objc dynamic var content_id: String = ""
    @objc dynamic var book_name: String = ""
    @objc dynamic var cover_url: String = ""
    @objc dynamic var create_time: Double = Date().timeIntervalSince1970
    @objc dynamic var writing_process: Int = 0
    
    override static func primaryKey() -> String? {
        return "book_id"
    }
}

