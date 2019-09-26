//
//  DZMReadChapterListModel.swift
//  ReaderKit
//
//  Created by lieon on 2017/5/12.
//  Copyright © 2018年lieon. All rights reserved.
//

import UIKit

class DZMReadChapterListModel: NSObject,NSCoding {
    /// 章节字数
    var words_count:Int32 = 0
    
    /// 章节号
    var order:Int32 = 0
    
    /// 购买金币数
    var price:Int32 = 0
    
    // 用户是否购买过
    var is_buy:Bool = false
    
    /// 小说ID
    var bookID:String!
    
    /// 章节ID
    var id:String!
    
    /// 章节名称
    var name:String!
    
    /// 优先级 (一般章节段落都带有排序的优先级 从 0 开始)
    var priority:NSNumber!
    
    // MARK: -- 获取章节模型
    class func readChapterModel(bookID: String, contentID: String, isUpdateFont:Bool = false) ->DZMReadChapterModel? {
        
        if DZMReadChapterModel.IsExistReadChapterModel(bookID: bookID, chapterID: contentID) {
            
            return DZMReadChapterModel.readChapterModel(bookID: bookID, chapterID: contentID, isUpdateFont: isUpdateFont)
        }
        
        return nil
    }
    
    // MARK: -- 操作
    func readChapterModel(isUpdateFont:Bool = false) ->DZMReadChapterModel? {
        
        if DZMReadChapterModel.IsExistReadChapterModel(bookID: bookID, chapterID: id) {
            
            return DZMReadChapterModel.readChapterModel(bookID: bookID, chapterID: id, isUpdateFont: isUpdateFont)
        }
        
        return nil
    }
    
    // MARK: -- NSCoding
    
    override init() {
        
        super.init()
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init()
        
        priority = aDecoder.decodeObject(forKey: "priority") as? NSNumber
        
        bookID = aDecoder.decodeObject(forKey: "bookID") as? String
        
        id = aDecoder.decodeObject(forKey: "id") as? String
        
        name = (aDecoder.decodeObject(forKey: "name") as! String)
        
        words_count = aDecoder.decodeInt32(forKey: "words_count")
        
        order = aDecoder.decodeInt32(forKey: "order")
        
        is_buy = aDecoder.decodeBool(forKey: "is_buy")
        
        price = aDecoder.decodeInt32(forKey: "price")
    }
    
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(priority, forKey: "priority")
        
        aCoder.encode(bookID, forKey: "bookID")
        
        aCoder.encode(id, forKey: "id")
        
        aCoder.encode(name, forKey: "name")
        
        aCoder.encode(words_count, forKey: "words_count")
        
        aCoder.encode(order, forKey: "order")
        
        aCoder.encode(is_buy, forKey: "is_buy")
        
        aCoder.encode(price, forKey: "price")
    }
}
