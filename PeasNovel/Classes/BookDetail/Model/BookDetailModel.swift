//
//  BookDetailModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/12.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import HandyJSON

class BookDetailResponse: BaseResponse<BookDetailModel> { }

class BookUpdateResponse: BaseResponse<BookUpdateModel> {}

class BookUpdateModel: Model {
    var id: String?
    var book_id: String?
    var send_num: String?
    var last_send_time: String?
}

class BookDetailModel: Model {
    
    var book_info: BookInfo?
    var last_chapter_info: BookChapterInfo?
    var like_book: [BookInfoSimple]?
    var like_shudan: [BookSheetModel]?// [BookSheet]?
    var cp_info: BookLicense?
    var isAddBookNoti: Bool = false
    
}

enum BookStatus: Int {
    
    case serializing = 0
    case completion = 1
    
    var desc: String {
        switch self {
        case .serializing:
            return "连载"
        case .completion:
            return "完结"
        }
    }
    
}

extension BookStatus: HandyJSONEnum {
//    var desc
    
}

//extension BookStatus: LocalizedError {
//
//}

class BookInfo: HandyJSON {
    var is_online: String?
    var book_id: String = "" //: String? // "2039327",
    var book_title: String? //: String? // "无上神帝",
    var book_intro: String? //: String? // "万千大世界，强者如林。\r\n一代仙王牧云，重生到一个备受欺凌的私生子身上，誓要搅动风云，重回巅峰。\r\n苍茫天域，谁与争锋？\r\n诸天万界，我主沉浮！\r\n这一世，牧云注定要掌御万界，斗破苍穹！",
    var cover_url: String? //: String? // "https://res.kxxsc.com/upload/tmp/2018-03/b4b570ff7babaecdaf4eb0349d8fb362.jpg",
    var word_count: Int = 0 //: String? // "9179481",
    var chapter_count: Int = 0 //: String? // "2803",
    var author_id: String? //: String? // "111385446",
    var author_name: String? //: String? // "蜗牛狂奔",
    var writing_process: BookStatus = .serializing //: String? // "0",
    var last_chapter_time = Date() //: String? // "2019-04-11 13:51:40",
    var last_chapter_date: String?
    var total_reward_num: String? //: String? // "0",
    var total_click_num: Int = 0 //: String? // "435667",
    var week_click_num: Int = 0
    var week_collect_num: Int = 0
    var total_comment_num: String? //: String? // "323",
    var site: String? //: String? // "1",
    var category_id_1: BookTag?
    var category_id_2: BookTag?
    var total_collect_num: Int = 0 //: String? // "6931",
    var is_free: String? //: String? // "0",
    var channel_id: String? //: String? // "118243657",
    var create_time: String? //: String? // "2018-03-06 13:58:31",
    var join_bookcase: Bool = false // "0",
    var c_order: String? //: String? // "44",
    var content_id: String? //: String? // "8157726",
    var is_reading: String? //: String? // "1",
    var last_content_id: String? //: String? // "8157726"
    
    // 书单字段
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
    var source: String? //": "doudoumianfeixiaoshuo_ios",
    var join_time: String? //": "2019-04-17 14:28:52",
    var book_type: Int = 0 //": "2"
    var link: String?
    var isSelected: Bool = false
    var localTempAdConfig: LocalTempAdConfig?
    
    /// 当前书籍是否更新
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

    public required init() {
        
    }
    
    convenience init(_ localRecord: ReadRecord) {
        self.init()
        self.book_id = localRecord.book_id
        self.content_id = localRecord.content_id
        self.book_title = localRecord.book_name
        self.cover_url = localRecord.cover_url
        self.writing_process = BookStatus(rawValue: localRecord.writing_process) ?? .serializing
    }
    
    func mapping(mapper: HelpingMapper) {
        mapper >>> isSelected
        
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
    
    class func didSelected(for bookId: String, date: Date) {
        let currTimestamp = Int(date.timeIntervalSince1970)
        UserDefaults.standard.set(currTimestamp, forKey: bookId)
        UserDefaults.standard.synchronize()
    }
    
}

class BookInfoSimple: Model {
    
    var book_id: String = ""
    var book_title: String?
    var cover_url: String?
    var author_id: String?
    var author_name: String?
    var writing_process: BookStatus = .serializing
    var total_click_num: Int = 0
    var site: String?
    var category_id_1: BookTag?
    var category_id_2: BookTag?
    var book_intro: String?
}

class BookChapterInfo: Model {
    var book_id: String? //: String? // "2039327",
    var content_id: String? //: String? // "14954945",
    var title: String? //: String? // "第2803章 零七章 让我们继续打劫",
    var words_count: Int = 0
    var order: String?//: String? // "2803",
    var creator: String? //: String? // "system",
    var createtime: String? //: String? // "2019-04-11",
    var price: Int = 0
}

class BookTag: Model {
    var category_id: String = ""
    var site: String?
    var level: String?
    var parent_id: String?
    var name: String?
    var short_name: String?
}

class BookLicense: Model {
    var book_title: String? //: String? // "无上神帝",
    var author: String? //: String? // "蜗牛狂奔",
    var shelves_time: String? //: String? // "2018-03-06 13:58:31",
    var origin_company: String? //: String? // "杭州作客文化传媒有限公司",
    var target_company: String? //: String? // "北京友和卓谊信息技术有限公司",
    var detail_text: String? //: String? // "免责声明：本页面由“杭州作客文化传媒有限公司”提供，并由其授权北京友和卓谊信息技术有限公司制作发布，若书中含有不良信息，请书友积极告知客服。",
    var read_text: String? //: String? // "本书由杭州作客文化传媒有限公司公司授权<br/>北京友和卓谊信息技术有限公司电子版制作与发布"
}

