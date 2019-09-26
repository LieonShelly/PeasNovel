//
//  BoutiqueActiveModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/14.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import HandyJSON

class BoutiqueActiveResponse: BaseResponseArray<BoutiqueActiveModel> {
}


class BoutiqueActiveModel: HandyJSON {
    var id: String? //": 999,
    var boutique_title: String? //": "精品书单",
    var boutique_img: String? //": "http://file.momoyue.cn/upload/tmp/2019-03/0a619baf89b16e6005034293342310d3.png",
    var jump_url: String? //": "client://kanshu/selected_book_menu_list"
    
    func mapping(mapper: HelpingMapper) {
        mapper <<<
            jump_url <-- StringPercentEndingTransform()
        
    }
    
    public required init() {}
}
