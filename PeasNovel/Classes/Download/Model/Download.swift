//
//  Download.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/23.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import Realm
import HandyJSON
import RealmSwift

class DownloadChapterGroupResponse: BaseResponseArray<DownloadChapterGroup> { }

class DownloadChapterPayResponse: BaseResponse<DownloadChapterPay> {
    static func commonError(_ error: Error) -> DownloadChapterPayResponse {
        let response = DownloadChapterPayResponse()
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

class DownloadedBooksResponse: BaseResponseArray<DownloadedBook> { }

class DownloadChapter: Model {
    var content_id: String?
    var book_id: String?
    var title: String?
    var beans: String?
    var order: String?
}

class DownloadChapterGroup: Model {
    var id: String?
    var title: String?
    var group_beans: String?
    var chapters: [DownloadChapter]?
    var book_id: String?
    var book_title: String?
    var status: DownloadStatus = .none
    var progress: Double = 0.0
}

class DownloadChapterPay: Model {
    var book_id: String?
    var beans: String?
    var coin: String?
    var chapter_ids: String?
    
}

class DownloadedBook: Model {
    var book_id: String?
    var book_title: String?
    var author_name: String?
    var chapter_count: String?
    var cover_url: String?
    var last_chapter_title: String?
    var book_intro: String?
    var size: Double = 0
    var downloadStatus: DownloadStatus = .none
    var totalDownloadChapterCount: Int = 0
}

enum DocumenetStatus: Int {
    case normal = 1
    case delete = 0
}

class DownloadLocalBook: Object, HandyJSON {
    @objc dynamic var cover_img: String = ""
    @objc dynamic var book_title: String = ""
    @objc dynamic var book_id: String = ""
    @objc dynamic var author: String = ""
    @objc dynamic var download_chapter_count: Int = 0
    @objc dynamic var download_size: Double = 0
    @objc dynamic var dowloadStatus: Int = DownloadStatus.none.rawValue
    @objc dynamic  var status: Int = DocumenetStatus.normal.rawValue
    @objc dynamic  var create_time: Double = 111
    
    override static func primaryKey() -> String? {
        return "book_id"
    }
    
}

enum DownloadStatus: Int, HandyJSONEnum {
    case none = -1
    case fail = 0
    case success = 1
    case willDownload = 4
    case downloading = 2
    case waiting = 3
    case unlock = 5
    
    var desc: String {
        switch self {
        case .none:
            return "未知"
        case .fail:
            return "下载失败"
        case .success:
            return "已下载"
        case .downloading:
            return "下载中"
        case .waiting:
            return "等待下载"
        case .willDownload:
            return "即将下载"
        case .unlock:
            return "解锁"
        }
    }
}
