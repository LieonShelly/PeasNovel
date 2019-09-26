//
//  DZMReadModel.swift
//  ReaderKit
//
//  Created by lieon on 2017/5/12.
//  Copyright © 2018年lieon. All rights reserved.
//

import UIKit

private let prefix = "book-"

open class DZMReadModel: NSObject,NSCoding {
    
    /// 小说ID
    var bookID:String!
    
    /// 增：小说名称
    var name: String?
    
    /// 是否为本地小说
    var isLocalBook:NSNumber = NSNumber(value: 0)

    /// 章节列表数组（章节列表不包含章节内容, 它唯一的用处就是在阅读页面给用户查看章节列表）
    var readChapterListModels:[DZMReadChapterListModel] = [DZMReadChapterListModel]()
    
    /// 章节目录是否缓存完成
    var readChapterListCached: Bool = false
    
    /// 阅读记录
    var readRecordModel:DZMReadRecordModel! {
        didSet {
            print("didSet - readRecordModel")
        }
    }
    
    /// 书签列表
    private(set) var readMarkModels:[DZMReadMarkModel] = [DZMReadMarkModel]()
    
    /// 当前书签(用于记录使用)
    private(set) var readMarkModel:DZMReadMarkModel?
    
    // MARK: -- init
    
    private override init() {
        
        super.init()
    }
    
    func addChpterListModel(_ model: DZMReadChapterListModel) {
        var isExistChapterListModel = false
        for listModel in readChapterListModels {
            if listModel.bookID == model.bookID && listModel.id == model.id {
                isExistChapterListModel = true
            }
        }
        if !isExistChapterListModel {
            readChapterListModels.append(model)
        }
        readChapterListModels.sort { return $0.order < $1.order }
    }
    
    func updateChapterListModel(_ model: DZMReadChapterListModel) {
        
        for (idx, listModel) in readChapterListModels.enumerated() {
            if listModel.bookID == model.bookID && listModel.id == model.id {
                readChapterListModels[idx] = model
                save()
                return
            }
        }
    }
    
    /// 获得阅读模型
    class func readModel(bookID:String) ->DZMReadModel {
        
        var readModel:DZMReadModel!
        
        let fileName = prefix + bookID
        if DZMReadModel.IsExistReadModel(bookID: bookID) { // 存在
            if let model = ReadKeyedUnarchiver(folderName: bookID, fileName: fileName) as? DZMReadModel {
                readModel = model
            }else{
                ReadKeyedRemoveArchiver(folderName: bookID, fileName: fileName)
                readModel = DZMReadModel()
                readModel.bookID = bookID
            }
            
        } else {
            readModel = DZMReadModel()
            readModel.bookID = bookID
        }
        readModel!.readRecordModel = DZMReadRecordModel.readRecordModel(bookID: bookID)
        
        // 返回
        return readModel!
    }
    
    func modifyReadRecordModel(chapterID:String, page:NSInteger = 0, isUpdateFont:Bool = false, isSave:Bool = false) {
        
        readRecordModel.modify(chapterID: chapterID, toPage: page, isUpdateFont: isUpdateFont, isSave: isSave)
    }
    
    func modifyReadRecordModel(readMarkModel:DZMReadMarkModel, isUpdateFont:Bool = false, isSave:Bool = false) {
        
        readRecordModel.modify(readMarkModel: readMarkModel, isUpdateFont: isUpdateFont, isSave: isSave)
    }
    

    func save() {
        let fileName = prefix + bookID
        ReadKeyedArchiver(folderName: bookID, fileName: fileName, object: self)
        readRecordModel.save()
    }
    
    class func IsExistReadModel(bookID:String) ->Bool {
        let fileName = prefix + bookID
        return ReadKeyedIsExistArchiver(folderName: bookID, fileName: fileName)
    }
    
    func GetReadChapterListModel(chapterID:String) ->DZMReadChapterListModel? {
        
       return readChapterListModels.filter { (model) -> Bool in
            
            return model.id == chapterID
            
        }.first
    }
    
    func addMark(readRecordModel:DZMReadRecordModel? = nil) {
        if  checkMark(readRecordModel: readRecordModel) {
            return
        }
        
        let readRecordModel = (readRecordModel ?? self.readRecordModel)!
        
        let readMarkModel = DZMReadMarkModel()
        
        readMarkModel.bookID = readRecordModel.readChapterModel!.bookID
        
        readMarkModel.id = readRecordModel.readChapterModel!.id
        
        readMarkModel.name = readRecordModel.readChapterModel!.name
        
        readMarkModel.location = NSNumber(value: readRecordModel.readChapterModel!.location(page: readRecordModel.page))
        
        readMarkModel.content = readRecordModel.readChapterModel!.string(page: readRecordModel.page).string
        
        readMarkModel.time = Date()
        
        readMarkModels.append(readMarkModel)
        
        save()
        
        self.readMarkModel = readMarkModel
    }
    
    func removeMark(readMarkModel:DZMReadMarkModel? = nil, index:NSInteger? = nil) ->Bool {
        
        if index != nil {
           
            readMarkModels.remove(at: index!)
            
            save()
            
            return true
            
        }else{
            
            let readMarkModel = readMarkModel ?? self.readMarkModel
            
            if readMarkModel != nil && readMarkModels.contains(readMarkModel!) {
                
                readMarkModels.remove(at: readMarkModels.index(of: readMarkModel!)!)
                
                save()
                
                return true
            }
        }
        
        return false
    }
    
    func removeAllReadMark() {
        readMarkModels.removeAll()
        save()
    }
    
    /// 检查当前页面是否存在书签 默认使用当前阅读记录作为检查对象
    func checkMark(readRecordModel:DZMReadRecordModel? = nil) ->Bool {
        if self.readRecordModel == nil {
            return false
        }
        let readRecordModel = (readRecordModel ?? self.readRecordModel)!
        guard let readChapterModel =  readRecordModel.readChapterModel else {
            return false
        }
        let chapterID = readChapterModel.id
        
        let results = readMarkModels.filter { (model) -> Bool in
            return model.id == chapterID
         }
        if !results.isEmpty, readRecordModel.page < readRecordModel.readChapterModel!.pageModels.count {
            if  let range = readRecordModel.readChapterModel!.pageModels[readRecordModel.page].range {
                for readMarkModel in results {
                    let location = readMarkModel.location.intValue
                    if location >= range.location && location < (range.location + range.length) {
                        self.readMarkModel = readMarkModel
                        return true
                    }
                }
            }
        }
        readMarkModel = nil
        return false
    }
    
    // MARK: -- NSCoding
    
    required public init?(coder aDecoder: NSCoder) {
        
        super.init()
        
        bookID = aDecoder.decodeObject(forKey: "bookID") as? String
        
        name = aDecoder.decodeObject(forKey: "name") as? String
        
        isLocalBook = aDecoder.decodeObject(forKey: "isLocalBook") as! NSNumber
        
        readChapterListModels = aDecoder.decodeObject(forKey: "readChapterListModels") as! [DZMReadChapterListModel]
        
        readMarkModels = aDecoder.decodeObject(forKey: "readMarkModels") as! [DZMReadMarkModel]
        
        readChapterListCached = aDecoder.decodeBool(forKey: "readChapterListCached")
    }
    
    public func encode(with aCoder: NSCoder) {
        
        aCoder.encode(bookID, forKey: "bookID")
        
        aCoder.encode(name, forKey: "name")
        
        aCoder.encode(isLocalBook, forKey: "isLocalBook")
        
        aCoder.encode(readChapterListModels, forKey: "readChapterListModels")
        
        aCoder.encode(readMarkModels, forKey: "readMarkModels")
        
        aCoder.encode(readChapterListCached, forKey: "readChapterListCached")
    }
}
