//
//  DZMReadOperation.swift
//  ReaderKit
//
//  Created by lieon on 2017/5/15.
//  Copyright © 2018年lieon. All rights reserved.
//

import UIKit
import RxSwift
import Alamofire
import PKHUD
import Moya


extension ReaderController {
    
    func getReadViewController(readRecordModel: DZMReadRecordModel?) -> UIViewController? {
        if readRecordModel != nil {
            if readRecordModel?.readChapterModel?.id == ReaderSpecialChapterValue.firstPageValue,
                (DZMReadConfigure.shared().effectType == DZMRMEffectType.simulation.rawValue || DZMReadConfigure.shared().effectType == DZMRMEffectType.translation.rawValue),
                let cpInfo = readRecordModel?.readChapterModel?.cp_info {
                return ReaderBookIntroViewController(ReaderBookIntroViewModel(cpInfo))
            }
            let readViewController = ReaderViewController()
            readViewController.readRecordModel = readRecordModel?.copySelf()
            readViewController.readController = self
            return readViewController
        }
        return nil
    }
    
    func getCurrentReadViewController(isUpdateFont:Bool = false, isSave:Bool = false) ->UIViewController? {
        if readModel.readRecordModel != nil {
            if isUpdateFont {
                self.readModel.readRecordModel.readChapterModel?.sepearatePage()
                readModel.readRecordModel.updateFont(isSave: true)
            }
            if isSave {
                readRecordUpdate(readRecordModel: readModel.readRecordModel)
            }
            return getReadViewController(readRecordModel:readModel.readRecordModel.copySelf())
        }
        return nil
    }
    
    func getAboveReadViewController() -> UIViewController? {
        if readModel == nil,  readModel.readRecordModel == nil {
            return nil
        }
        let readRecordModel = readModel.readRecordModel.copySelf()
        guard  let currentChapter = readRecordModel.readChapterModel else {
            return nil
        }
        let id = currentChapter.id
        if id == ReaderSpecialChapterValue.firstPageValue {
            return nil
        }
        var page = readModel.readRecordModel.page
        if currentChapter.isAdChapter {
            page = 0
        }
        if page == 0 { // 这一章到头了
            if ReaderAdService.shouldShowBottomBannerAd().isShow {
                UISize.bannerHeight = UISize.adBannerHeight
            } else {
                UISize.bannerHeight = UISize.noAdBannerHeight
            }
            if readRecordModel.isAdChapter {
                guard let preChapterId = readModel.readRecordModel.readChapterModel?.lastChapterId, !preChapterId.isEmpty  else {
                    return nil
                }
                if DZMReadChapterModel.IsExistReadChapterModel(bookID: readModel.bookID, chapterID: preChapterId) {
                    readRecordModel.readChapterModel?.sepearatePage()
                    readRecordModel.modify(chapterID: preChapterId, toPage: ReaderSpecialChapterValue.lastPageValue, isUpdateFont: true, isSave: true)
                    return getReadViewController(readRecordModel: readRecordModel)
                } else {
                    self.goToChapter(chapterID: preChapterId, toPage: ReaderSpecialChapterValue.lastPageValue)
                    return nil
                }
            }
            guard let preChapterId = readModel.readRecordModel.readChapterModel?.lastChapterId, !preChapterId.isEmpty  else {
                return nil
            }
            if preChapterId == ReaderSpecialChapterValue.firstPageValue, let cpInfo = readRecordModel.readChapterModel?.cp_info  {
                readRecordModel.modify(chapterID: preChapterId, toPage: 0, isUpdateFont:false, isSave: false)
                readModel.readRecordModel = readRecordModel
                return ReaderBookIntroViewController(ReaderBookIntroViewModel(cpInfo))
            }
            if let id = readRecordModel.readChapterModel?.id,
                id !=  ReaderSpecialChapterValue.firstPageValue {
                if let adVC = ReaderAdService.createChapterConnectionVC(currenntReadChapterCount.value, title: readRecordModel.readChapterModel?.last_chapter?.title ?? "") {
                    let adChapter = DZMReadChapterModel.createPreAdChapter(currentChapter)
                    let newRecord = DZMReadRecordModel()
                    newRecord.readChapterModel = adChapter
                    newRecord.page = 0
                    newRecord.bookID = adChapter.bookID
                    readModel.readRecordModel = newRecord
                    return adVC
                }
            }
            if !DZMReadChapterModel.IsExistReadChapterModel(bookID: readModel.bookID, chapterID: preChapterId) {
                self.goToChapter(chapterID: preChapterId, toPage:  ReaderSpecialChapterValue.lastPageValue)
                return nil
            } else {
                readRecordModel.readChapterModel?.sepearatePage()
                readRecordModel.modify(chapterID: preChapterId, toPage:  ReaderSpecialChapterValue.lastPageValue, isUpdateFont:true, isSave: true)
                return getReadViewController(readRecordModel: readRecordModel)
            }
        } else  {
            readRecordModel.page = page - 1
        }
        /// 预加载
        if readRecordModel.page == 0 {
            let lastChapterId = readModel.readRecordModel.readChapterModel?.lastChapterId
            ReaderController.cache(readModel.bookID, contentId: lastChapterId)
        }
        if let contentId = id {
            let isSperatePage = readRecordModel.readChapterModel?.pageModels.isEmpty ?? true
            readRecordModel.updateRecord(chapterID: contentId, toPage: readRecordModel.page, isSperatePage: isSperatePage, isSave: isSperatePage)
        }
        return getReadViewController(readRecordModel: readRecordModel)
    }
    
    fileprivate func toReaderLastPage(_ contentId: String) {
        ReaderController.requestChapter(readModel.bookID,
                                        contentId: contentId,
                                        finished: { [weak self] res in
                                            let vcc = ReaderLastPageViewController(ReaderLastPageViewModel(["book_id": self!.readModel.bookID, "category_id_1": res.data?.book_info?.category_id_1 ?? ""]))
                                            let manager = NetworkReachabilityManager()
                                            guard let isReachable = manager?.isReachable, isReachable == true else {
                                                DefaultWireframe.presentAlert(title: "网络不可用", message: "")
                                                return
                                            }
                                            guard let navc = self?.navigationController else {
                                                return
                                            }
                                            guard let topViewController = navc.topViewController else {
                                                return
                                            }
                                            if topViewController is ReaderLastPageViewController {
                                                return
                                            }
                                            navc.pushViewController(vcc, animated: true)
        })
    }
    
    func getBelowReadViewController() -> UIViewController? {
        if readModel == nil || readModel.readRecordModel == nil {
            return nil
        }
        let readRecordModel = readModel.readRecordModel.copySelf()
        let id = readRecordModel.readChapterModel!.id
        let page = readRecordModel.page
        debugPrint("getBelowReadViewController - currentPage:\(page)")
        if readRecordModel.isBookLastPage, let contnetId = id {
            toReaderLastPage(contnetId)
            return nil
        }
        if readRecordModel.isAdChapter {
            guard let nextChapterId = readModel.readRecordModel.readChapterModel?.nextChapterId, !nextChapterId.isEmpty else {
                return nil
            }
            if DZMReadChapterModel.IsExistReadChapterModel(bookID: readModel.bookID, chapterID: nextChapterId) {
                readRecordModel.readChapterModel?.sepearatePage()
                readRecordModel.modify(chapterID: nextChapterId, isUpdateFont: true)
                return getReadViewController(readRecordModel: readRecordModel)
            } else {
                self.goToChapter(chapterID: nextChapterId, toPage: 0)
                return nil
            }
        }
        if readRecordModel.isLastPage {
            if ReaderAdService.shouldShowBottomBannerAd().isShow {
                UISize.bannerHeight = UISize.adBannerHeight
            } else {
                UISize.bannerHeight = UISize.noAdBannerHeight
            }
            if let id = readRecordModel.readChapterModel?.id, let currentChapter = readRecordModel.readChapterModel,
                id != ReaderSpecialChapterValue.firstPageValue {
                if let adVC = ReaderAdService.createChapterConnectionVC(currenntReadChapterCount.value, title: readRecordModel.readChapterModel?.next_chapter?.title ?? "") {
                    let adChapter = DZMReadChapterModel.createNextAdChapter(currentChapter)
                    let newRecord = DZMReadRecordModel()
                    newRecord.readChapterModel = adChapter
                    newRecord.page = 0
                    newRecord.bookID = adChapter.bookID
                    readModel.readRecordModel = newRecord
                    return adVC
                }
            }
            guard let nextChapterId = readModel.readRecordModel.readChapterModel?.nextChapterId, !nextChapterId.isEmpty else {
                return nil
            }
            if DZMReadChapterModel.IsExistReadChapterModel(bookID: readModel.bookID, chapterID: nextChapterId) {
                readRecordModel.readChapterModel?.sepearatePage()
                readRecordModel.modify(chapterID: nextChapterId, isUpdateFont: true, isSave: true)
                return getReadViewController(readRecordModel: readRecordModel)
            } else {
                self.goToChapter(chapterID: nextChapterId, toPage: 0)
                return nil
            }
        }
        
        if readRecordModel.isCopyrightPage  {
            guard let nextChapterId = readModel.readRecordModel.readChapterModel?.nextChapterId, !nextChapterId.isEmpty else {
                return nil
            }
            if DZMReadChapterModel.IsExistReadChapterModel(bookID: readModel.bookID, chapterID: nextChapterId) {
                readRecordModel.readChapterModel?.sepearatePage()
                readRecordModel.modify(chapterID: nextChapterId, isUpdateFont: true)
                return getReadViewController(readRecordModel: readRecordModel)
            } else {
                self.goToChapter(chapterID: nextChapterId, toPage: 0)
                return nil
            }
        }
        readRecordModel.page = page + 1
        /// 预加载
        let lastPage = readRecordModel.readChapterModel!.pageCount - 1
        if page == lastPage - 1 {
            let nextChapterId = readRecordModel.readChapterModel?.nextChapterId
            ReaderController.cache(readModel.bookID, contentId: nextChapterId)
        }
        if let contentId = id {
            let isSperatePage = readRecordModel.readChapterModel?.pageModels.isEmpty ?? true
            readRecordModel.updateRecord(chapterID: contentId, toPage: readRecordModel.page, isSperatePage: isSperatePage, isSave: isSperatePage)
        }
        return getReadViewController(readRecordModel: readRecordModel)
    }
    
    @discardableResult
    func goToChapter(chapterID:String, toPage:NSInteger = 0) -> Bool {

        if readModel != nil {
            if DZMReadChapterModel.IsExistReadChapterModel(bookID: readModel.bookID, chapterID: chapterID) { //  存在
                readModel.readRecordModel.readChapterModel?.sepearatePage()
                readModel.modifyReadRecordModel(chapterID: chapterID, page: toPage, isSave: true)
                creatPageController(getCurrentReadViewController(isUpdateFont: true, isSave: true))
                return true
            }else{ // 不存在
                ReaderController.cache(readModel.bookID, contentId: chapterID) { [weak self] res in
                    guard let `self` = self else { return }
                    if res.status?.code == 0 {
                        self.readModel.readRecordModel.readChapterModel?.sepearatePage()
                        self.readModel.modifyReadRecordModel(chapterID: chapterID, page: toPage, isSave: true)
                        self.creatPageController(self.getCurrentReadViewController(isUpdateFont: true, isSave: true))
                    } else {
                        HUD.flash(HUDContentType.errorTip(res.status?.msg ?? ""), delay: 2.0)
                    }
                }
                
                return false
            }
        }
        
        return false
    }
    
    func goToChapter(chapterID:String,  toPage:NSInteger = 0, completeHandler: (() -> Void)? = nil) {
        if readModel != nil {
            if DZMReadChapterModel.IsExistReadChapterModel(bookID: readModel.bookID, chapterID: chapterID) { //  存在
                 readModel.readRecordModel.readChapterModel?.sepearatePage()
                readModel.modifyReadRecordModel(chapterID: chapterID, page: toPage, isSave: false)
                creatPageController(getCurrentReadViewController(isUpdateFont: true, isSave: true))
                completeHandler?()
            }else{ // 不存在
                ReaderController.cache(readModel.bookID, contentId: chapterID) { [weak self] res in
                    guard let `self` = self else { return }
                    if res.status?.code == 0 {
                        self.readModel.readRecordModel.readChapterModel?.sepearatePage()
                        self.readModel.modifyReadRecordModel(chapterID: chapterID, page: toPage, isSave: false)
                        self.creatPageController(self.getCurrentReadViewController(isUpdateFont: true, isSave: true))
                        completeHandler?()
                    } else {
                        HUD.flash(HUDContentType.errorTip(res.status?.msg ?? ""), delay: 2.0)
                    }
                }
            }
        }
    }
    
    /// 更新记录
    func readRecordUpdate(readRecordModel: DZMReadRecordModel?, isSave: Bool = true) {
        readModel.readRecordModel = readRecordModel
        guard let readRecordModel = readRecordModel, !readRecordModel.isAdChapter  else {
            return
        }
        if isSave {
            readModel.readRecordModel.save()
            DispatchQueue.main.async {
                self.readMenu?.progressView.sliderUpdate()
            }
        }
    }
    
}

extension ReaderController {
    
   class func cache(_ bid: String, contentId: String?, finished: ((ChapterContentResponse) -> ())? = nil) {
    
     func cachePreNextChapter(_ bid: String, contentId: String) {
        let chapter = DZMReadChapterModel.readChapterModel(bookID: bid, chapterID: contentId)
        if let nextChapterId = chapter.nextChapterId, !nextChapterId.isEmpty , !DZMReadChapterModel.IsExistReadChapterModel(bookID: bid, chapterID: nextChapterId) {
            requestChapter(bid, contentId: nextChapterId)
        }
        if let preChapterId = chapter.lastChapterId, !preChapterId.isEmpty, !DZMReadChapterModel.IsExistReadChapterModel(bookID: bid, chapterID: preChapterId)  {
            requestChapter(bid, contentId: preChapterId)
        }
    }
        if let contentId = contentId {
            if DZMReadChapterModel.IsExistReadChapterModel(bookID: bid, chapterID: contentId) {
                let res = ChapterContentResponse()
                let status = ReponseResult()
                status.code = 0
                res.status = status
                if let finished = finished {
                    finished(res)
                }
                return
            }
        }
        requestChapter(bid, contentId: contentId, finished: { res in
            finished?(res)
            if let contentId = contentId {
                cachePreNextChapter(bid, contentId: contentId)
            }
        })
    }

   class func requestChapter(_ bid: String, contentId: String?, finished: ((ChapterContentResponse) -> ())? = nil) {
        let provider = MoyaProvider<BookReaderService>()
        let _ = provider
            .rx
            .request(BookReaderService.chapterContent(["book_id": bid, "content_id": contentId ?? ""]))
            .model(ChapterContentResponse.self)
            .subscribe{ event in
                switch event {
                case let .success(response):
                    if let model = response.data, response.status?.code == 0 {
                         cacheData(model)
                    }
                    if let finished = finished {
                        finished(response)
                    }
                case .error:
                    if let finished = finished {
                        let response = ChapterContentResponse()
                        let status = ReponseResult()
                        status.code = -1
                        status.msg = "章节加载失败"
                        response.status = status
                        finished(response)
                    }
                    break
                }
        }
        
    }
    
    class func cacheChapterData(_ chapter: ChapterContent) -> DZMReadChapterModel? {
        let readChapterModel = DZMReadChapterModel.readChapterModel(bookID: chapter.book_id , chapterID: chapter.content_id ?? "")
        guard let content = chapter.content, let name = chapter.title else {
            return nil
        }
        readChapterModel.bookID = chapter.book_id
        readChapterModel.id = chapter.content_id
        readChapterModel.priority = 1
        readChapterModel.name = chapter.title
        readChapterModel.order = Int(chapter.order)
        readChapterModel.bookInfo = chapter.book_info
        readChapterModel.cp_info = chapter.cp_info
        readChapterModel.next_chapter = chapter.next_chapter
        readChapterModel.last_chapter = chapter.last_chapter
        readChapterModel.content = content
        readChapterModel.lastChapterId = chapter.last_chapter?.content_id
        readChapterModel.nextChapterId = chapter.next_chapter?.content_id
        readChapterModel.content = DZMParagraphHeaderSpace + content.replacingOccurrences(of: name, with: "").removeSpaceHeadAndTailPro
        readChapterModel.chargeInfo = nil
        readChapterModel.justUpdateFont()
        /// 版权页
        if chapter.order == 1 { /// 判断是否是第一章
            let cpChapter =  DZMReadChapterModel.readChapterModel(bookID: chapter.book_id , chapterID: ReaderSpecialChapterValue.firstPageValue)
            cpChapter.bookID = chapter.book_id
            cpChapter.order = 0
            cpChapter.content = ""
            cpChapter.bookInfo = chapter.book_info
            let cpNextChapter = ChapterInfo()
            cpNextChapter.book_id = chapter.book_id
            cpNextChapter.content_id = chapter.content_id
            cpNextChapter.words_count = "\(chapter.words_count)"
            cpNextChapter.title = chapter.title
            cpNextChapter.order = "1"
            cpNextChapter.price = "\(chapter.price)"
            cpChapter.next_chapter = cpNextChapter
            cpChapter.nextChapterId = chapter.content_id
            cpChapter.last_chapter = chapter.last_chapter
            cpChapter.lastChapterId = nil
            cpChapter.id =  ReaderSpecialChapterValue.firstPageValue
            cpChapter.cp_info =  chapter.cp_info
            cpChapter.pageCount = 1
            cpChapter.saveData()
            readChapterModel.lastChapterId =  cpChapter.id /// 第一章的上一页是版权页
        }
        readChapterModel.saveData()
        return readChapterModel
    }
    
    static func generateCopyrightInfoPage() {
        
    }
    
    /// 存储章节
    class func cacheData(_ chapter: ChapterContent) {
        let readModel = DZMReadModel.readModel(bookID: chapter.book_id )
        guard let readChapterModel = cacheChapterData(chapter) else {
            return
        }
        let readChapterListModel = DZMReadChapterListModel()
        readChapterListModel.bookID = readChapterModel.bookID
        readChapterListModel.id = readChapterModel.id
        readChapterListModel.name = readChapterModel.name
        readChapterListModel.priority = readChapterModel.priority
        readChapterListModel.order = chapter.order
        readChapterListModel.words_count = chapter.words_count
        readChapterListModel.price = chapter.price
        readChapterListModel.is_buy = true
        readModel.updateChapterListModel(readChapterListModel)
        let info = ["book_id": chapter.book_id, "chapter_id": chapter.content_id]
        
        NotificationCenter.default.post(name: Notification.Name.Book.subscribe,
                                        object: nil,
                                        userInfo: info as [AnyHashable : Any])
        if readModel.readRecordModel.readChapterModel == nil || readModel.readRecordModel.readChapterModel?.content.isEmpty == true {
            if chapter.order == 1 {
                readModel.modifyReadRecordModel(chapterID:  ReaderSpecialChapterValue.firstPageValue)
            } else {
                readModel.modifyReadRecordModel(chapterID: chapter.content_id ?? "")
            }
           
        }
        readModel.name = chapter.book_info?.book_title ?? ""
        readModel.save()
    }
    
    
    class func preRequestChapter(_ bid: String, contentId: String?, finished: ((DZMReadChapterModel?) -> ())? = nil) {
        guard let contentId = contentId else {
            return
        }
        if DZMReadChapterModel.IsExistReadChapterModel(bookID: bid, chapterID: contentId) {
            let chpater = DZMReadChapterModel.readChapterModel(bookID: bid, chapterID: contentId)
            finished?(chpater)
        } else {
            let provider = MoyaProvider<BookReaderService>()
            let _ = provider
                .rx
                .request(BookReaderService.chapterContent(["book_id": bid, "content_id": contentId]))
                .model(ChapterContentResponse.self)
                .subscribe{ event in
                    switch event {
                    case let .success(response):
                        if let chapter = response.data, response.status?.code == 0 {
                            let dzChapter = cacheChapterData(chapter)
                            finished?(dzChapter)
                        }
                    case .error:
                        if let finished = finished {
                            finished(nil)
                        }
                        break
                    }
            }
        }
       
    }
    
}


