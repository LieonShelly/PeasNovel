//
//  BookSheetModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/17.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import HandyJSON

class BookSheetResponse: BaseResponseArray<BookSheetModel> {
    static func commonError(_ error: Error) -> BookSheetResponse {
        let response = BookSheetResponse()
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

class BookSheetDetailResponse: BaseResponse<BookSheetModel> {
    static func commonError(_ error: Error) -> BookSheetDetailResponse {
        let response = BookSheetDetailResponse()
        let status = ReponseResult()
        response.status = status
        status.code = -1
        status.msg = "遇到问题了哦"
        if let error = error as? AppError {
            status.msg = error.message
        }
        return response
    }
}

class BookSheetModel: HandyJSON {
    
    var id: String = "" //": "266048028",
    var boutique_title: String? //": "三百六十行，行行可风流",
    var book_num: Int = 0 //": 6,
    var boutique_intro: String? //": "铁拳所向，试问谁可争锋？ 义胆柔情，各色美人争宠！",
    var sortorder: String? //": "1",
    var type_id: String? //": "4",
    var app_id: String? //": "82524829",
    var boutique_img: String? //": "http://file.momoyue.cn/upload/tmp/2019-04/b0bc38a211f517f0eed6df677b61e46a.png",
    var jump_url: String? //": "client://kanshu/book_menu_horizontal_list?id=26&title=三百六十行，行行可风流",
    var book_lists: [BookSheetListModel]?
    var user_id: String? //": "44900273",
    var book_id: String = "" //": "26",
    var source: String? //": "doudoumianfeixiaoshuo_ios",
    var join_time: String? //": "2019-04-17 14:28:52",
    var book_type: Int = 0 //": "2"
    var category_short_name: String?
    var category_name: String?
    var is_case: Bool = false
    
    func mapping(mapper: HelpingMapper) {
        mapper <<<
            jump_url <-- StringPercentEndingTransform()
        
    }
    
    public required init() {}

}

class BookSheetListModel: HandyJSON {
    
    public required init() {
        
    }
    
    var app_id: String? //": "82524829",
    var book_id: String = "" //": "2036714",
    var book_title: String? //": "史上第一昏君",
    var cover_url: String? //": "https://res.kxxsc.com/upload/tmp/2018-01/dbd951e133d4d3cb0280a363511ba186.jpg",
    var last_chapter_id: String? //": "12189266",
    var last_chapter_title: String? //": "大昏君",
    var last_chapter_time: Date = Date() //": "2018-09-30 18:20:30",
    var c_order: String? //": 1,
    var content_id: String = "" //": "",
    var update_time: TimeInterval = 0 //": 1538302830
    var book_intro: String?
    var author_name: String?
    var writing_process: BookStatus?
    var category_name: String?
    var total_click_num: Int = 0
    var is_case: Bool = false
    var read_info_title: String?
    
    var isUpdate: Bool {
        get {
            let timestamp = UserDefaults.standard.integer(forKey: book_id)
            if timestamp == 0 {
                return false
            }else if timestamp < Int(last_chapter_time.timeIntervalSince1970) {
                return true
            }else{
                return false
            }
        }
    }
    
    func mapping(mapper: HelpingMapper) {
        mapper <<<
            last_chapter_time <-- CustomDateFormatTransform(formatString: "yyyy-MM-dd HH:mm:ss")
    }
    
    func didFinishMapping() {
        let timestamp = UserDefaults.standard.integer(forKey: book_id)
        if timestamp == 0 {
            let currTimestamp = Int(last_chapter_time.timeIntervalSince1970)
            UserDefaults.standard.set(currTimestamp, forKey: book_id)
            UserDefaults.standard.synchronize()
        }
    }
    
}
