//
//  DateExtension.swift
//  Arab
//
//  Created by lieon on 2018/9/14.
//  Copyright © 2018年 kanshu.com. All rights reserved.
//

import Foundation

extension Date {

    var description: String {
        
        let currentTimestamp = Date().timeIntervalSince1970
        let spaceTimestamp = currentTimestamp - self.timeIntervalSince1970
        let spaceSec = Int(spaceTimestamp)
        
        if spaceSec < 60 {
            return NSLocalizedString("justNow", comment: "")
        }
        
        if spaceSec/60 < 60 {
            return String(format: NSLocalizedString("minuteAgo", comment: ""), spaceSec/60)
        }
        
        if spaceSec/3600 < 24 {
            return String(format: NSLocalizedString("hourAgo", comment: ""), spaceSec/3600)
        }
        
        if spaceSec/3600/24 < 2 {
            return NSLocalizedString("yesterday", comment: "")
        }
        
        if spaceSec/3600/24 < 7 {
            return String(format: NSLocalizedString("dayAgo", comment: ""), spaceSec/3600/24)
        }
        
        if spaceSec/3600/24 < 30 {
            
            let formatter = DateFormatter()
            formatter.dateFormat = NSLocalizedString("monthAndDay", comment: "")
            return formatter.string(from: self)
        }
//        let date = Date(timeIntervalSince1970: timestamp)
        let formatter = DateFormatter()
        formatter.dateFormat = NSLocalizedString("yearMonthDay", comment: "")
        return formatter.string(from: self)
    }
    
    func withFormat(_ formatStr: String) -> String {
        let format = DateFormatter()
        format.dateFormat = formatStr
        return format.string(from: self)
    }
    
  static  func convertSecondsFormat(_ seconds: Double) -> String {
        if seconds == 0 {
            return "00:00"
        }
        let date = Date(timeIntervalSince1970: seconds)
        let formatter = DateFormatter()
        if seconds / 36000 >= 1 {
            formatter.dateFormat = "HH:mm:ss"
        } else {
            formatter.dateFormat = "mm:ss"
        }
        return formatter.string(from: date)
    }

    /// 今天的0点时间和
    var todayStartTime: Date {
        let calenndar = Calendar.current
        let components = calenndar.dateComponents([.year, .month, .day], from: self)
        return calenndar.date(from: components) ?? Date()
    }
    
    /// 下一天的0点时间
    var todayEndTime: Date {
        let calenndar = Calendar.current
        return calenndar.date(byAdding: .day, value: 1, to: self.todayStartTime) ?? Date()
    }
}
