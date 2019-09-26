//
//  ListenBook.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/12.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RealmSwift


enum ToneType: Int {
    case male = 1
    case female = 0
}

enum SpeechType: Int {
    case moreSlow = 0
    case slow = 1
    case normal = 2
    case quick = 3
    case moreQuick = 4
    
    var rate: Float {
        switch self {
        case .moreSlow:
            return 0.5
        case .slow:
            return 0.75
        case .normal:
            return 1
        case .quick:
            return 1.5
        case .moreQuick:
            return 2.0
        }
    }
}

enum TimingType: Int {
    case none = 0
    case fifteen = 15
    case thirty = 30
    case sixity = 60
    case ninety = 90
}

class ListenBookMenuConfig: Object {
    @objc dynamic var id: String = Constant.AppConfig.bundleID
    @objc dynamic var tone: NSInteger = ToneType.female.rawValue
    @objc dynamic var speech_rate: NSInteger = SpeechType.normal.rawValue
    @objc dynamic var timing: NSInteger = TimingType.none.rawValue
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
}

class ListenBookAdModel: Object {
    @objc dynamic var watch_num: NSInteger = 0
    @objc dynamic var create_time: Double = Date().timeIntervalSince1970
    @objc dynamic var id: String = Constant.AppConfig.bundleID
    @objc dynamic var listen_chapter_count : NSInteger = 0
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    static func addWatchNum(_ count: Int = 1) {
        let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
        if let record = realm.objects(ListenBookAdModel.self).last {
            if record.create_time < Date().todayEndTime.timeIntervalSince1970,
                record.create_time >= Date().todayStartTime.timeIntervalSince1970 {
                try? realm.write {
                    record.watch_num += count
                    record.create_time = Date().timeIntervalSince1970
                    record.listen_chapter_count = 0
                }
            }  else if record.create_time < Date().todayStartTime.timeIntervalSince1970 {
                let newRecord = ListenBookAdModel()
                newRecord.watch_num = count
                record.create_time = Date().timeIntervalSince1970
                record.listen_chapter_count = 0
                try? realm.write {
                    realm.add(newRecord, update: .all)
                }
            }
        } else {
            let newRecord = ListenBookAdModel()
            newRecord.watch_num = count
            try? realm.write {
                realm.add(newRecord, update: .all)
            }
        }
    }
    
    static func addListenChapterCount(_ count: Int = 1) {
        let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
        if let record = realm.objects(ListenBookAdModel.self).first {
            try? realm.write {
                record.create_time = Date().timeIntervalSince1970
                record.listen_chapter_count += count
            }
        } else {
            let newRecord = ListenBookAdModel()
            newRecord.create_time = Date().timeIntervalSince1970
            newRecord.listen_chapter_count = count
            try? realm.write {
                realm.add(newRecord, update: .all)
            }
        }
    }
    
    static func  todayListenChapterCount() -> Int? {
        let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
        if let record = realm.objects(ListenBookAdModel.self).first {
            if record.create_time < Date().todayEndTime.timeIntervalSince1970,
                record.create_time >= Date().todayStartTime.timeIntervalSince1970 {
                return record.listen_chapter_count
            }  else if record.create_time < Date().todayStartTime.timeIntervalSince1970 {
                return 0
            }
        }
        return nil
    }

    static func todayAdWatchNum() -> Int? {
        let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
        if let record = realm.objects(ListenBookAdModel.self).first {
            if record.create_time < Date().todayEndTime.timeIntervalSince1970,
                record.create_time >= Date().todayStartTime.timeIntervalSince1970 {
                return record.watch_num
            }  else if record.create_time < Date().todayStartTime.timeIntervalSince1970 {
                return 0
            }
        }
        return nil
    }
}
