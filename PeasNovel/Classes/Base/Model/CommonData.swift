//
//  CommonData.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/25.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RxSwift
import RealmSwift
import HandyJSON
import RxCocoa

class CommomData {
    static let share: CommomData = CommomData()
    var switcherConfig: BehaviorRelay<SwitcherConfig?> = .init(value: nil)
    var sogouKeywords: BehaviorRelay<[SogouKeyword]> = .init(value: [])
    var sogouKeywordsPrePageNum: BehaviorRelay<Int> = .init(value: 0)
    
    private init() {
       
    }
    
}

class SwitcherConfigResponse: BaseResponse<SwitcherConfig> { }

class SwitcherConfig: Model {
    var id: String?
    var app_version: String?
    var enter_page: String?
    var search: String?
    var bookcase_hlxs: String?
    var lottery_h5_link: String?
    var wechat: String?
    var qq: String?
    var ad_minute: Int?
    var ad_type: SwitcherAdType = SwitcherAdType.forceVideo
    var read_page_ad_num: Int?
    var read_page_full_screen_ad_num: Int?
    var listen_book_ad_ad_num: Int?
    var free_ad_num: Int?
    var read_page_chapter_end_ad_num: Int?
    var buy_vip: Bool = false
    
}

enum SwitcherAdType: Int, HandyJSONEnum {
    /// 强制视频
    case forceVideo = 1
    /// 非强制视频
    case unforceVideo = 2
}

//class LocalSwitcherConfig: Object {
//    @objc dynamic var id: String = Constant.AppConfig.bundleID
//    @objc dynamic var app_version: String = ""
//    @objc dynamic var enter_page: String = ""
//    @objc dynamic var search: String = ""
//    @objc dynamic var bookcase_hlxs: String = ""
//    @objc dynamic var lottery_h5_link: String = ""
//    @objc dynamic var wechat: String = ""
//    @objc dynamic var qq: String = ""
//    @objc dynamic var ad_minute: NSInteger = 0
//    @objc dynamic var ad_type: NSInteger = SwitcherAdType.forceVideo.rawValue
//    @objc dynamic var read_page_ad_num: NSInteger = 0
//    @objc dynamic var listen_book_ad_ad_num: NSInteger = 0
//    @objc dynamic var free_ad_num: NSInteger = 0
//    @objc dynamic var read_page_full_screen_ad_num: NSInteger = 0
//    
//    override static func primaryKey() -> String? {
//        return "id"
//    }
//    
//    convenience init( _ serverData: SwitcherConfig) {
//        self.init()
//        self.app_version = serverData.app_version ?? ""
//        self.enter_page = serverData.enter_page ?? ""
//        self.search = serverData.search ?? ""
//        self.bookcase_hlxs = serverData.bookcase_hlxs ?? ""
//        self.lottery_h5_link = serverData.lottery_h5_link ?? ""
//        self.wechat = serverData.wechat ?? ""
//        self.qq = serverData.qq ?? ""
//        self.ad_minute = serverData.ad_minute ?? 0
//        self.ad_type = serverData.ad_type.rawValue
//        self.read_page_ad_num = serverData.read_page_ad_num ?? 0
//        self.listen_book_ad_ad_num = serverData.listen_book_ad_ad_num ?? 0
//        self.free_ad_num = serverData.free_ad_num ?? 0
//        self.read_page_full_screen_ad_num = serverData.read_page_full_screen_ad_num ?? 0
//    }
//}


class AppConfig: Object {
    @objc dynamic var id: String = Constant.AppConfig.bundleID
    @objc dynamic var app_version: Int = Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1") ?? 1
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

class LaunchAlertTime: Object {
    @objc dynamic var id: String = Constant.AppConfig.bundleID
    @objc dynamic var modify_time: Double = Date().timeIntervalSince1970
    
    override static func primaryKey() -> String? {
        return "id"
    }
}