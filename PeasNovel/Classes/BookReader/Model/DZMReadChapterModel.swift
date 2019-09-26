//
//  DZMReadChapterModel.swift
//  ReaderKit
//
//  Created by lieon on 2017/5/12.
//  Copyright © 2018年lieon. All rights reserved.
//

import UIKit
import RealmSwift
import YYText

class DZMReadChapterModel: NSObject,NSCoding {
    /// 小说ID 
    var bookID:String!
    /// 章节ID
    var id:String!
    /// 上一章 章节ID
    var lastChapterId:String?
    /// 下一章：章节ID
    var nextChapterId:String?
    /// 是否刚才更新过
    var isUpdate = false
    /// 章节名称
    var name:String!
    /// 完整章节名称
    var fullName:String! { return DZMContentTitle(name) }

    /// 内容
    var content:String!
    /// 优先级 (一般章节段落都带有排序的优先级 从 0 开始)
    var priority:NSNumber!
    
    /// 章节付费信息
    var chargeInfo: NovelChargeInfo?
    
    /// 本章有多少页
    var pageCount: Int = 0
    
    /// 每一页的Range数组
   fileprivate var rangeArray:[NSRange] = []
    
    /// 书籍信息
    var bookInfo: ChapterBookInfo?
    
    /// 版权信息
    var cp_info: ChapterCopyRightInfo?
    
    /// 价格
    var price: UInt32 = 0
    
    var is_buy: Bool = true
    /// 下一章
    var next_chapter: ChapterInfo?
    /// 上一章
    var last_chapter: ChapterInfo?
    /// 章节号
    var order: Int = -1111
    /// 当前章节是否为第一个章节
    var isFirstChapter:Bool! { return (lastChapterId ?? "").isEmpty }
    /// 当前章节是否为最后一个章节
    var isLastChapter:Bool! { return (nextChapterId ?? "").isEmpty}
    /// 当前章节是否是广告页
    var isAdChapter: Bool {
        return id == ReaderSpecialChapterValue.chapterConnectionId
    }
    /// 记录该章使用的字体属性
    private var readAttribute:[NSAttributedString.Key:Any] = [:]
    private var nameAttribute:[NSAttributedString.Key:Any] = [:]
    var aTagModels: [ATagModel]!
    var fullContent: NSMutableAttributedString!
    var pageModels: [ChapterPageModel] = []
    var pageInfoAdView: Set<ReaderPageAdView> = []
    var onlyText: String?
    var attchModels: [AttachmentModel] = []
    var pageInfoAdConfig: TempAdvertise?
    var fullScreenAdConfig: TempAdvertise?
    let lock = NSLock()
    /// 更新字体
    func updateFont(isSave:Bool = false) {
        
        let nameAttribute = DZMReadConfigure.shared().readAttribute(isPaging: true, isTitle: true)
        
        let readAttribute = DZMReadConfigure.shared().readAttribute(isPaging: true, isTitle: false)
        
        if !NSDictionary(dictionary: self.readAttribute).isEqual(to: readAttribute) || !NSDictionary(dictionary: self.nameAttribute).isEqual(to: nameAttribute) {
            self.nameAttribute = nameAttribute
            self.readAttribute = readAttribute
            if isSave {
                saveData()
            }
        }
    }
    
    
    /// 强制更新字体
    func justUpdateFont() {
        
        let nameAttribute = DZMReadConfigure.shared().readAttribute(isPaging: true, isTitle: true)
        let readAttribute = DZMReadConfigure.shared().readAttribute(isPaging: true, isTitle: false)
        self.nameAttribute = nameAttribute
        self.readAttribute = readAttribute
        saveData()
    }
    
    func sepearatePage() {
        if name == nil {
            return
        }
        if content == nil {
            return
        }
        lock.lock()
        let newContent = NSMutableAttributedString()
        let nameAttribute = DZMReadConfigure.shared().readAttribute(isPaging: true, isTitle: true)
        let readAttribute = DZMReadConfigure.shared().readAttribute(isPaging: true, isTitle: false)
        let fullTitle = DZMContentTitle(name)
        let nameString = NSMutableAttributedString(string: fullTitle, attributes: nameAttribute)
        let result = DZMReadParser.replaceATag(content, attributes: readAttribute)
        let attrString = result.1
        newContent.append(nameString)
        newContent.append(NSMutableAttributedString(string: "  ", attributes: readAttribute))
        newContent.append(attrString)
        aTagModels = result.2
        fullContent = newContent
        rangeArray = DZMReadParser.ParserPageRange(attrString: newContent, rect: GetReadViewFrame())
        if pageInfoAdConfig == nil, let config = AdvertiseService.advertiseConfig(.readerPageInfoAd) {
            pageInfoAdConfig = TempAdvertise(config)
        }
        attchModels.removeAll()
        while getAdPageIndexies(rangeArray).count != attchModels.count {
            let pageIndexes = getAdPageIndexies(rangeArray)
            for pageIndex in pageIndexes {
                seperatePage(with: pageIndex)
            }
        }
        let ranges = DZMReadParser.ParserPageRange(attrString: fullContent, rect: GetReadViewFrame())
        rangeArray = ranges
        pageCount = ranges.count
        pageModels.removeAll()
        onlyText = fullTitle + result.0
        for (index, range) in ranges.enumerated() {
            let model = ChapterPageModel()
            let attrText = NSMutableAttributedString(attributedString: fullContent.attributedSubstring(from: range))
            model.range = range
            model.pangeContent = attrText
            model.page = index
            model.text = attrText.string
            model.oririnalText = attrText
            model.bookId = self.bookID
            model.contentId = self.id
            pageModels.append(model)
        }
        insertFullScreenAd()
        lock.unlock()
    }
  
    fileprivate func getAdPageIndexies(_ rangeArray: [NSRange]) -> [Int] {
        var pageIndexes: [Int] = []
        let result = ReaderAdService.shouldShowChapterpageAd()
        if !result.isShow {
            return []
        }
        for index in 0 ..< rangeArray.count {
            if let pageInfoAdConfig = self.pageInfoAdConfig, pageInfoAdConfig.is_close {
                break
            }
            guard let read_page_ad_num = CommomData.share.switcherConfig.value?.read_page_ad_num, read_page_ad_num != 0 else {
                break
            }
            let a0 = 0 + read_page_ad_num - 1
            let d = read_page_ad_num
            let pageIndex = a0 + index * d
            if pageIndex < rangeArray.count {
                pageIndexes.append(pageIndex)
            }
        }
        return pageIndexes
    }
    
    
    fileprivate func createSpaceAttribute(_ height: CGFloat, width: CGFloat) -> [NSAttributedString.Key : Any] {
        struct RunStruct {
            let ascent: CGFloat
            let descent: CGFloat
            let width: CGFloat
        }
        let height: CGFloat = height
        let extenBuffer = UnsafeMutablePointer<RunStruct>.allocate(capacity: 1)
        extenBuffer.initialize(to: RunStruct(ascent: height, descent: 0, width: width))
        var callbacks = CTRunDelegateCallbacks(version: kCTRunDelegateVersion1, dealloc: { (pointer) in
            
        }, getAscent: { (pointer) -> CGFloat in
            let d = pointer.assumingMemoryBound(to: RunStruct.self)
            return d.pointee.ascent
        }, getDescent: { (pointer) -> CGFloat in
            let d = pointer.assumingMemoryBound(to: RunStruct.self)
            return d.pointee.descent
        }, getWidth: {  (pointer) -> CGFloat in
            let d = pointer.assumingMemoryBound(to: RunStruct.self)
            return d.pointee.width
        })
        let delegate = CTRunDelegateCreate(&callbacks, extenBuffer)
        let attrDictionaryDelegate = [(kCTRunDelegateAttributeName as NSAttributedString.Key): (delegate as Any)]
        return attrDictionaryDelegate
    }
    
    fileprivate func seperatePage(with pageIndex: Int) {
//        print("seperatePage: pageIndex: \(pageIndex) - rangeArray:\(rangeArray.count) - attchModels:\(attchModels.count)")
        if pageIndex >= rangeArray.count {
            return
        }
        if attchModels.contains(where: { $0.page == pageIndex }) {
            return
        }
        if pageInfoAdConfig == nil, let config = AdvertiseService.advertiseConfig(.readerPageInfoAd)  {
            pageInfoAdConfig = TempAdvertise(config)
        }
        let range = rangeArray[pageIndex]
        let contentAttr = fullContent.attributedSubstring(from: range)
        let frameRef = DZMReadParser.GetReadFrameRef(attrString: NSMutableAttributedString(attributedString: contentAttr), rect: GetReadViewFrame())
        let lines = CTFrameGetLines(frameRef) as! [CTLine]
        var lineIndex: Int = 3
        if lineIndex >= lines.count {
            lineIndex = lines.count - 1
        }
        let line = lines[lineIndex]
        let onelocation = DZMReadParser.getLineStartLocation(line)
        let page = pageIndex
        let pageUIConfig = ReaderPageAdUIConfig()
        let adSize = pageUIConfig.infoAdSize(AdvertiseType(rawValue: pageInfoAdConfig?.ad_type ?? 0))
        let width = adSize.width
        let attrDictionaryDelegate = createSpaceAttribute(adSize.height, width: width)
        let attchSpace = NSAttributedString(string: " ", attributes: attrDictionaryDelegate)
        var location: Int = range.location + onelocation
        if location >= fullContent.length {
            location = fullContent.length
        }
        let attchModel = AttachmentModel()
        attchModel.location = location
        attchModel.page = page
        if let index = attchModels.firstIndex(where: {$0.page == page}) {
            attchModels[index] = attchModel
        } else {
            attchModels.append(attchModel)
        }
        attchModels.sort { (model0, model1) -> Bool in
            return model1.page > model1.page
        }
        let space = NSAttributedString(string: "\n",  attributes: readAttribute)
        fullContent.insert(space, at: location - 1)
        fullContent.insert(attchSpace, at: location)
        if (location + 1) > fullContent.length {
            fullContent.append(space)
        } else {
            fullContent.insert(space, at: location + 1)
        }
        if (location + 2) > fullContent.length {
            fullContent.append(space)
        } else {
            fullContent.insert(space, at: location + 2)
        }
        let ranges = DZMReadParser.ParserPageRange(attrString: fullContent, rect: GetReadViewFrame())
        rangeArray = ranges
    }
    
    func attachModel(with page: Int) -> AttachmentModel? {
        if let index = attchModels.firstIndex(where:  { $0.page == page}) {
            return attchModels[index]
        }
        return nil
    }
    
    
    fileprivate func fullScreenAdVC(_ page: Int) -> UIViewController? {
     
        guard  let chapterPageFullScreenAdNum = CommomData.share.switcherConfig.value?.read_page_full_screen_ad_num,
            chapterPageFullScreenAdNum != 0 else {
                return nil
        }
        let d = chapterPageFullScreenAdNum
        let a0 = 0 + d - 1
        let result = ReaderAdService.shouldShowFullScreenAd() 
        if (page - a0) % d == 0, result.isShow {
            guard let config = result.config else {
                return nil
            }
            let viewModel = ReaderFullPicAdViewModel(config)
            let vcc = ReaderFullPicAdViewController(viewModel)
            return vcc
        }
        return nil
    }
    
    
    fileprivate func getFullScreenAdIndexies(_ rangeArray: [NSRange]) -> [Int] {
        var pageIndexes: [Int] = []
        let result = ReaderAdService.shouldShowFullScreenAd()
        if !result.isShow {
            return []
        }
        for index in 0 ..< rangeArray.count {
            if let fullScreenAdConfig = self.fullScreenAdConfig, fullScreenAdConfig.is_close {
                break
            }
            guard let read_page_full_screen_ad_num = CommomData.share.switcherConfig.value?.read_page_full_screen_ad_num, read_page_full_screen_ad_num != 0 else {
                break
            }
            let a0 = 0 + read_page_full_screen_ad_num - 1
            let d = read_page_full_screen_ad_num
            let pageIndex = a0 + index * d
            if pageIndex < rangeArray.count {
                pageIndexes.append(pageIndex)
            }
        }
        return pageIndexes
        
    }
    
    fileprivate func insertFullScreenAd() {
        if fullScreenAdConfig == nil, let config = AdvertiseService.advertiseConfig(.readerPageFullScreenAd) {
            fullScreenAdConfig = TempAdvertise(config)
        }
        let adIndexs = getFullScreenAdIndexies(rangeArray)
        for fullScreenIndex in adIndexs {
            let adPage = ChapterPageModel()
            let fullVM = ReaderFullPicAdViewModel(LocalAdvertise(fullScreenAdConfig!))
            adPage.type = .fullScreenAd(fullVM)
            adPage.page = fullScreenIndex
            let rightPageModels = pageModels[fullScreenIndex ..< pageModels.count]
            for pageModel in rightPageModels {
                pageModel.page += 1
            }
            for attchModel in attchModels where attchModel.page >= fullScreenIndex {
                attchModel.page += 1
            }
            pageModels.insert(adPage, at: fullScreenIndex)
        }
        pageCount = pageModels.count
        debugPrint("adIndexs:\(adIndexs) - pageCount:\(pageCount)")

    }
    

    override init() {
        super.init()
        if pageInfoAdConfig == nil, let config = AdvertiseService.advertiseConfig(.readerPageInfoAd)  {
            pageInfoAdConfig = TempAdvertise(config)
        }
    }
    
    class func readChapterModel(bookID:String, chapterID:String, isUpdateFont:Bool = false) -> DZMReadChapterModel {
        
        if DZMReadChapterModel.IsExistReadChapterModel(bookID: bookID, chapterID: chapterID),
            let readChapterModel = ReadKeyedUnarchiver(folderName: bookID, fileName: chapterID) as? DZMReadChapterModel{ // 存在
            if isUpdateFont {
                readChapterModel.updateFont(isSave: true)
            }
             return readChapterModel
        }else{ // 不存在
          let readChapterModel = DZMReadChapterModel()
            readChapterModel.bookID = bookID
            readChapterModel.id = chapterID
             return readChapterModel
        }
        
    }
    
    class func readChapterNeedPay(bookID:String, chapterID:String) -> Bool {
        
        if DZMReadChapterModel.IsExistReadChapterModel(bookID: bookID, chapterID: chapterID), let readChapterModel = ReadKeyedUnarchiver(folderName: bookID, fileName: chapterID) as? DZMReadChapterModel { // 存在
            return readChapterModel.is_buy
        }
        return false
    }
    
    class func readChapterBookInfo(bookID:String, chapterID:String) -> ChapterBookInfo? {
        
        if DZMReadChapterModel.IsExistReadChapterModel(bookID: bookID, chapterID: chapterID), let readChapterModel = ReadKeyedUnarchiver(folderName: bookID, fileName: chapterID) as? DZMReadChapterModel { // 存在
            return readChapterModel.bookInfo
        }
        
        return nil
    }
    

    func pageModel(page: Int) -> ChapterPageModel? {
        debugPrint("pageModel - page:\(page)")
        guard !pageModels.isEmpty else {
            return nil
        }
        var page = page
        if page >= pageModels.count {
            page = pageModels.count - 1
        } else if page < 0 {
            page = 0
        }
        let pageModel = pageModels[page]
        if case ChapterPageType.fullScreenAd = pageModel.type {
            return pageModel
        }
        guard let content = pageModel.oririnalText else {
            return nil
        }
        var pangeContent = NSMutableAttributedString(attributedString: content)
        let result = DZMReadParser.matchSogouKeyWords(pangeContent)
        pangeContent = result.0
        pageModel.pangeContent = pangeContent
        let sogouAtagModels = result.1
        for sogouAtagModel in sogouAtagModels {
            if let index = self.aTagModels.firstIndex(where: { $0.href == sogouAtagModel.href}) {
                self.aTagModels[index] = sogouAtagModel
            } else {
                 self.aTagModels.append(sogouAtagModel)
            }
        }
          return pageModel
    }
    
    func getPageModel(with page: Int, pageAdIdex: Int) -> ChapterPageModel {
        if page >= pageModels.count || page < 0 {
            return ChapterPageModel()
        }
        let pageModel = pageModels[page]
        guard let content = pageModel.oririnalText else {
            return  ChapterPageModel()
        }
         var pangeContent = NSMutableAttributedString(attributedString: content)
        if page == pageAdIdex {
            if pageInfoAdConfig == nil, let config = AdvertiseService.advertiseConfig(.readerPageInfoAd)  {
                pageInfoAdConfig = TempAdvertise(config)
            }
            let pageUIConfig = ReaderPageAdUIConfig()
            let adSize = pageUIConfig.infoAdSize(AdvertiseType(rawValue: pageInfoAdConfig?.ad_type ?? 0))
            let spaceAttribute = createSpaceAttribute(adSize.height, width: adSize.width)
            let space = NSAttributedString(string: " ", attributes: spaceAttribute)
            let readAttribute = DZMReadConfigure.shared().readAttribute(isPaging: true, isTitle: false)
            let whiteLine = NSAttributedString(string: "\n", attributes: readAttribute)
            let location: Int = 20
            if location + 1 < pangeContent.length {
                pangeContent.insert(whiteLine, at: location - 1)
                pangeContent.insert(space, at: location)
                pangeContent.insert(whiteLine, at: location + 1)
            }
        }
       
        let result = DZMReadParser.matchSogouKeyWords(pangeContent)
        pangeContent = result.0
        pageModel.pangeContent = pangeContent
        let sogouAtagModels = result.1
        for sogouAtagModel in sogouAtagModels {
            if let index = self.aTagModels.firstIndex(where: { $0.href == sogouAtagModel.href}) {
                self.aTagModels[index] = sogouAtagModel
            } else {
                self.aTagModels.append(sogouAtagModel)
            }
        }
        return pageModel
    }
    
    /// 通过 Page 获得字符串
    func string(page: NSInteger) -> NSMutableAttributedString {
        guard !pageModels.isEmpty else {
            return NSMutableAttributedString()
        }
        if page >= pageModels.count, let pangeContent = pageModels.last?.pangeContent {
            return NSMutableAttributedString(attributedString: pangeContent)
        }
        guard let pangeContent = pageModels[page].pangeContent  else {
            return NSMutableAttributedString()
        }
        return NSMutableAttributedString(attributedString: pangeContent)
    }

    /// 通过 Page 获得 Location
    func location(page:NSInteger) -> NSInteger {
        guard !pageModels.isEmpty, page >= 0 else {
            return 0
        }
        return pageModels[page].range?.location ?? 0
    }


    /// 通过 Location 获得 Page
    func page(location: NSInteger) ->NSInteger {
        let count = pageModels.count
        for i in 0 ..< count {
            if  let range = pageModels[i].range {
                if location < (range.location + range.length) {
                    return i
                }
            }
        }
        return 0
    }

    /// 保存
    func saveData() {
        ReadKeyedArchiver(folderName: bookID, fileName: id, object: self)
    }
    
    /// 是否存在章节内容模型
    class func IsExistReadChapterModel(bookID:String, chapterID:String) ->Bool {
        return ReadKeyedIsExistArchiver(folderName: bookID, fileName: chapterID)
    }
    
    required init?(coder aDecoder: NSCoder) {
        
        super.init()
        
        bookID = aDecoder.decodeObject(forKey: "bookID") as? String ?? ""
        
        id = aDecoder.decodeObject(forKey: "id") as? String ?? ""
        
        lastChapterId = aDecoder.decodeObject(forKey: "lastChapterId") as? String
        
        nextChapterId = aDecoder.decodeObject(forKey: "nextChapterId") as? String
        
        name = aDecoder.decodeObject(forKey: "name") as? String ?? ""
        
        priority = aDecoder.decodeObject(forKey: "priority") as? NSNumber ?? 1
        
        chargeInfo = aDecoder.decodeObject(forKey: "chargeInfo") as? NovelChargeInfo
    
        bookInfo = aDecoder.decodeObject(forKey: "bookInfo") as? ChapterBookInfo
        
        next_chapter = aDecoder.decodeObject(forKey: "next_chapter") as? ChapterInfo
        
        last_chapter = aDecoder.decodeObject(forKey: "last_chapter") as? ChapterInfo
        
        content = aDecoder.decodeObject(forKey: "content") as? String ?? ""
        
        pageCount = aDecoder.decodeObject(forKey: "pageCount") as? Int ?? 0
        
        order  = aDecoder.decodeInteger(forKey: "order")
        cp_info = aDecoder.decodeObject(forKey: "cp_info") as? ChapterCopyRightInfo
        rangeArray = aDecoder.decodeObject(forKey: "rangeArray") as? [NSRange] ?? []
        readAttribute = aDecoder.decodeObject(forKey: "readAttribute") as? [NSAttributedString.Key:Any] ?? [NSAttributedString.Key:Any]()
        nameAttribute = aDecoder.decodeObject(forKey: "nameAttribute") as? [NSAttributedString.Key:Any] ?? [NSAttributedString.Key:Any]()
        if pageInfoAdConfig == nil, let config = AdvertiseService.advertiseConfig(.readerPageInfoAd)  {
            pageInfoAdConfig = TempAdvertise(config)
        }
//        fullContent = fullContentAttrString()
    }
    
    
    
    func encode(with aCoder: NSCoder) {
        
        aCoder.encode(bookID, forKey: "bookID")
        
        aCoder.encode(id, forKey: "id")
        
        aCoder.encode(lastChapterId, forKey: "lastChapterId")
        
        aCoder.encode(nextChapterId, forKey: "nextChapterId")
        
        aCoder.encode(name, forKey: "name")
        
        aCoder.encode(priority, forKey: "priority")
        
        aCoder.encode(chargeInfo, forKey: "chargeInfo")
        
        aCoder.encode(bookInfo, forKey: "bookInfo")
        
        aCoder.encode(content, forKey: "content")
        
        aCoder.encode(pageCount, forKey: "pageCount")
        
        aCoder.encode(rangeArray, forKey: "rangeArray")
        
        aCoder.encode(readAttribute, forKey: "readAttribute")
        
        aCoder.encode(nameAttribute, forKey: "nameAttribute")
        
        aCoder.encode(next_chapter, forKey: "next_chapter")
        
        aCoder.encode(last_chapter, forKey: "last_chapter")
        
        aCoder.encode(order, forKey: "order")
        aCoder.encode(cp_info, forKey: "cp_info")
        
    }
}

extension DZMReadChapterModel {
    static func createNextAdChapter(_ currentChapter: DZMReadChapterModel) -> DZMReadChapterModel {
        let chapter = createAdChapter(currentChapter)
        let preChapterInfo = ChapterInfo()
        preChapterInfo.book_id = currentChapter.bookID
        preChapterInfo.content_id = currentChapter.id
        
        chapter.name = currentChapter.next_chapter?.title ?? ""
        chapter.last_chapter = preChapterInfo
        chapter.lastChapterId = currentChapter.id
        
        chapter.id = ReaderSpecialChapterValue.chapterConnectionId
        chapter.bookID = currentChapter.bookID
        chapter.next_chapter = currentChapter.next_chapter
        chapter.nextChapterId = currentChapter.nextChapterId
        chapter.pageCount = 1
        return chapter
    }
    
    static func createPreAdChapter(_ currentChapter: DZMReadChapterModel) -> DZMReadChapterModel {
        let chapter = createAdChapter(currentChapter)
        let nextChapterInfo = ChapterInfo()
        nextChapterInfo.book_id = currentChapter.bookID
        nextChapterInfo.content_id = currentChapter.id
        
        chapter.name = currentChapter.last_chapter?.title ?? ""
        chapter.last_chapter = currentChapter.last_chapter
        chapter.lastChapterId = currentChapter.lastChapterId
        
        chapter.id = ReaderSpecialChapterValue.chapterConnectionId
        chapter.bookID = currentChapter.bookID
        chapter.next_chapter = nextChapterInfo
        chapter.nextChapterId = currentChapter.id
        chapter.pageCount = 1
        return chapter
    }
    
    private static func createAdChapter(_ currentChapter: DZMReadChapterModel) -> DZMReadChapterModel  {
        let chapter = DZMReadChapterModel()
        chapter.last_chapter = currentChapter.last_chapter
        chapter.lastChapterId = currentChapter.lastChapterId
        chapter.id = ReaderSpecialChapterValue.chapterConnectionId
        chapter.bookID = currentChapter.bookID
        chapter.next_chapter = currentChapter.next_chapter
        chapter.nextChapterId = currentChapter.nextChapterId
        chapter.pageCount = 1
        return chapter
    }
}

struct ATagModel {
    var text: String?
    var href: String?
}


enum ChapterPageType {
    case text
    case fullScreenAd(ReaderFullPicAdViewModel)
    
    static func getValue(_ status: ChapterPageType) -> String {
        switch status {
        case .text:
            return "text"
        case .fullScreenAd:
            return "fullScreenAd"
        }
    }
}

class ChapterPageModel: NSObject {
    var oririnalText: NSAttributedString?
    var pangeContent: NSAttributedString?
    var page: Int = 0
    var range: NSRange?
    var text: String? {
        didSet {
         seperate()
        }
    }
    var bookId: String?
    var contentId: String?
    var textArray: [String] = []
    var type: ChapterPageType = .text
    
    func seperate() {
        if let text = self.text {
            textArray = text.components(separatedBy: CharacterSet.init(charactersIn: "。！?"))//.filter { !$0.isEmpty}
        } else {
            textArray = [""]
        }
    }
    
    
}

class AttachmentModel {
    var page: Int = 0
    var location: Int = 0 /// 在整个文本中的位置
    var content: UIResponder?
}
