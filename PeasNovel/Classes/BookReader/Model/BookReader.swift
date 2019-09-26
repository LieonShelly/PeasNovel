//
//  BookReader.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/12.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import HandyJSON
import RealmSwift

/// 章节内容
class ChapterContentResponse: BaseResponse<ChapterContent> {
    
    static func commonError(_ error: Error) -> ChapterContentResponse {
        let response = ChapterContentResponse()
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

/// 所有的章节信息
class AllChapterResponse: BaseResponseArray<ChapterInfo> { }

class ChapterContent: Model {
    var book_id: String = ""
    var content_id: String?
    var title: String?
    var words_count: Int32 = 0
    var order: Int32 = 0
    var creator: String?
    var createtime: String?
    var content: String?
    var price: Int32 = 0
    var first_chapter: ChapterInfo?
    var next_chapter: ChapterInfo?
    var last_chapter: ChapterInfo?
    var is_can_cache: Bool = false
    var book_info: ChapterBookInfo?
    var cp_info: ChapterCopyRightInfo?
    var is_buy: Bool = false
    var is_user_payed: Bool = false
    

}


class ChapterInfo:  NSObject, NSCoding, HandyJSON  {
    var content_id: String?
    var title: String?
    var words_count: String?
    var order: String?
    var book_id: String?
    var price: String?
    
    required override init() { }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(content_id, forKey: "content_id")
        aCoder.encode(title, forKey: "title")
        aCoder.encode(words_count, forKey: "words_count")
        aCoder.encode(order, forKey: "order")
        aCoder.encode(book_id, forKey: "book_id")
        aCoder.encode(price, forKey: "price")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init()
        content_id = aDecoder.decodeObject(forKey: "content_id")  as? String
        title = aDecoder.decodeObject(forKey: "title")  as? String
        words_count = aDecoder.decodeObject(forKey: "words_count") as? String
        book_id = aDecoder.decodeObject(forKey: "book_id") as? String
        price = aDecoder.decodeObject(forKey: "price") as? String
    }
}

class ChapterBookInfo: NSObject, NSCoding, HandyJSON {
    var book_id: String?
    var book_title: String?
    var book_title_spell: String?
    var author_id: String?
    var author_name: String?
    var is_delete: String?
    var is_online: String?
    var chapter_count: String?
    var cover_url: String?
    var last_chapter_title: String?
    var is_free: String?
    var channel_id: String?
    var writing_process: String?
    var category_id_1: String?
    var category_id_2: String?
    var book_intro: String?
    var word_count: String?
    var c_order: String?
    var content_id: String?
    var join_bookcase: String?
    
    required override init() { }
    
    required init?(coder aDecoder: NSCoder) {
        super.init()
        book_title = aDecoder.decodeObject(forKey: "book_title")  as? String
        book_id = aDecoder.decodeObject(forKey: "book_id")  as? String
        book_title_spell = aDecoder.decodeObject(forKey: "book_title_spell") as? String
        author_id = aDecoder.decodeObject(forKey: "author_id") as? String
        author_name = aDecoder.decodeObject(forKey: "author_name")  as? String
        is_delete = aDecoder.decodeObject(forKey: "is_delete")  as? String
        is_online = aDecoder.decodeObject(forKey: "is_online") as? String
        chapter_count = aDecoder.decodeObject(forKey: "chapter_count") as? String
        cover_url = aDecoder.decodeObject(forKey: "cover_url")  as? String
        last_chapter_title = aDecoder.decodeObject(forKey: "last_chapter_title")  as? String
        is_free = aDecoder.decodeObject(forKey: "is_free") as? String
        writing_process = aDecoder.decodeObject(forKey: "writing_process") as? String
        category_id_1 = aDecoder.decodeObject(forKey: "category_id_1")  as? String
        category_id_2 = aDecoder.decodeObject(forKey: "category_id_2")  as? String
        book_intro = aDecoder.decodeObject(forKey: "book_intro") as? String
        word_count = aDecoder.decodeObject(forKey: "word_count") as? String
        c_order = aDecoder.decodeObject(forKey: "c_order")  as? String
        content_id = aDecoder.decodeObject(forKey: "content_id") as? String
        join_bookcase = aDecoder.decodeObject(forKey: "join_bookcase") as? String
       
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(book_title, forKey: "book_title")
        aCoder.encode(book_id, forKey: "book_id")
        aCoder.encode(book_title_spell, forKey: "book_title_spell")
        aCoder.encode(author_id, forKey: "author_id")
        aCoder.encode(author_name, forKey: "author_name")
        aCoder.encode(is_delete, forKey: "is_delete")
        aCoder.encode(is_online, forKey: "is_online")
        aCoder.encode(chapter_count, forKey: "chapter_count")
        aCoder.encode(cover_url, forKey: "cover_url")
        aCoder.encode(last_chapter_title, forKey: "last_chapter_title")
        aCoder.encode(is_free, forKey: "is_free")
        aCoder.encode(writing_process, forKey: "writing_process")
        aCoder.encode(category_id_1, forKey: "category_id_1")
        aCoder.encode(category_id_2, forKey: "category_id_2")
        aCoder.encode(book_intro, forKey: "book_intro")
        aCoder.encode(word_count, forKey: "word_count")
        aCoder.encode(c_order, forKey: "c_order")
        aCoder.encode(content_id, forKey: "content_id")
        aCoder.encode(join_bookcase, forKey: "join_bookcase")
        
    }
    
}


class ChapterCopyRightInfo: NSObject, NSCoding, HandyJSON  {
    
    var book_title: String?
    var author: String?
    var shelves_time: String?
    var origin_company: String?
    var target_company: String?
    var detail_text: String?
    var read_text: String?
    
    required override init() { }
    
    required init?(coder aDecoder: NSCoder) {
        super.init()
        book_title = aDecoder.decodeObject(forKey: "book_title")  as? String
        author = aDecoder.decodeObject(forKey: "author")  as? String
        shelves_time = aDecoder.decodeObject(forKey: "shelves_time")  as? String
        origin_company = aDecoder.decodeObject(forKey: "origin_company")  as? String
        target_company = aDecoder.decodeObject(forKey: "target_company")  as? String
        detail_text = aDecoder.decodeObject(forKey: "detail_text")  as? String
        read_text = aDecoder.decodeObject(forKey: "read_text")  as? String
    }
    
    func encode(with aCoder: NSCoder) {
        aCoder.encode(book_title, forKey: "book_title")
        aCoder.encode(author, forKey: "author")
        aCoder.encode(origin_company, forKey: "origin_company")
        aCoder.encode(target_company, forKey: "target_company")
        aCoder.encode(detail_text, forKey: "detail_text")
        aCoder.encode(read_text, forKey: "read_text")
    }
    
    convenience init( _ bookLiscense: BookLicense) {
        self.init()
        self.book_title = bookLiscense.book_title
        self.author = bookLiscense.author
        self.shelves_time = bookLiscense.shelves_time
        self.origin_company = bookLiscense.origin_company
        self.target_company = bookLiscense.target_company
        self.detail_text = bookLiscense.detail_text
        self.read_text = bookLiscense.read_text
    }
}

//
//struct ChapterDetailResponse: HandyJSON {
//    var code = 0
//    var msg: String?
//    var data: ChapterDetailModel?
//    var chargeInfo: NovelChargeInfo?
//    
//    mutating func mapping(mapper: HelpingMapper) {
//        mapper <<<
//            self.chargeInfo <-- "data"
//    }
//}
//
//struct ChapterDetailModel: HandyJSON {
//    
//    var content_id: String = ""
//    var title: String?
//    var book_title: String?
//    var words_count: Int32 = 0
//    var book_id: String = ""
//    var order: Int32 = 0
//    var content: String?
//    var price: Int32 = 0
//    var prev_chapter: SubChapterModel?
//    var next_chapter: SubChapterModel?
//}
//
class NovelChargeInfo: NSObject, NSCoding, HandyJSON {
    var is_charge = false
    var join_tribe = false
    var join_wish = false
    var sortorder: Int32 = 0
    var chapter_title: String?
    var chapter_id: String = ""
    var pay_money: Int32 = 0
    var book_title: String?
    var book_id: String = ""
    var chapter_count: Int = 0
    
    required override init() { }
    
    required init?(coder aDecoder: NSCoder) {
        super.init()
        
        is_charge = aDecoder.decodeBool(forKey: "is_charge")
        join_tribe = aDecoder.decodeBool(forKey: "join_tribe")
        join_wish = aDecoder.decodeBool(forKey: "join_wish")
        sortorder = aDecoder.decodeInt32(forKey: "sortorder")
        chapter_id = aDecoder.decodeObject(forKey: "chapter_id") as! String
        pay_money = aDecoder.decodeInt32(forKey: "pay_money")
        book_title = aDecoder.decodeObject(forKey: "book_title")  as? String
        chapter_title = aDecoder.decodeObject(forKey: "chapter_title") as? String
        book_id = aDecoder.decodeObject(forKey: "book_id")  as! String
        chapter_count = aDecoder.decodeInteger(forKey: "chapter_count")
    }
    
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(is_charge, forKey: "is_charge")
        aCoder.encode(join_tribe, forKey: "join_tribe")
        aCoder.encode(join_wish, forKey: "join_wish")
        aCoder.encode(sortorder, forKey: "sortorder")
        aCoder.encode(chapter_id, forKey: "chapter_id")
        aCoder.encode(pay_money, forKey: "pay_money")
        aCoder.encode(book_title, forKey: "book_title")
        aCoder.encode(book_id, forKey: "book_id")
        aCoder.encode(chapter_count, forKey: "chapter_count")
        aCoder.encode(chapter_title, forKey: "chapter_title")
    }
    
    
}

struct SubChapterModel: HandyJSON {
    var content_id: String = ""
    var title: String?
    var words_count: String = ""
    var book_id: String = ""
    var order: String = ""
}



struct CatalogResponse: HandyJSON {
    var code = 0
    var msg: String?
    var data: CatalogData?
    
}

struct CatalogData: HandyJSON {
    var page = 0
    var num = 0
    var total = 0
    var total_page = 0
    var lists: [CatalogModel]?
    var user_read: CatalogUserRead?
    
    mutating func didFinishMapping() {
        guard var lists = lists else { return }
        for (idx, model) in lists.enumerated() {
            if model.content_id == user_read?.chapter_id {
                var curr = model
                curr.isCurr = true
                lists[idx] = curr
                break
            }
        }
        self.lists = lists
    }
}

struct CatalogModel: HandyJSON {
    var content_id: String = ""
    var book_id: String = ""
    var title: String?
    var words_count:Int32 = 0
    var order:Int32 = 0
    var price: Int32 = 0
    var is_buy: Bool = false
    var isCurr: Bool = false
    
    /// 漫画目录数据结构
    var status = 0
    var sortorder = 0
    var create_time = 0
    var is_lock = 0
    
    mutating func mapping(mapper: HelpingMapper) {
        mapper >>> self.isCurr
        
        mapper <<<
            self.title <-- ["title", "ch_title"]
        mapper <<<
            self.content_id <-- ["content_id", "sortorder"]
        mapper <<<
            self.price <-- ["price", "is_lock"]
    }
    
    
}

struct CatalogUserRead: HandyJSON {
    var id: String = ""
    var user_id: String?
    var book_id: String = ""
    var chapter_id: String = ""
    var book_title: String?
    var chapter_title: String?

}

/// 一本书的有效阅读时长，用于在阅读器内统计，进入阅读器，值清空
class OneBookReadingTime: Object {
    @objc dynamic var id: String = Constant.AppConfig.bundleID
    @objc dynamic var readingDuration: Double = 0
    @objc dynamic var createTime: Double = Date().timeIntervalSince1970
    
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
}

/// 每隔一段时间的阅读时长,  弹出全屏广告后清0
class FullScreenBookReadingTime: Object {
    @objc dynamic var id: String = Constant.AppConfig.bundleID
    @objc dynamic var readingDuration: Double = 0
    @objc dynamic var createTime: Double = Date().timeIntervalSince1970
    
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
}


class LocalReaderChapterInfo: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var content_id: String = ""
    @objc dynamic var title: String = ""
    @objc dynamic var order: NSInteger = 0
    @objc dynamic var book_id: String = ""
    @objc dynamic var words_count: String = "0"
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    convenience init(_ chapterInfo: ChapterInfo) {
        self.init()
        self.id = (chapterInfo.book_id ?? "") + (chapterInfo.content_id ?? "")
        self.content_id = chapterInfo.content_id ?? ""
        self.title = chapterInfo.title ?? ""
        self.order = Int(chapterInfo.order ?? "0") ?? 0
        self.book_id = chapterInfo.book_id ?? ""
        self.words_count = chapterInfo.words_count ?? ""
    }
}


class ChapterTailBookResponse: BaseResponse<BookInfo> { }

class ListenBookServerResponse: BaseResponse<ListenBookServerData> { }

class SogouKeywordResponse: BaseResponse<SogouKeywordData> { }

class SogouKeywordData: Model {
    var prepage_num: Int = 0
    var keywords: [SogouKeyword]?
}

class SogouKeyword: Model {
    var content: String?
    var url: String?
    
    func mapping(mapper: HelpingMapper) {
        mapper <<<
            url <-- StringPercentEndingTransform()
        
    }
}



class ListenBookServerData: Model {
    var ad: UserAdvertiseInfo?
    var listen: UserAdvertiseInfo?
    var cur_time: Int?
}

class LocalBookLatestCateLog: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var content_id: String = ""
    @objc dynamic var book_id: String = ""
    @objc dynamic var title: String?
    @objc dynamic var words_count:String = ""
    @objc dynamic var order: String = ""
    
    override static func primaryKey() -> String {
        return "id"
    }
    
    convenience init(_ serverData: BookCatalogModel) {
        self.init()
        self.id = serverData.book_id
        self.content_id = serverData.content_id
        self.title = serverData.title
        self.words_count = serverData.words_count ?? ""
        self.order = serverData.order ?? ""
    }
}
