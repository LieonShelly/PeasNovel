//
//  Charge.swift
//  PeasNovel
//
//  Created by lieon on 2019/2/19.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import HandyJSON

class ChargeResponse: BaseResponseArray<ChargeModel> { }


class ChargeRecordResponse: BaseResponseArray<ChargeRecord> {
    
    static func emptyError(_ error: Error) -> ChargeRecordResponse {
        let response = ChargeRecordResponse()
        let status = ReponseResult()
        response.status = status
        status.code = 0
        status.msg = "遇到问题了哦"
        if let error = error as? AppError {
            status.msg = error.message
        }
        response.data = []
        return response
    }
    
}

class ChargeModel: Model {
    
    var rule_id: String?
    var amount: String?
    var days: String?
    var discount: String?
    var product_id: String?
    var disamount: String?
    var isSelected: Bool = false
    var pay_title: String?
    var pay_fee: Int = 0
    
}

class ChargeRecord: Model {
    var total_fee: Int = 0
    var start_time: String?
    var end_time: String?
    var order_no: String?
    var day: String = "30"
    var pay_type_title: String?
    var title: String? 
    var pay_type: String = "苹果支付"
    
    
}

