//
//  Login.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/21.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import HandyJSON
import RealmSwift

class PictureCaptchaResponse: BaseResponse<PictureCaptcha> {}

class UserSafeRatioResponse: BaseResponse<UserSafeRatio> {}

class UserSsoResponse: BaseResponse<UserSso> {}

class PictureCaptcha: Model {
    var h: CGFloat = 0
    var b: String = ""
    var s: String = ""
}

class UserSafeRatio: Model {
    var phone: String?
    var code: Float = 0.0
}

class UserSso: Model {
    var token: String?
}

class FlashLoginTime: Object {
    @objc dynamic var id: String = Constant.AppConfig.bundleID
    @objc dynamic var loginNum: Int = 0
    @objc dynamic var loginTime: Double = Date().timeIntervalSince1970
    
    static override func primaryKey() -> String? {
        return "id"
    }
    
    convenience init(_ local: FlashLoginTime) {
        self.init()
        self.id = local.id
        self.loginNum = local.loginNum
        self.loginTime = local.loginTime
    }
}
