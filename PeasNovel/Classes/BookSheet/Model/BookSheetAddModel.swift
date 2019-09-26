//
//  BookSheetAddModel.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/30.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class BookSheetAddResponse: BaseResponse<BookSheetAddModel> {

}

class BookSheetAddModel: Model {
    var book_id: String?
    var book_lists: Any?
}
