//
//  ReaderLastPage.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/22.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation

class ReaderLastPageGuessBookResponse: BaseResponseArray<ReaderLastPageGuessBook> {}

class ReaderLastPageGuessBook: RecommendBook {
    var locaAdTemConfig: LocalTempAdConfig?
}
