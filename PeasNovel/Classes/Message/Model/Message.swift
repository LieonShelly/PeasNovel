//
//  Message.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/20.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RealmSwift
import HandyJSON

class BaseServerMessage: HandyJSON {
    var show_type: MessageShowType = MessageShowType.inner
    var createtime: Int = Int(Date().timeIntervalSince1970)
    var title: String = ""
    var content: String = ""
    var img_url: String = ""
    var intent: String = ""
    var jump_url: String = ""
    
    func mapping(mapper: HelpingMapper) {
        mapper <<<
            jump_url <-- StringPercentEndingTransform()
        
    }
    
    public required init() {}
}

enum MessageShowType: Int, HandyJSONEnum {
    case inner = 0
    case outter = 1
}

class ServerMessage: BaseServerMessage {
    var messages: [BaseServerMessage] = []
}


enum MessageStyleType: Int, HandyJSONEnum {
    case none = -1
    case titleBigPic = 1
    case titleSmallPic = 2
    case text = 3
    case sendNoti = 4
}
/// MessageModel- 已废弃， 使用GEPushMessage
//class MessageModel: Object {
//    @objc dynamic var createtime: Int = Int(Date().timeIntervalSince1970)
//    @objc dynamic var message_id: String = ""
//    @objc dynamic var title: String = ""
//    @objc dynamic var notify_theme: String = ""
//    @objc dynamic var style_type: Int = MessageStyleType.none.rawValue
//    @objc dynamic var link_type: Int = -1
//    @objc dynamic var img_url: String = ""
//    @objc dynamic var content_id: String = ""
//    @objc dynamic var jump_url: String = ""
//    @objc dynamic var notify_id: String = ""
//    @objc dynamic var notify_time: Int = -1
//    @objc dynamic var notify_link_type: Int = -1
//    @objc dynamic var notify_url: String = ""
//    @objc dynamic var notify_content: String = ""
//    @objc dynamic var notify_book_id: String = ""
//    @objc dynamic var notify_content_id: String = ""
//    @objc dynamic var notify_order_id: String = ""
//    @objc dynamic var status: Int = MessageStatus.unread.rawValue
//
//    override static func primaryKey() -> String? {
//        return "message_id"
//    }
//
//
//    convenience init(_ local: MessageModel) {
//        self.init()
//        self.createtime = local.createtime
//        self.message_id = local.message_id
//        self.title = local.title
//        self.style_type = local.style_type
//        self.link_type = local.link_type
//        self.img_url = local.img_url
//        self.content_id = local.content_id
//        self.jump_url = local.jump_url
//        self.notify_id = local.notify_id
//        self.notify_time = local.notify_time
//        self.notify_link_type = local.notify_link_type
//        self.notify_theme = local.notify_theme
//        self.notify_content = local.notify_content
//        self.notify_book_id = local.notify_book_id
//        self.notify_content_id = local.notify_content_id
//        self.notify_order_id = local.notify_order_id
//        self.status = local.status
//    }
//
//}
//
enum MessageStatus: Int {
    case unread = 0
    case read = 1
}

class GEPushMessage: Object {
    @objc dynamic var show_type: Int = MessageShowType.inner.rawValue
    @objc dynamic  var createtime: Int = Int(Date().timeIntervalSince1970)
    @objc dynamic var title: String = ""
    @objc dynamic var content: String = ""
    @objc dynamic var img_url: String = ""
    @objc dynamic var intent: String = ""
    @objc dynamic var jump_url: String = ""
    let  chilid_messages = List<GEPushChildMessage>()
    @objc dynamic var status: Int = MessageStatus.unread.rawValue
    
    override static func primaryKey() -> String? {
         return "createtime"
     }
    
    convenience init(_ serverMessage: ServerMessage) {
        self.init()
        self.show_type = serverMessage.show_type.rawValue
        self.createtime = serverMessage.createtime
        self.title = serverMessage.title
        self.content = serverMessage.content
        self.img_url = serverMessage.img_url
        self.intent = serverMessage.intent
        self.jump_url = serverMessage.jump_url
        let chlidMessages = serverMessage.messages.map { GEPushChildMessage($0) }
        self.chilid_messages.append(objectsIn: chlidMessages)
    }
    
    convenience init(_ localMessage: GEPushMessage) {
        self.init()
        self.show_type = localMessage.show_type
        self.createtime = localMessage.createtime
        self.title = localMessage.title
        self.content = localMessage.content
        self.img_url = localMessage.img_url
        self.intent = localMessage.intent
        self.jump_url = localMessage.jump_url
        let chlidMessages = localMessage.chilid_messages
        self.chilid_messages.append(objectsIn: chlidMessages)
    }
}


class GEPushChildMessage: Object {
    @objc dynamic var show_type: Int = MessageShowType.inner.rawValue
    @objc dynamic  var createtime: Int = Int(Date().timeIntervalSince1970)
    @objc dynamic var title: String = ""
    @objc dynamic var content: String = ""
    @objc dynamic var img_url: String = ""
    @objc dynamic var intent: String = ""
    @objc dynamic var jump_url: String = ""
    @objc dynamic var status: Int = MessageStatus.unread.rawValue
    
    override static func primaryKey() -> String? {
        return "createtime"
    }
    
    convenience init(_ serverMessage: BaseServerMessage) {
        self.init()
        self.show_type = serverMessage.show_type.rawValue
        self.createtime = serverMessage.createtime
        self.title = serverMessage.title
        self.content = serverMessage.content
        self.img_url = serverMessage.img_url
        self.intent = serverMessage.intent
        self.jump_url = serverMessage.jump_url
    }
    
    
}
