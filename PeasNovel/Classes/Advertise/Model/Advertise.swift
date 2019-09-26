//
//  Advertise.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/5.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import HandyJSON
import Moya
import RxSwift
import RxCocoa
import RxSwiftExt
import CryptoSwift
import RxDataSources
import RxRealm
import Realm
import RealmSwift
import InMobiSDK
import Alamofire

protocol Advertiseable {
    var isAutoRefresh: Bool { get }
    func errorNotification(_ config: LocalAdvertise?, userInfo: [String: Any]?, errorCallBack: (() -> Void)?)
    func adExposedNotification(_ config: LocalAdvertise?)
    func adLoadedNotification(_ config: LocalAdvertise?)
    func adClickNotification(_ config: LocalAdvertise?)
    /// 关闭广告需要做的操作
    func adClickHandler(_ config: LocalAdvertise?) -> Bool
    func clearErrorLog(_ config: LocalAdvertise?)
}

extension Advertiseable {
    var isAutoRefresh: Bool {
        return false
    }
    func adClickHandler(_ config: LocalAdvertise?) -> Bool {
        return false
    }
    
    func adLoadedNotification(_ config: LocalAdvertise?) {
        if let config = config {
            NotificationCenter.default.post(name: NSNotification.Name.Advertise.loadSuccess, object: config)
            NotificationCenter.default.post(name: NSNotification.Name.Statistic.advertise, object: ["ad_type": config.ad_type,
                                                                                                    "ad_position": config.ad_position,
                                                                                                    "pv_uv_page_type": "ad_request"])
            clearErrorLog(config)
        }
    }
    
    func adExposedNotification(_ config: LocalAdvertise?) {
        if let config = config {
            let adService = AdvertiseService()
            adService.advertiseExposed.onNext(config)
            NotificationCenter.default.post(name: NSNotification.Name.Statistic.advertise, object: ["ad_type": config.ad_type,
                                                                                                    "ad_position": config.ad_position,
                                                                                                    "pv_uv_page_type": "ad_show"])
        }
    }
    func adClickNotification(_ config: LocalAdvertise?) {
        if let config = config {
            NotificationCenter.default.post(name: NSNotification.Name.Statistic.advertise, object: ["ad_type": config.ad_type,
                                                                                                    "ad_position": config.ad_position,
                                                                                                    "pv_uv_page_type": "ad_click"])
        }
    }
    

    
    func errorNotification(_ config: LocalAdvertise?, userInfo: [String: Any]? = nil, errorCallBack: (() -> Void)? = nil) {
        guard let config = config else {
            return
        }
        /// 网络不可用直接返回
         let manager = NetworkReachabilityManager()
        guard let isReachable = manager?.isReachable, isReachable == true else {
            return
        }
        let adService = AdvertiseService()
        adService.advertiseExposed.onNext(config)
        var error_load_num: Int = 1
        let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
        if let dbLog = realm.objects(AdvertiseLoadErrorLog.self).filter(NSPredicate(format: "ad_position = %ld", config.ad_position)).first {
            if  dbLog.error_load_num >= 10 {
                return
            }
            error_load_num = dbLog.error_load_num + 1
          try? realm.write {
                dbLog.error_load_num = error_load_num
            }

        } else {
            error_load_num = 1
            let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
            let log = AdvertiseLoadErrorLog()
            log.ad_position = config.ad_position
            log.local_advertise = config
            log.error_load_num = error_load_num
            try? realm.write {
               realm.add(log, update: .all)
            }
        }
        if error_load_num == AdvertiseLaodType.first.rawValue {
            NotificationCenter.default.post(name: NSNotification.Name.Advertise.fisrtTypeLoadFail, object: LocalAdvertise(config), userInfo: userInfo)
        } else if error_load_num == AdvertiseLaodType.second.rawValue  {
            NotificationCenter.default.post(name: NSNotification.Name.Advertise.secondTypeLoadFail, object: LocalAdvertise(config), userInfo: userInfo)
        } else {
            errorCallBack?()
            NotificationCenter.default.post(name: NSNotification.Name.Advertise.allTypeLoadFail, object: LocalAdvertise(config), userInfo: userInfo)
        }
    }

    func clearErrorLog(_ config: LocalAdvertise?) {
        guard let config = config else {
            return
        }
        let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
        let dbLogs = realm.objects(AdvertiseLoadErrorLog.self).filter(NSPredicate(format: "ad_position = %ld", config.ad_position))
        try? realm.write {
             dbLogs.setValue(0, forKeyPath: "error_load_num")
        }
    }
}

protocol AdvertiseUIInterface: Advertiseable {
    var userInfo: [String: Any]! { get set }
    var holderVC: UIViewController? {get set }
    /// 信息流广告初始尺寸，广告加载后，有些是模板广告的话，需要根据其模板广告，获取它的真实尺寸(比如广点通的)
    func infoAdSize(_ type: AdvertiseType?) -> CGSize
    /// 信息流广告加载后的真实尺寸
    func infoAdLoadedRealSize(_ type: LocalAdvertiseType?) -> CGSize

    func viewModelCacheKey(_ config: LocalAdvertise) -> String
    
    
    
}

extension AdvertiseUIInterface {

    func infoAdSize(_ type: AdvertiseType?) -> CGSize {
        guard let type = type else {
            return .zero
        }
        switch type {
        case .inmobi:
            return CGSize(width: (UIScreen.main.bounds.width - 2 * 16), height: (UIScreen.main.bounds.width - 2 * 16)  * 2.0 / 3.0 + 120)
        case .GDT:
            return CGSize(width: (UIScreen.main.bounds.width - 2 * 16), height: (UIScreen.main.bounds.width - 2 * 16)  * 2.0 / 3.0 + 50)
        case .todayHeadeline:
            return CGSize(width: (UIScreen.main.bounds.width - 2 * 16), height: (UIScreen.main.bounds.width - 2 * 16)  * 2.0 / 3.0 + 80)
        default:
            return .zero
        }
    }
    
    func infoAdLoadedRealSize(_ type: LocalAdvertiseType?) -> CGSize {
        guard let type = type else {
            return .zero
        }
        switch type {
        case .inmobi:
            return CGSize(width: (UIScreen.main.bounds.width - 2 * 16), height: (UIScreen.main.bounds.width - 2 * 16)  * 2.0 / 3.0 + 120)
        case .GDT(let nativeAd):
            if let nativeAd = nativeAd as? GDTNativeExpressAdView {
                return nativeAd.size
            }
             return .zero
        case .todayHeadeline:
            return CGSize(width: (UIScreen.main.bounds.width - 2 * 16), height: (UIScreen.main.bounds.width - 2 * 16)  * 2.0 / 3.0 + 80)
        default:
            return .zero
        }
    }
    
    
    
    func viewModelCacheKey(_ config: LocalAdvertise) -> String {
        let key = "\(config.ad_position)" + config.ad_position_id
        debugPrint("viewModelCacheKey:\(key)")
        return  key
    }
    
    var userInfo: [String: Any]! {
        get {
            return [:]
        }
        set {
            
        }
    }
    
    var holderVC: UIViewController? {
        get {
            return (UIApplication.shared.keyWindow?.rootViewController as? TabBarController)?.viewControllers?[(UIApplication.shared.keyWindow?.rootViewController as? TabBarController)?.selectedIndex ?? 0]
        }
        set {
            
        }
    }

}

enum AdvertiseType: Int, HandyJSONEnum {
    case none = -1
    ///  3 => '图文 - 广告',
    case pictureText = 3
    ///  4 => '广点通 - 广告'',
    case GDT = 4
    ///  5 => '360 - 广告',
    case platform360 = 5
    ///   6 => 'inmobi - 广告',,
    case inmobi = 6
    ///  '今日头条 - 广告'
    case todayHeadeline = 9
    ///  10 => '洛米 - 广告',,
    case nuomi = 10
    ///  11 => '变现猫',
    case bianxinamao = 11
    /// 12 => '百度 - 广告',
    case baidu = 12
    
    
}

/// 临时用的
class LocalTempAdConfig {
    var localConfig: LocalAdvertise
    var adType: LocalAdvertiseType = .none
    var uiConfig: AdvertiseUIInterface?
    
    convenience init( _ localConfig: LocalAdvertise, adType: LocalAdvertiseType) {
        self.init()
        self.localConfig = localConfig
        self.adType = adType
    }
    
    init() {
        self.localConfig = LocalAdvertise()
    }
}

enum LocalAdvertiseType {
    case none
    case pictureText
    case GDT(Any)
    case platform360
    case inmobi(Any)
    case todayHeadeline(Any)
    case nuomi
    case bianxinamao
    case baidu
}

enum AdPosition: Int, HandyJSONEnum {
    case none = -1
    /// 启动页广告
    case splash = 101
    /// "书架上方Banner SJ-0（1080*150）
    case bookShelfTop = 102
    ///  "书架-编辑好书广告位SJ-1（原生封面）270*360"
    case bookShelfEditBookSJ_1 = 103
    ///  "书架-编辑好书广告位SJ-2（原生封面）270*360"
    case bookShelfEditBookSJ_2 = 104
    ///  "书架-编辑好书广告位SJ-3（原生封面）270*360"
    case bookShelfEditBookSJ_3 = 105
    /// 书籍详情中间Banner SJXQ-1（1080*150）
    case bookDetailMedium = 106
    /// 阅读页下方Banner（1080*150）
    case readerBottomBanner = 107
    /// 搜索页上方Banner（1080*150）
    case searchPageTopBanner = 108
    /// 阅读章节衔接页每5章节衔接（原生上文下大图）1080*720
    case readerPer5PageBigPic = 109
    /// 阅读页内每5章底部banner（1080*150)
    case readerPer5PgeBottomBanner = 110
    ///   111 => "安卓豆豆-阅读页章节衔接广告 （原生上文下大图）1080*720",
    case readerPerPageBigPic = 111
    ///    112 => "5分钟开屏广告",
    case fiveMinutesSplash = 112
    ///    113 => "阅读页内全屏视频广告",
    case readerFullScreenVideo = 113
    ///    114 => "推荐书摇一摇页面广告（信息流）",
    case readerShinkingInfoStream = 114
    ///    115 => "下载页底部banner",
    case downloadBottomBanner = 115
    ///   116 => 章节下载解锁激励视频
    case downloadUnLockRewardVideo = 116
    ///   117 => 网页搜索底部
    case webPageSearch = 117
    ///    118 => "零钱提现激励视频",
    case cashWithdrawal = 118
    ///    119 => "本周主打下信息流广告",,
    case weekMainLoadInfoStream = 119
    ///    120 => "推荐书单下--信息流广告",
    case recommendBookListInfoStream = 120
    ///    121 => "精选用户分类--信息流广告",
    case boutiqueCategoryInfoStream = 121
    ///    122 => "万人之选--信息流广告",
    case wanrenzhixuanInnfoStream = 122
    ///    123 => "用户分类频道--信息流广告",
    case userCategoryInfoStream = 123
    ///    124 => "阅读器免广告阅读--视频广告",
    case readerRewardVideoAd = 124
    /// 阅读器看视频听书
    case readerViedeoAdListenBook = 125
    /// 阅读器每x页全屏广告
    case readerPageFullScreenAd = 126
    /// 章节结尾广告
    case readerChapterPageEndAd = 127
    /// 阅读器中间信息流广告
    case readerPageInfoAd = 128
   
    
}

class AdvertiseConfigResponse: BaseResponseArray<AdvertiseConfig> { }

class AdvertiseModel: Model {
    var ad_type: AdvertiseType = AdvertiseType.none
    var exposure: Int = 0
    var ad_position: AdPosition = AdPosition.none
    var ad_position_id: String = ""
    
}

class TempAdvertise: Object {
    var id: String = "" /// ad_type + ad_position 作为主键
    var ad_type: NSInteger = 0
    var ad_position: NSInteger = 0
    var ad_position_id: String = ""
    var second_ad_type: NSInteger = 0
    var second_ad_position_id: String = ""
    var third_ad_type: NSInteger = 0
    var third_ad_position_id: String = ""
    var is_close: Bool = false
    var exposure: NSInteger = 0  /// 能够曝光好多次
    
    convenience init(_ localRecord: LocalAdvertise) {
        self.init()
        self.id = localRecord.id
        self.ad_type = localRecord.ad_type
        self.ad_position = localRecord.ad_position
        self.ad_position_id = localRecord.ad_position_id
        self.second_ad_type = localRecord.second_ad_type
        self.second_ad_position_id = localRecord.second_ad_position_id
        self.third_ad_type = localRecord.third_ad_type
        self.third_ad_position_id = localRecord.third_ad_position_id
        self.is_close = localRecord.is_close
        self.exposure = localRecord.exposure
    }
}

class LocalAdvertise: Object {
    @objc dynamic var id: String = "" /// ad_type + ad_position 作为主键
    @objc dynamic var ad_type: NSInteger = 0
    @objc dynamic var ad_position: NSInteger = 0
    @objc dynamic var ad_position_id: String = ""
    @objc dynamic var second_ad_type: NSInteger = 0
    @objc dynamic var second_ad_position_id: String = ""
    @objc dynamic var third_ad_type: NSInteger = 0
    @objc dynamic var third_ad_position_id: String = ""
    @objc dynamic var is_close: Bool = false
    @objc dynamic var exposure: NSInteger = 0  /// 能够曝光好多次

    
    override static func primaryKey() -> String? {
        return "id"
    }

    convenience init( _ advertiseType: AdvertiseModel, advetiseConfig: AdvertiseConfig) {
        self.init()
        self.id = "\( advertiseType.ad_type.rawValue)" + "\(advertiseType.ad_position.rawValue)"
        self.ad_type = advertiseType.ad_type.rawValue
        self.ad_position = advertiseType.ad_position.rawValue
        self.ad_position_id = advertiseType.ad_position_id
        self.second_ad_type = advetiseConfig.second_ad_type.rawValue
        self.second_ad_position_id = advetiseConfig.second_ad_position_id ?? ""
        self.third_ad_type = advetiseConfig.third_ad_type.rawValue
        self.third_ad_position_id = advetiseConfig.third_ad_position_id ?? ""
        self.is_close = advetiseConfig.is_close
        self.exposure = advertiseType.exposure
    }
    
    
    convenience init( _ localRecord: LocalAdvertise) {
        self.init()
        self.id = localRecord.id
        self.ad_type = localRecord.ad_type
        self.ad_position = localRecord.ad_position
        self.ad_position_id = localRecord.ad_position_id
        self.second_ad_type = localRecord.second_ad_type
        self.second_ad_position_id = localRecord.second_ad_position_id
        self.third_ad_type = localRecord.third_ad_type
        self.third_ad_position_id = localRecord.third_ad_position_id
        self.is_close = localRecord.is_close
        self.exposure = localRecord.exposure
    }
    
    convenience init( _ localRecord: TempAdvertise) {
        self.init()
        self.id = localRecord.id
        self.ad_type = localRecord.ad_type
        self.ad_position = localRecord.ad_position
        self.ad_position_id = localRecord.ad_position_id
        self.second_ad_type = localRecord.second_ad_type
        self.second_ad_position_id = localRecord.second_ad_position_id
        self.third_ad_type = localRecord.third_ad_type
        self.third_ad_position_id = localRecord.third_ad_position_id
        self.is_close = localRecord.is_close
        self.exposure = localRecord.exposure
    }
}

class LocalAdvertiseExposured: Object {
    @objc dynamic var local_advertise_id: String = "" /// LocalAdvertise 的主键 作为主键
    @objc dynamic var ad_type: NSInteger = 0
    @objc dynamic var ad_position: NSInteger = 0
    @objc dynamic var exposured: NSInteger = 0 /// 曝光了好多次
    @objc dynamic var local_advertise: LocalAdvertise?
    
    override static func primaryKey() -> String? {
        return "local_advertise_id"
    }
    
    convenience init(_ localAdvertise: LocalAdvertise) {
        self.init()
        self.local_advertise_id = localAdvertise.id
        self.exposured = 0
        self.local_advertise = localAdvertise
        self.ad_type = localAdvertise.ad_type
        self.ad_position = localAdvertise.ad_position
    }
    
    func copySelf() -> LocalAdvertiseExposured{
        let newObj = LocalAdvertiseExposured()
        newObj.local_advertise_id = self.local_advertise_id
        newObj.exposured = self.exposured
        newObj.local_advertise = self.local_advertise
        newObj.ad_type = self.ad_type
        newObj.ad_position = self.ad_position
        return newObj
    }
    
}

class AdvertiseConfig: Model {
    var ad_type: AdvertiseType = AdvertiseType.none
    var second_ad_type: AdvertiseType = AdvertiseType.none
    var ad_position: AdPosition = AdPosition.none
    var is_close: Bool = false
    var title: String?
    var ad_image_url: String?
    var ad_image_jump: String?
    var ad_position_id: String?
    var second_ad_position_id: String?
    var description: String?
    var third_ad_position_id: String?
    var third_ad_type: AdvertiseType = AdvertiseType.none
    var ad_type_lists: [AdvertiseModel]?
    
}

class AppTime: Object {
    @objc dynamic  var id: String = ""
    @objc dynamic  var leaveAppTime: Int = 0
    
    override static func primaryKey() -> String? {
        return "id"
    }
}

/// 阅读器看视屏广告5章节免广告阅读
class ReaderFiveChapterNoAd: Object {
    @objc dynamic var id: String = "com.youhe.peas.novel"
    @objc dynamic var create_time: NSInteger = NSInteger(Date().timeIntervalSince1970)
    @objc dynamic var read_chapter_count : NSInteger = 0
    @objc dynamic var show_alert_count : NSInteger = 0
    @objc dynamic var chapter_title : String = ""
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    static func isShowAlert() -> Bool {
        let realm = try? Realm(configuration: Realm.Configuration.defaultConfiguration)
        let serverAlertCount = CommomData.share.switcherConfig.value?.free_ad_num ?? 0
        guard let record = realm?.objects(ReaderFiveChapterNoAd.self).first else {
            return true
        }
        if  record.create_time <= Int(Date().todayStartTime.timeIntervalSince1970) {
            return true
        }
        return  record.create_time >= Int(Date().todayStartTime.timeIntervalSince1970) &&
                record.create_time < Int(Date().todayEndTime.timeIntervalSince1970 ) &&
                record.show_alert_count < serverAlertCount
    }
    
    static func addShowAlertCount() {
        let realm = try? Realm(configuration: Realm.Configuration.defaultConfiguration)
        guard let record = realm?.objects(ReaderFiveChapterNoAd.self).first else {
            let newRecord = ReaderFiveChapterNoAd()
            newRecord.show_alert_count = 1
            newRecord.read_chapter_count = 0
            try? realm?.write {
                realm?.add(newRecord, update: .all)
            }
            return
        }
        if record.create_time < Int(Date().todayStartTime.timeIntervalSince1970) {
            try? realm?.write {
                record.show_alert_count = 1
                record.create_time = NSInteger(Date().timeIntervalSince1970)
                record.read_chapter_count = 0
            }
        } else {
            try? realm?.write {
                record.show_alert_count += 1
                record.create_time = NSInteger(Date().timeIntervalSince1970)
                record.read_chapter_count = 0
            }
        }
        
    }
    
    static func addReadChapterCount(_ count: Int = 1, chapterTitle: String) {
        let realm = try? Realm(configuration: Realm.Configuration.defaultConfiguration)
        guard let record = realm?.objects(ReaderFiveChapterNoAd.self).first else {
            let newRecord = ReaderFiveChapterNoAd()
            newRecord.read_chapter_count = 1
            newRecord.chapter_title = chapterTitle
            try? realm?.write {
                realm?.add(newRecord, update: .all)
            }
            return
        }
        if record.chapter_title == chapterTitle {
            return
        }
        try? realm?.write {
            record.read_chapter_count += count
            record.chapter_title = chapterTitle
            record.create_time = NSInteger(Date().timeIntervalSince1970)
        }
    }
    
    static func isReadFiveAd() -> Bool {
        /// 检查是否看了激励视频，免5章节广告 (有记录，在当天，阅读章节数小于6), 在免广告范围内，阅读器不显示广告
        var isFiveNoAd: Bool = false
        guard let realm = try? Realm(configuration: Realm.Configuration.defaultConfiguration),
            let record = realm.objects(ReaderFiveChapterNoAd.self).first else {
            return isFiveNoAd
        }
        debugPrint("isReadFiveAd - read_chapter_count:\(record.read_chapter_count)")
        if record.create_time >= Int(Date().todayStartTime.timeIntervalSince1970) && record.create_time < Int(Date().todayEndTime.timeIntervalSince1970 ),
            record.read_chapter_count <= 4 {
            isFiveNoAd = true
        }
        return isFiveNoAd
    }
    
    static func deleteRecord() {
       if let realm = try? Realm(configuration: Realm.Configuration.defaultConfiguration),
        let record = realm.objects(ReaderFiveChapterNoAd.self).first {
            try? realm.write {
                record.read_chapter_count = 1000
                record.create_time = NSInteger(Date().timeIntervalSince1970)
            }
        }
       
    }
}

enum AdvertiseLaodType: Int {
    case first = 1
    case second = 2
    case third = 3
}

class AdvertiseLoadErrorLog: Object {
    @objc dynamic var ad_position: NSInteger = 0
    @objc dynamic var error_load_num: NSInteger = -1
    @objc dynamic var local_advertise: LocalAdvertise?
    
    
    override static func primaryKey() -> String? {
        return "ad_position"
    }
}

var userInfo: [String : Any]?
