//
//  Feedback.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/26.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import HandyJSON

class FeedbackQuestionResponse: BaseResponseArray<FeedbackQuestion> {}

class FeedbackQuestionDetailResponse: BaseResponseArray<FeedbackQuestionDetail> {}

class MyFeedbackResponse: BaseResponseArray<MyFeedback> {
    
    static func commonError(_ error: Error) -> MyFeedbackResponse {
        let response = MyFeedbackResponse()
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

class FeedbackQuestion: Model {
    var id: String?
    var title: String?
    var isSelected: Bool = false
}

class FeedbackQuestionDetail: Model {
    var id: String?
    var question: String?
    var category_id: String?
    var reply: String?
    var isSelected: Bool = false
    var img_url: String = ""
}

class MyFeedback: Model {
    var content: String?
    var createtime: String?
    var suggest_reply: SuggestReply?
    
}

class SuggestReply: Model {
    var content: String?
    var createtime: String?
}
