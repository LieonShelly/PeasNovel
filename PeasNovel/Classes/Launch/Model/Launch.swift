//
//  Launch.swift
//  PeasNovel
//
//  Created by lieon on 2019/6/3.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import HandyJSON

class LaunchAlertResponse: BaseResponse<LaunchAlert> { }

class LaunchAlert: HandyJSON {
    var type_name: String?
    var title: String?
    var img_url: String?
    var jump_url: String?
    var is_delete: Bool = true
    
    func mapping(mapper: HelpingMapper) {
        mapper <<<
            jump_url <-- StringPercentEndingTransform()
        
    }
    
    public required init() {}
    
    
}
