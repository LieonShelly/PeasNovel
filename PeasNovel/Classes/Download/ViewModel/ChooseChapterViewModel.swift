//
//  ChooseChapterViewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/23.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import Moya
import RxMoya
import RxCocoa
import RxSwift
import Realm
import RxRealm
import RealmSwift
import HandyJSON

class ChooseChapterViewModel {
    /// input
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let bag = DisposeBag()
    let addBookshelfAction: PublishSubject<Void> = .init()
    let bookDetailInput: PublishSubject<Void> = .init()
    let activityDriver: Driver<Bool>
    let errorDriver: Driver<HUDValue>
    let shackingInput: PublishSubject<Void> = .init()
    let downloadInput: BehaviorRelay<DownloadChapterGroup> = .init(value: DownloadChapterGroup())
    let unlockInput: PublishSubject<DownloadChapterGroup> = .init()
    let itemSelectInput: PublishSubject<DownloadChapterGroup> = .init()
    let retryBtnInput: PublishSubject<DownloadChapterGroup> = .init()
    let waitBtnInput: PublishSubject<DownloadChapterGroup> = .init()
    var bannerViewModel: Advertiseable?
    
    /// output
    let dataDriver: Driver<[SectionModel<String, DownloadChapterGroup>]>
    let itemSelectOutput: Driver<ReaderViewModel>
    let bannerOutput = PublishSubject<LocalTempAdConfig>.init()
    let bannerConfigOutput: BehaviorRelay<LocalAdvertise?> = .init(value: nil)
    let unlockOutput: PublishSubject<AdPosition> = .init()
    let message: PublishSubject<HUDValue> = .init()
    
    
    init(_ bookId: String ) {
        let realm =  try! Realm(configuration: Realm.Configuration.defaultConfiguration)
        let activityIndicator = ActivityIndicator()
        let errorTracker = ErrorTracker()
        let dataResponse = PublishSubject<DownloadChapterGroupResponse>.init()
        let chapterGroupList: BehaviorRelay<[DownloadChapterGroup]> = .init(value: [])
        let downloadingInput: BehaviorRelay<DownloadChapterGroup?> = .init(value: nil)
        let chargeResponse = PublishSubject<NullResponse>.init()
        let payResponse = PublishSubject<DownloadChapterPayResponse>.init()
        let chapterContentResponse = PublishSubject<ChapterContentResponse>.init()
        let unlockChapterInput: BehaviorRelay<DownloadChapterGroup> = .init(value: DownloadChapterGroup())
        let message = self.message
        /// 下载的队列
        let totalDownloadChapters = BehaviorRelay<[DownloadChapterGroup]>.init(value: [])
        
        /// 书籍详情
        let bookDetail = BehaviorRelay<BookDetailModel>(value:BookDetailModel())
        let detailProvider = MoyaProvider<BookInfoService>()
        viewDidLoad
            .flatMap { _ in
                detailProvider
                    .rx
                    .request(.detail(bookId))
                    .model(BookDetailResponse.self)
                    .asObservable()
                    .catchError {_ in Observable.never()}
            }
            .map{ $0.data }
            .unwrap()
            .bind(to: bookDetail)
            .disposed(by: bag)
        
        /// 清除过期的章节
      viewDidLoad.asObservable()
        .subscribe(onNext: { (_) in
            let invalidChapters = realm.objects(DownloadLocalChapterGroupInfo.self).filter(NSPredicate(format: "book_id = %@ AND create_time > 0 AND create_time <= %lf AND status = %ld", bookId, Date().timeIntervalSince1970 - 24 * 60 * 60, DownloadStatus.unlock.rawValue))
            try? realm.write {
                realm.delete(invalidChapters)
            }
        })
        .disposed(by: bag)

        errorDriver = errorTracker.asDriver()
        activityDriver = activityIndicator.asDriver()
        
        itemSelectOutput = itemSelectInput.asObservable()
            .filter { $0.status.rawValue == DownloadStatus.success.rawValue }
            .flatMap{ info -> Observable<DZMReadModel> in
                return Observable<DZMReadModel>.create { observer -> Disposable in
                    DZMReadParser.getBookDetail(bookID: info.book_id ?? "", contentId: info.chapters?.first?.content_id, completion: {
                        observer.on(.next(($0)))
                    })
                    return Disposables.create()
                }
            }
            .map{ ReaderViewModel($0) }
            .asDriverOnErrorJustComplete()
        
        let provider = MoyaProvider<DownloadService>()
        viewDidLoad
            .asObservable()
            .flatMap {
                provider.rx.request(DownloadService.chapterGroup(["book_id": bookId]))
                    .model(DownloadChapterGroupResponse.self)
                    .asObservable()
                    .catchError {_ in Observable.never()}
            }
            .bind(to: dataResponse)
            .disposed(by: bag)

        dataResponse.asObservable()
            .map {$0.data}
            .unwrap()
            .mapMany({ (group) -> DownloadChapterGroup in
                let localGroup = realm.objects(DownloadLocalChapterGroupInfo.self).filter({ (filtergroup) -> Bool in
                        return filtergroup.id == group.id
                }).first
                if let localGroup = localGroup, localGroup.id == group.id{
                    group.status = DownloadStatus(rawValue: localGroup.status) ?? .none
                    group.progress = localGroup.progress
                    /// 继续下载没有下载完的章节
                    if group.status == DownloadStatus.downloading,  group.progress < 1 {
                        downloadingInput.accept(group)
                    }
                    if group.status == DownloadStatus.waiting,  group.progress < 1 {
                        totalDownloadChapters.accept(totalDownloadChapters.value + [group])
                    }
                    return group
                }
                return group
            })
            .bind(to: chapterGroupList)
            .disposed(by: bag)
        
        dataDriver = chapterGroupList.asObservable()
            .skip(1)
            .map {
               [SectionModel<String, DownloadChapterGroup>(model: $0.first?.book_title ?? "", items: $0)]
            }
            .asDriver(onErrorJustReturn:[])
        
        /// 下载的输入
        self.downloadInput
            .asObservable()
            .filter { $0.id != nil }
            .subscribe(onNext: { (inputChapter) in
                if totalDownloadChapters.value.contains(where: { $0.id == inputChapter.id}) {
                    message.onNext(HUDValue.init(.label("请勿重复添加")))
                    return
                }
                totalDownloadChapters.accept( totalDownloadChapters.value + [inputChapter])
                if let currentIndex = chapterGroupList.value.lastIndex(where: {$0.id == inputChapter.id}) {
                    let unlockChapterGroup =  chapterGroupList.value[currentIndex]
                    unlockChapterGroup.status = .waiting
                    var data = chapterGroupList.value
                    data[currentIndex] = unlockChapterGroup
                    chapterGroupList.accept(data)
                    /// 缓存到本地
                    let record = DownloadLocalChapterGroupInfo(inputChapter)
                    record.status = DownloadStatus.waiting.rawValue
                    try? realm.write {
                        realm.add(record, update: .all)
                        realm.add(record, update: Realm.UpdatePolicy.all)
                    }
                }
                guard let current = downloadingInput.value, let id = current.id else {
                    downloadingInput.accept(inputChapter)
                    return
                }
                guard let local = realm.objects(DownloadLocalChapterGroupInfo.self).filter(NSPredicate(format: "id = %@", id)).first,
                    let status = DownloadStatus.init(rawValue: local.status) else {
                      downloadingInput.accept(inputChapter)
                    return
                }
                switch status {
                case .fail:
                    downloadingInput.accept(inputChapter)
                case .success:
                     downloadingInput.accept(inputChapter)
                default:
                    break
                }
              
            })
            .disposed(by: bag)
        
        /// 重试的输入
        self.retryBtnInput
            .asObservable()
            .filter { $0.id != nil }
            .subscribe(onNext: { (inputChapter) in
                if totalDownloadChapters.value.contains(where: { $0.id == inputChapter.id}) {
                    downloadingInput.accept(inputChapter)
                    return
                }
                totalDownloadChapters.accept(totalDownloadChapters.value + [inputChapter])
                if let currentIndex = chapterGroupList.value.lastIndex(where: {$0.id == inputChapter.id}) {
                    let unlockChapterGroup =  chapterGroupList.value[currentIndex]
                    unlockChapterGroup.status = .waiting
                    var data = chapterGroupList.value
                    data[currentIndex] = unlockChapterGroup
                    chapterGroupList.accept(data)
                    /// 缓存到本地
                    let record = DownloadLocalChapterGroupInfo(inputChapter)
                    record.status = DownloadStatus.waiting.rawValue
                    try? realm.write {
                        realm.add(record, update: .all)
                    }
                }
                guard let current = downloadingInput.value, let id = current.id else {
                    downloadingInput.accept(inputChapter)
                    return
                }
                guard let local = realm.objects(DownloadLocalChapterGroupInfo.self).filter(NSPredicate(format: "id = %@", id)).first,
                    let status = DownloadStatus.init(rawValue: local.status) else {
                        downloadingInput.accept(inputChapter)
                        return
                }
                switch status {
                case .fail, .waiting:
                    downloadingInput.accept(inputChapter)
                case .success:
                    downloadingInput.accept(inputChapter)
                default:
                    break
                }
                
            })
            .disposed(by: bag)

        /// 初始化下载状态
        let currentDownloadChapter = BehaviorRelay<CurrentDonwloadChapterInfo>(value: CurrentDonwloadChapterInfo())
        let currentDownloadBook = BehaviorRelay<DownloadLocalBook>(value: DownloadLocalBook())
       
        /// 第1-20章的第一章存储为扉页
        downloadingInput.asObservable()
            .filter { _ in  bookDetail.value.cp_info != nil }
            .unwrap()
            .filter { $0.title == "第1-20章"}
            .map { $0.chapters?.first}
            .unwrap()
            .subscribeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { (firstChapter) in
                let liscense = bookDetail.value.cp_info!
                let cpInfo = ChapterCopyRightInfo(liscense)
                
                let cpChapter =  DZMReadChapterModel.readChapterModel(bookID: firstChapter.book_id! , chapterID: ReaderSpecialChapterValue.firstPageValue)
                cpChapter.bookID = firstChapter.book_id
                cpChapter.order = 0
                cpChapter.content = ""
                let cpNextChapter = ChapterInfo()
                cpNextChapter.book_id = firstChapter.book_id
                cpNextChapter.content_id = firstChapter.content_id
                cpNextChapter.title = firstChapter.title
                cpNextChapter.order = "1"
                cpChapter.next_chapter = cpNextChapter
                cpChapter.nextChapterId = firstChapter.content_id
                cpChapter.last_chapter = nil
                cpChapter.lastChapterId = nil
                cpChapter.id = ReaderSpecialChapterValue.firstPageValue
                cpChapter.cp_info =  cpInfo
                cpChapter.pageCount = 1
                cpChapter.saveData()
            })
            .disposed(by: bag)
        
        /// 初始化章节状态
        downloadingInput.asObservable()
            .debug()
            .unwrap()
            .filter { $0.chapters != nil }
            .map { (input) -> CurrentDonwloadChapterInfo in
                var currentDowninfo = CurrentDonwloadChapterInfo()
                currentDowninfo.status = .waiting
                currentDowninfo.title = input.title ?? ""
                currentDowninfo.bookId = bookId
                currentDowninfo.book_title = input.book_title ?? ""
                currentDowninfo.id = input.id
                currentDowninfo.chapterIds = input.chapters!.map { $0.content_id ?? "" }
                return currentDowninfo
        }
            .bind(to: currentDownloadChapter)
            .disposed(by: bag)

        /// 初始化书籍状态
        let currentBook = DownloadLocalBook()
        currentBook.book_id = bookId
        currentBook.create_time = Date().timeIntervalSince1970
        currentDownloadBook.accept(currentBook)
        
        /// 有书籍信息
        downloadingInput.asObservable()
             .skip(1)
            .unwrap()
            .filter { $0.chapters != nil }
            .filter {_ in bookDetail.value.book_info != nil }
            .map { (input) -> DownloadLocalBook in

                let currentBook = currentDownloadBook.value
                currentBook.book_title = input.book_title ?? ""
                currentBook.author = bookDetail.value.book_info?.author_name ?? ""
                currentBook.cover_img = bookDetail.value.book_info?.cover_url ?? ""
                currentBook.dowloadStatus = DownloadStatus.waiting.rawValue
                if let record = realm.objects(DownloadLocalBook.self).filter(NSPredicate(format: "book_id = %@", input.book_id ?? "")).first {
                    currentBook.download_chapter_count = record.download_chapter_count
                    currentBook.create_time = record.create_time
                }
                return currentBook
            }
            .bind(to: currentDownloadBook)
            .disposed(by: bag)

        /// 无书籍信息
        downloadingInput.asObservable()
            .skip(1)
            .unwrap()
            .filter { $0.chapters != nil }
            .filter {_ in bookDetail.value.book_info == nil }
            .flatMap { _ in
                detailProvider
                    .rx
                    .request(.detail(bookId))
                    .model(BookDetailResponse.self)
                    .asObservable()
            }
            .map { $0.data?.book_info }
            .unwrap()
            .map { (input) -> DownloadLocalBook in
                let currentBook = currentDownloadBook.value
                currentBook.book_title = input.book_title ?? ""
                currentBook.author = bookDetail.value.book_info?.author_name ?? ""
                currentBook.cover_img = bookDetail.value.book_info?.cover_url ?? ""
                currentBook.dowloadStatus = DownloadStatus.waiting.rawValue
                if let record = realm.objects(DownloadLocalBook.self).filter(NSPredicate(format: "book_id = %@", input.book_id)).first {
                    currentBook.download_chapter_count = record.download_chapter_count
                    currentBook.create_time = record.create_time
                }
                return currentBook
            }
            .bind(to: currentDownloadBook)
            .disposed(by: bag)

      
        
         /// 先给用户充值
        downloadingInput.asObservable()
            .skip(1)
            .unwrap()
            .filter { $0.chapters != nil }
            .flatMap { _ -> Observable<NullResponse> in
                provider.rx.request(.charge)
                    .model(NullResponse.self)
                    .asObservable()
                    .debug()
                    .catchError { Observable.just(NullResponse.commonError($0))}
            }
            .bind(to: chargeResponse)
            .disposed(by:  bag)
  
        /// 充值成功后，进行章节购买
        chargeResponse
            .asObservable()
            .filter { $0.status?.code == 0  }
            .filter { _ in  downloadingInput.value != nil }
            .map { _ in (bookId, downloadingInput.value!.chapters!.map {$0.content_id ?? ""}.joined(separator: ",")) }
            .flatMap {
                provider.rx
                    .request(.payChapter(["book_id": $0.0, "chapter_ids": $0.1]))
                    .model(DownloadChapterPayResponse.self)
                    .asObservable()
                    .catchError { Observable.just(DownloadChapterPayResponse.commonError($0))}
                    .trackActivity(activityIndicator)
            }
            .bind(to: payResponse)
            .disposed(by: bag)
      
        /// 购买后，批量下载
        payResponse.asObservable()
            .filter { $0.status?.code == 0 }
            .map {$0.data}
            .unwrap()
            .filter {$0.chapter_ids != nil }
            .map { $0.chapter_ids!.split(separator: ",")}
            .flatMap { (chapterIds) -> Observable<ChapterContentResponse> in
                var info = currentDownloadChapter.value
                info.chapterIds = chapterIds.map { String($0)}
                info.status = .downloading
                currentDownloadChapter.accept(info)
                let collection = chapterIds.map({ (chapterId) -> Observable<ChapterContentResponse> in
                        return provider.rx
                            .request(.chapterContent(["book_id": bookId, "content_id": String(chapterId)]))
                            .model(ChapterContentResponse.self)
                            .asObservable()
                            .catchError { Observable.just(ChapterContentResponse.commonError($0))}
                    })

               let merge = Observable.merge(collection)
                return merge
            }
           .bind(to: chapterContentResponse)
           .disposed(by: bag)
        
        /// 保存下载的章节
        chapterContentResponse.asObservable()
            .filter {$0.status?.code == 0}
            .map { $0.data }
            .unwrap()
            .subscribeOn(MainScheduler.asyncInstance)
            .subscribe(onNext: { (chapter) in
                if let bookLiscense = bookDetail.value.cp_info {
                    chapter.cp_info = ChapterCopyRightInfo(bookLiscense)
                }
                ReaderController.cacheData(chapter)
                var info = currentDownloadChapter.value
                info.chapterSuccessCount += 1
                info.status = info.chapterSuccessCount == info.chapterIds.count ? .success : .downloading
                currentDownloadChapter.accept(info)
            })
            .disposed(by: bag)
        
        /// 监听每个环节的状态，只要有一个失败，则都算是失败状态
        Observable.merge([chargeResponse.asObservable().debug().filter {$0.status?.code != 0 }.mapToVoid(),
                          payResponse.asObservable().filter {$0.status?.code != 0 }.mapToVoid(),
                          chapterContentResponse.asObservable().filter {$0.status?.code != 0 }.mapToVoid()])
            .map { _ -> CurrentDonwloadChapterInfo in
                var info = currentDownloadChapter.value
                info.status = .fail
                return info
            }
            .bind(to: currentDownloadChapter)
            .disposed(by: bag)
        
        
        /// 发出下载信息
        currentDownloadChapter.asObservable()
            .skip(1)
            .subscribe(onNext: { (info) in
                NotificationCenter.default.post(name: Notification.Name.Book.downloadInfo, object: info, userInfo: info.toJSON() ?? [String: Any]())
            })
            .disposed(by: bag)
        
        /// 接收章节下载信息
        NotificationCenter.default.rx.notification(Notification.Name.Book.downloadInfo)
            .map { $0.object as? CurrentDonwloadChapterInfo}
            .unwrap()
            .filter { $0.status.rawValue == DownloadStatus.success.rawValue }
            .subscribe(onNext: { (info) in
                if let index = totalDownloadChapters.value.firstIndex(where: {$0.id == info.id}) {
                    /// 从下载队列移除，继续下一个下载
                    var data = totalDownloadChapters.value
                    data.removeAll(where: {$0.id == nil })
                    data.remove(at: index)
                    totalDownloadChapters.accept(data)
                    if totalDownloadChapters.value.isEmpty {
                        return
                    }
                    /// 缓一下
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 2, execute: {
                        downloadingInput.accept(totalDownloadChapters.value.first!)
                        /// 更新UI
                        if let currentIndex = chapterGroupList.value.lastIndex(where: {$0.id == downloadingInput.value!.id}) {
                            let unlockChapterGroup =  chapterGroupList.value[currentIndex]
                            unlockChapterGroup.status = .waiting
                            var data = chapterGroupList.value
                            data[currentIndex] = unlockChapterGroup
                            chapterGroupList.accept(data)
                        }
                    })
                }
            })
            .disposed(by: bag)
        
     
        currentDownloadChapter.asObservable()
            .skip(1)
            .filter { $0.status.rawValue == DownloadStatus.fail.rawValue }
            .map { ($0.book_title ?? "") + $0.title + "下载失败" }
            .map { HUDValue(.label($0))}
            .bind(to: message)
            .disposed(by: bag)
        
        currentDownloadChapter.asObservable()
            .skip(1)
            .filter { $0.status.rawValue == DownloadStatus.success.rawValue }
            .map { ($0.book_title ?? "") + $0.title + "下载成功" }
            .map { HUDValue(.label($0))}
            .bind(to: message)
            .disposed(by: bag)
        
        
        /// 存储下载的章节信息
        currentDownloadChapter.asObservable()
            .filter { !$0.chapterIds.isEmpty }
            .filter { $0.id != nil }
            .map { (currentGroup) -> DownloadLocalChapterGroupInfo in
                let record = DownloadLocalChapterGroupInfo()
                record.id = currentGroup.id!
                record.title = currentGroup.title
                record.progress = currentGroup.progress
                record.status = currentGroup.status.rawValue
                record.book_title = currentGroup.book_title ?? ""
                record.book_id = currentGroup.bookId
                record.content_ids = currentGroup.chapterIds.joined(separator: ",")
                return record
        }
        .subscribe(realm.rx.add(update: true, onError: nil))
        .disposed(by: bag)
        
        /// 根据章节信息转换为书籍信息
        currentDownloadChapter.asObservable()
            .filter { !$0.chapterIds.isEmpty }
            .filter { $0.id != nil }
            .subscribe(onNext: { (info) in
                 let newBook = currentDownloadBook.value
                if newBook.dowloadStatus != info.status.rawValue {
                    newBook.dowloadStatus = info.status.rawValue
                    currentDownloadBook.accept(newBook)
                }
                if case DownloadStatus.success = info.status {
                    newBook.download_chapter_count += info.chapterSuccessCount
                    newBook.download_size = Double(ReaderFileService.bookSize(info.bookId))
                    currentDownloadBook.accept(newBook)
                }
            })
            .disposed(by: bag)
        
        /// 存储书籍信息
        currentDownloadBook.asObservable()
            .filter { $0.download_chapter_count > 0 }
            .map({ (preBook) -> DownloadLocalBook in
                let newBook = DownloadLocalBook()
                newBook.book_id = preBook.book_id
                newBook.book_title = preBook.book_title
                newBook.author = preBook.author
                newBook.cover_img = preBook.cover_img
                newBook.dowloadStatus = preBook.dowloadStatus
                newBook.download_chapter_count = preBook.download_chapter_count
                newBook.download_size = preBook.download_size
                newBook.create_time = preBook.create_time
                NotificationCenter.default.post(name: Notification.Name.Book.downloadInfo, object: newBook, userInfo: newBook.toJSON() ?? [String: Any]())
                return newBook
            })
            .subscribe(realm.rx.add(update: true, onError: nil))
            .disposed(by: bag)
        
        
        /// 更新内存中的数据
        currentDownloadChapter.asObservable()
            .filter { !$0.chapterIds.isEmpty }
            .filter { $0.id != nil }
            .subscribe(onNext: { (currentGroup) in
                for (index, group) in chapterGroupList.value.enumerated() {
                    if group.id == currentGroup.id {
                        group.status = currentGroup.status
                        group.progress = currentGroup.progress
                        var data = chapterGroupList.value
                        data[index] = group
                        chapterGroupList.accept(data)
                        break
                    }
                }
            })
            .disposed(by: bag)
        
        /// 解锁章节输入
        unlockInput.asObservable()
            .filter {$0.chapters != nil }
            .bind(to: unlockChapterInput)
            .disposed(by: bag)
        
//        unlockInput.asObservable().subscribe(onNext: { (currentgroup) in
//            if let currentIndex = chapterGroupList.value.lastIndex(where: {$0.id == currentgroup.id}) {
//                let unlockChapterGroup =  chapterGroupList.value[currentIndex]
//                unlockChapterGroup.status = .unlock
//                chapterGroupList.value[currentIndex] = unlockChapterGroup
//                /// 缓存到本地
//                let record = DownloadLocalChapterGroupInfo()
//                record.create_time = Date().timeIntervalSince1970
//                record.id = currentgroup.id!
//                record.title = currentgroup.title ?? ""
//                record.progress = currentgroup.progress
//                record.status = DownloadStatus.unlock.rawValue
//                record.book_title = currentgroup.book_title ?? ""
//                record.book_id = currentgroup.book_id ?? ""
//                record.content_ids = currentgroup.chapters!.map { $0.content_id ?? ""}.joined(separator: ",")
//                try? realm.write {
//                    realm.add(record, update: true)
//                }
//            }
//        })
//            .disposed(by: bag)
   
        
        ///  解锁
        unlockInput.asObservable()
            .map { _ in AdPosition.downloadUnLockRewardVideo}
            .debug()
            .bind(to: unlockOutput)
            .disposed(by: bag)

       /// 广告视频看完了，解锁下载
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.rewardVideoAdWillDismiss)
            .asObservable()
            .map { $0.object }
            .map { $0 as? LocalAdvertise}
            .unwrap()
            .filter { $0.ad_position == AdPosition.downloadUnLockRewardVideo.rawValue }
            .map {_ in unlockChapterInput.value }
            .subscribe(onNext: { (currentgroup) in
                if let currentIndex = chapterGroupList.value.lastIndex(where: {$0.id == currentgroup.id}) {
                    let unlockChapterGroup =  chapterGroupList.value[currentIndex]
                    unlockChapterGroup.status = .unlock
                    var data = chapterGroupList.value
                    data[currentIndex] = unlockChapterGroup
                    chapterGroupList.accept(data)
                    /// 缓存到本地
                    let record = DownloadLocalChapterGroupInfo()
                    record.create_time = Date().timeIntervalSince1970
                    record.id = currentgroup.id!
                    record.title = currentgroup.title ?? ""
                    record.progress = currentgroup.progress
                    record.status = DownloadStatus.unlock.rawValue
                    record.book_title = currentgroup.book_title ?? ""
                    record.book_id = currentgroup.book_id ?? ""
                    record.content_ids = currentgroup.chapters!.map { $0.content_id ?? ""}.joined(separator: ",")
                    try? realm.write {
                        realm.add(record, update: .all)
                    }
                }
            })
            .disposed(by: bag)
        
        guard let readerBottomAdConfig = AdvertiseService.advertiseConfig(AdPosition.downloadBottomBanner), !readerBottomAdConfig.is_close else {
            return
        }
        
        let bannerOutput = self.bannerOutput
        bannerConfigOutput.accept(readerBottomAdConfig)
        bannerConfigOutput.asObservable()
            .unwrap()
            .filter { !$0.is_close}
            .filter { $0.ad_type == AdvertiseType.inmobi.rawValue }
            .subscribe(onNext: {[weak self] (config) in
                guard let weakSelf = self else {
                    return
                }
                let imBannerViewModel = IMBannerViewModel(config, isAutoRefresh: true)
                imBannerViewModel.nativeAdOutput
                    .asObservable()
                    .map { LocalTempAdConfig(config, adType: .inmobi($0))}
                    .bind(to: bannerOutput)
                    .disposed(by: weakSelf.bag)
                weakSelf.bannerViewModel = imBannerViewModel
            })
            .disposed(by: bag)
        
        /// banner 广告加载（首选position_id）失败， 加载second_type
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.fisrtTypeLoadFail)
            .map { $0.object as? LocalAdvertise }
            .debug()
            .unwrap()
            .filter { $0.ad_position == AdPosition.downloadBottomBanner.rawValue}
            .map { (oldConfig) -> LocalAdvertise in
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.second_ad_position_id
                newConfig.ad_type = oldConfig.second_ad_type
                return newConfig
            }
            .bind(to: bannerConfigOutput)
            .disposed(by: bag)
        
        /// banner 广告加载（首选position_id）失败， 加载second_type
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.secondTypeLoadFail)
            .map { $0.object as? LocalAdvertise }
            .debug()
            .unwrap()
            .filter { $0.ad_position == AdPosition.downloadBottomBanner.rawValue}
            .map { (oldConfig) -> LocalAdvertise in
                let newConfig = LocalAdvertise(oldConfig)
                newConfig.ad_position_id = oldConfig.third_ad_position_id
                newConfig.ad_type = oldConfig.third_ad_type
                return newConfig
            }
            .bind(to: bannerConfigOutput)
            .disposed(by: bag)
        
    }
    
}



struct CurrentDonwloadChapterInfo: HandyJSON {
    var bookId: String = ""
    var id: String?
    var title: String = ""
    var book_title: String?
    var chapterSuccessCount: Int = 0
    var chapterIds: [String] = []
    var progress: Double {
        if chapterIds.isEmpty {
            return 0
        } else {
            return Double(chapterSuccessCount) / Double(chapterIds.count) * 1.0
        }
    }
    var status: DownloadStatus = .none
    

}

class DownloadLocalChapterGroupInfo: Object {
    @objc dynamic var id: String = ""
    @objc dynamic var status: Int = DownloadStatus.none.rawValue
    @objc dynamic var progress: Double = 0.0
    @objc dynamic var title: String = ""
    @objc dynamic var book_id: String = ""
    @objc dynamic var book_title: String = ""
    @objc dynamic var content_ids: String = ""
    @objc dynamic  var create_time: Double = Date().timeIntervalSince1970
    
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
    convenience init(_ serverData: DownloadChapterGroup) {
        self.init()
        self.create_time = Date().timeIntervalSince1970
        self.id = serverData.id!
        self.title = serverData.title ?? ""
        self.progress = serverData.progress
        self.status = DownloadStatus.waiting.rawValue
        self.book_title = serverData.book_title ?? ""
        self.book_id = serverData.book_id ?? ""
        self.content_ids = serverData.chapters!.map { $0.content_id ?? ""}.joined(separator: ",")
    }
}
