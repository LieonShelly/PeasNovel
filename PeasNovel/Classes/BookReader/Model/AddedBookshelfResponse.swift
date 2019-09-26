//
//  AddedBookshelfResponse.swift
//  Arab
//
//  Created by lieon on 2018/10/31.
//  Copyright © 2018 kanshu.com. All rights reserved.
//

import HandyJSON

struct AddedBookshelfResponse: HandyJSON {
    var code = 0
    var msg: String?
    var isJoin: Bool = true
    
    mutating func mapping(mapper: HelpingMapper) {
        mapper <<<
            self.isJoin <-- "data.is_join"
    }
}
