//
//  BookMall.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/10.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import HandyJSON

/// 精选-轮播图+重磅推荐
class BannerAndSpecialRecommnedResponse: BaseResponse<BannerAndSpecialRecommned> {
    static func commonError(_ error: Error) -> BannerAndSpecialRecommnedResponse {
        let response = BannerAndSpecialRecommnedResponse()
        let status = ReponseResult()
        response.status = status
        status.code = -1
        status.msg = "遇到问题了哦"
        if let error = error as? AppError {
            status.msg = error.message
        }
        return response
    }
}

/// 精选-其他分类推荐书籍
class OtherRecommendBookResponse: BaseResponseArray<RecommendBook> {
    static func commonError(_ error: Error) -> OtherRecommendBookResponse {
        let response = OtherRecommendBookResponse()
        let status = ReponseResult()
        response.status = status
        status.code = -1
        status.msg = "遇到问题了哦"
        response.data = []
        if let error = error as? AppError {
            status.msg = error.message
        }
        return response
    }
}

/// 精选-推荐位内容
class RecommendPositionResponse: BaseResponseArray<RecommendPosition> {
    static func commonError(_ error: Error) -> RecommendPositionResponse {
        let response = RecommendPositionResponse()
        let status = ReponseResult()
        response.status = status
        status.code = -1
        status.msg = "遇到问题了哦"
        response.data = []
        if let error = error as? AppError {
            status.msg = error.message
        }
        return response
    }
    
}

class BannerAndSpecialRecommned: Model {
    var lunbotu: [Banner]?
    var jingxuan_zhongbangtuijian: [RecommendBook]?
}

class Banner: HandyJSON {
    var id: String?
    var type_name: String?
    var img_url: String?
    var jump_url: String?
    var color: String?
    
    func mapping(mapper: HelpingMapper) {
        mapper <<<
            jump_url <-- StringPercentEndingTransform()
        
    }
    
    public required init() {}
}

class RecommendBook: Model {
    var category_id_1: Category?
    var category_id_2: Category?
    var book_id: String?
    var book_title: String?
    var author_name: String?
    var is_online: Bool = false
    var chapter_count: Int = 0
    var cover_url: String?
    var last_chapter_title: String?
    var is_free: Bool = false
    var writing_process: BookStatus = .serializing
    var book_intro: String?
    var last_chapter_date: String?
    
    var title: String?
    var title_desc: String?
    var book_ids: String?
    var book_title_info: String?
    var title_small_img1: String?
    var title_small_img2: String?
    var title_small_img3: String?
    var jump_url: String?
    var content: [RecommendPositionInfoConetent]?
    var img_url: String?
    var short_name: String?
    var name: String?
    var parent_id: String?
    var level: String?
    var site: String?
    var category_id: String?
    var book_count_title: String?
    var category_count_title: String?
    var localTempAdConfig: LocalTempAdConfig?
    
}

class RecommendPositionInfoConetent: RecommendBook {
    
}


class RecommendPosition: Model {
    var title: String?
    var style: RecommendPositionUIStyle = .none
    var type_name: String?
    var bookinfo: [RecommendBook]?
    var category_id_1: String?
    var category_id_2: String?
    var localTempAdConfig: LocalTempAdConfig?
}

enum RecommendPositionUIStyle: Int, HandyJSONEnum {
    case none = 0
    case leftImageRightText = 1
    case bottomThreeImage = 2
    case leftThreeImage = 3
    case commonCategory = 4
    case topImageBottomText = 5
    case rightOrTopImage = 6
}
