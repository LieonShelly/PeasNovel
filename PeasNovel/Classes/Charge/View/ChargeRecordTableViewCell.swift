//
//  ChargeRecordTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/25.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class ChargeRecordTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var startLabel: UILabel!
    @IBOutlet weak var endLabel: UILabel!
    @IBOutlet weak var payLabel: UILabel!
    @IBOutlet weak var orderLabel: UILabel!
    @IBOutlet weak var priceLabel: UILabel!
     @IBOutlet weak var statusLabel: UILabel!
    
    
    func config(_ record: ChargeRecord) {
        titleLabel.text = record.title
        orderLabel.text = "订单编号：" + (record.order_no ?? "")
        payLabel.text = "支付方式：" + (record.pay_type_title ?? "苹果支付")
        priceLabel.text = "￥ " + "\(record.total_fee / 100)"
        startLabel.text = "会员生效时间：" + (record.start_time ?? "")
        endLabel.text = "会员结束时间：" + (record.end_time ?? "")
        
        let format = DateFormatter()
        format.dateStyle = .medium
        format.timeStyle = .short
        format.dateFormat = "YYYY-MM-dd HH:mm:ss"
        if let endDate = format.date(from: record.end_time ?? ""),
            let startTime = format.date(from: record.start_time ?? "") {
            let endTimeInterval = endDate.timeIntervalSince1970
            let startTimeInterval = startTime.timeIntervalSince1970
            let nowTimeInterval = Date().timeIntervalSince1970
            if nowTimeInterval >= startTimeInterval &&  nowTimeInterval <= endTimeInterval {
                 statusLabel.text = "生效中"
            } else if nowTimeInterval > endTimeInterval {
                   statusLabel.text = "已过期"
            } else if nowTimeInterval < startTimeInterval {
                 statusLabel.text = "未生效"
            }
        }
    }


}
