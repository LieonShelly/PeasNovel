//
//  DZMReadRecordModel.swift
//  ReaderKit
//
//  Created by lieon on 2017/5/12.
//  Copyright © 2018年lieon. All rights reserved.
//



import UIKit

struct ReaderSpecialChapterValue {
    /// 最后一页标示
    static  let lastPageValue:NSInteger = -1
    /// 版权页
    static  let firstPageValue: String = "copyright"
    /// 广告页的Id
    static let chapterConnectionId: String = "chapterConnectionId"
}

class DZMReadRecordModel: NSObject,NSCoding {
    
    /// 小说ID
    var bookID:String!
    
    /// 当前阅读到的章节模型
    var readChapterModel:DZMReadChapterModel?
    
    var page: Int = -1 
    
    var isFullScreenAd: Bool = false
    
    var isAdChapter: Bool! {
        return readChapterModel?.isAdChapter ?? false
    }
    var isBookLastPage: Bool {
        return isLastChapter && isLastPage
    }
    
    var isLastChapter: Bool! {
        return readChapterModel?.isLastChapter ?? false
    }
    var isFirstChapter: Bool {
        return readChapterModel?.isFirstChapter ?? false
    }
    
    var isFirstPage: Bool {
        return page == 0
    }
    
    var isLastPage: Bool {
        return page >= (readChapterModel?.pageCount ?? 0) - 1
    }
    
    var isCopyrightPage: Bool {
        return (readChapterModel?.id ?? "") == ReaderSpecialChapterValue.firstPageValue
    }
    
    override init() {
        
        super.init()
    }
    
     func nextPage() {
          print("pageViewController-page" + #function)
        page = min(page + 1, readChapterModel!.pageCount - 1)
    }
    
    func previousPage() {
        page = max(page - 1, 0)
    }
    
    /// 通过书ID 获得阅读记录模型 没有则进行创建传出
    class func readRecordModel(bookID:String, isUpdateFont:Bool = false, isSave:Bool = false) ->DZMReadRecordModel {
        var readModel:DZMReadRecordModel!
        if DZMReadRecordModel.IsExistReadRecordModel(bookID: bookID) { // 存在
            readModel = ReadKeyedUnarchiver(folderName: bookID, fileName: (bookID + "ReadRecord")) as? DZMReadRecordModel
            if isUpdateFont {
                readModel.updateFont(isSave: isSave)
            }
            debugPrint("currentRecord - readRecordModel:\(readModel.page)")
        }else{ // 不存在
            readModel = DZMReadRecordModel()
            readModel.bookID = bookID
        }
        
        return readModel!
    }
    
    // MARK: -- 操作
    
    /// 保存
    func save() {
        
        ReadKeyedArchiver(folderName: bookID, fileName: (bookID + "ReadRecord"), object: self)
    }
    
    func updateRecord(chapterID: String, toPage: NSInteger = 0, isSperatePage: Bool = false, isSave: Bool = false) {
        guard let _ = readChapterModel else {
            return
        }
        if isSperatePage {
            readChapterModel!.sepearatePage()
        }
        if chapterID == ReaderSpecialChapterValue.firstPageValue {
            page = -1
        } else if chapterID == ReaderSpecialChapterValue.chapterConnectionId {
            page = 0
        } else if toPage == ReaderSpecialChapterValue.lastPageValue {
            page = readChapterModel!.pageCount - 1
        }  else {
            page = toPage
        }
        if isSave {
            save()
            readChapterModel!.saveData()
        }
    }
  
    
    func modify(chapterID: String, toPage: NSInteger = 0, isUpdateFont: Bool = false, isSave: Bool = false) {
        if DZMReadChapterModel.IsExistReadChapterModel(bookID: bookID, chapterID: chapterID) {
            readChapterModel = DZMReadChapterModel.readChapterModel(bookID: bookID, chapterID: chapterID, isUpdateFont: isUpdateFont)
            if (readChapterModel?.pageCount ?? 0) == 0 {
                readChapterModel?.sepearatePage()
            }
            if chapterID == ReaderSpecialChapterValue.firstPageValue {
                page = -1
            } else if chapterID == ReaderSpecialChapterValue.chapterConnectionId {
                page = 0
            } else if toPage == ReaderSpecialChapterValue.lastPageValue {
                page = readChapterModel!.pageCount - 1
            }  else {
                page = toPage
            }
            if isSave {
                save()
            }
            let currentRecord = DZMReadRecordModel.readRecordModel(bookID: bookID)
            debugPrint("currentRecord:\(currentRecord.page)")
        } else {
            if isSave {
                readChapterModel?.saveData()
                save()
            }
        }
    }
    

    func modify(readMarkModel:DZMReadMarkModel, isUpdateFont:Bool = false, isSave:Bool = false) {
        if DZMReadChapterModel.IsExistReadChapterModel(bookID: readMarkModel.bookID, chapterID: readMarkModel.id) {
            readChapterModel = DZMReadChapterModel.readChapterModel(bookID: bookID, chapterID: readMarkModel.id, isUpdateFont: isUpdateFont)
            page = readChapterModel!.page(location: readMarkModel.location.intValue)
            if isSave {
                save()
            }
        }
    }
    
    /// 刷新字体 
    func updateFont(isSave:Bool = false) {
        if readChapterModel != nil {
            readChapterModel!.updateFont()
            if readChapterModel?.content != nil {
                readChapterModel!.saveData()
            }
            if isSave {
                save()
            }
        }
    }
    
    /// 是否存在阅读记录模型
    class func IsExistReadRecordModel(bookID:String) ->Bool {
        
        return ReadKeyedIsExistArchiver(folderName: bookID, fileName: (bookID + "ReadRecord"))
    }
    
    // MARK: -- NSCoding
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init()
        bookID = (aDecoder.decodeObject(forKey: "bookID") as! String)
        readChapterModel = aDecoder.decodeObject(forKey: "readChapterModel") as? DZMReadChapterModel
        page = aDecoder.decodeInteger(forKey: "page")
    }
    
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(bookID, forKey: "bookID")
        
        aCoder.encode(readChapterModel, forKey: "readChapterModel")
        
        aCoder.encode(page, forKey: "page")
    }
    
    // MARK: -- 拷贝
    func copySelf() ->DZMReadRecordModel {
        let readRecordModel = DZMReadRecordModel()
        readRecordModel.isFullScreenAd = isFullScreenAd
        readRecordModel.bookID = bookID
        readRecordModel.readChapterModel = readChapterModel
        readRecordModel.page = page
        return readRecordModel
    }
}
