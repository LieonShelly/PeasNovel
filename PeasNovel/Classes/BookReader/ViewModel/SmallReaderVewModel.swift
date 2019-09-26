//
//  SmallReaderVewModel.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/8.
//  Copyright © 2019 NotBroken. All rights reserved.
//  小窗口阅读器ViewModel

import Foundation
import RxCocoa
import RxSwift
import Moya
import PKHUD

class SmallReaderVewModel {
    /// input
    let viewDidLoad: PublishSubject<Void> = .init()
    let viewWillAppear: PublishSubject<Bool> = .init()
    let viewWillDisappear: PublishSubject<Bool> = .init()
    let bookInfo: PublishSubject<BookInfo> = .init()
    let addBookShlefInput: PublishSubject<Bool> = .init()
    let tapBtnInput: PublishSubject<Void> = .init()
    let bag = DisposeBag()
    let isAddedStatus: Driver<Bool>
    let message: PublishSubject<HUDValue> = .init()
    let smallViewModel: PublishSubject<SmallReaderVewModel> = .init()
    let loadContentInput: PublishSubject<Void> = .init()
    let textFrameInput: PublishSubject<CGRect> = .init()
    let content: BehaviorRelay<ChapterContent?> = .init(value: nil)
    let contentOutput: BehaviorRelay<NSAttributedString?> = .init(value: nil)
    let bookDetailVM: Driver<BookDetailViewModel>
    let detailBtnInput: PublishSubject<Void> = .init()
    
    init(_ inputBookInfo: BookInfo) {
        
        viewDidLoad
            .map { inputBookInfo }
            .bind(to: bookInfo)
            .disposed(by: bag)
        
        bookDetailVM = detailBtnInput.asObservable()
            .map { inputBookInfo }
            .map { BookDetailViewModel($0.book_id)}
            .asDriverOnErrorJustComplete()
        
        let bookProvider = MoyaProvider<BookInfoService>()
        let addBookshelf = addBookShlefInput
            .asObservable()
            .filter { $0 == false }
            .withLatestFrom(bookInfo)
            .map { $0.book_id}
            .unwrap()
            .flatMap {
                bookProvider.rx
                    .request(.add($0, 0))
                    .model(NullResponse.self)
                    .asObservable()
                    .catchError {_ in Observable.never()}
            }
            .map{ $0.status?.code }
            .unwrap()
            .share(replay: 1)
        
        let removeBookshelf = addBookShlefInput
            .asObservable()
            .filter { $0 == true }
            .withLatestFrom(bookInfo)
            .map { $0.book_id}
            .unwrap()
            .flatMap {
                bookProvider
                    .rx
                    .request(.delete($0, "0"))
                    .model(NullResponse.self)
                    .asObservable()
                    .catchError{_ in Observable.never() }
                
            }
            .map{ $0.status?.code }
            .unwrap()
            .share(replay: 1)
        
        
        Observable.merge(addBookshelf, removeBookshelf)
            .filter{ $0 == 0 }
            .subscribe(onNext: { _ in
                NotificationCenter.default.post(name: NSNotification.Name.Book.bookshelf, object: nil)
                NotificationCenter.default.post(name: NSNotification.Name.Book.smallReaderAddCollect, object: nil)
            })
            .disposed(by: bag)
        
        
        let bookDetail = BehaviorRelay<BookDetailModel>(value: BookDetailModel())
        bookInfo
            .asObservable()
            .flatMap {
                bookProvider
                    .rx
                    .request(.detail($0.book_id))
                    .model(BookDetailResponse.self)
                    .asObservable()
                    .catchError {_ in Observable.never()}
            }
            .map{ $0.data }
            .unwrap()
            .bind(to: bookDetail)
            .disposed(by: bag)
        
        // 是否加入书架
        let joinBookshelf = bookDetail
            .asObservable()
            .map{ $0.book_info?.join_bookcase }
            .unwrap()
            .map{ $0 }
        
        isAddedStatus = Observable
            .merge(joinBookshelf,
                   addBookshelf.map{ $0 == 0 },
                   removeBookshelf.filter{ $0 == 0 }.map { _ in false } )
            .asDriver(onErrorJustReturn: false)
        
        
        
        addBookshelf.asObservable()
            .observeOn(MainScheduler.instance)
            .filter { $0 == 0 }
            .map { _ in HUDValue(.label("添加书架成功"))}
            .bind(to: message)
            .disposed(by: bag)
        
        removeBookshelf.asObservable()
            .observeOn(MainScheduler.instance)
            .filter { $0 == 0 }
            .map { _ in HUDValue(.label("移除书架成功"))}
            .bind(to: message)
            .disposed(by: bag)

        loadTextContent(inputBookInfo)
        
    }
    
    private func loadTextContent(_ inputBookInfo: BookInfo) {
        let provider = MoyaProvider<BookReaderService>()
        loadContentInput
            .flatMap {
                provider.rx
                    .request(.chapterContent(["book_id": inputBookInfo.book_id]))
                    .model(ChapterContentResponse.self)
                    .asObservable()
                    .catchError {_ in Observable.never()}
            }
            .map { $0.data }
            .unwrap()
            .bind(to: content)
            .disposed(by: bag)
        
        content.asObservable()
            .withLatestFrom(textFrameInput, resultSelector: { ($0, $1)})
            .map { (chapterContent, textFrame) -> NSAttributedString in
                let title = "\r\n" + (chapterContent?.title ?? "") + "\r\n\r"
                let content = chapterContent?.content ?? ""
                let pageContentAttr = NSMutableAttributedString()
                var contentAttti = DZMReadConfigure.shared().readAttribute(isPaging: false, isTitle: false)
                contentAttti[NSAttributedString.Key.foregroundColor] = UIColor(0x6F6F6F)
                contentAttti[NSAttributedString.Key.font] = UIFont.systemFont(ofSize: 17)
                var nameAttribute = DZMReadConfigure.shared().readAttribute(isPaging: true, isTitle: true)
                nameAttribute[NSAttributedString.Key.foregroundColor] = UIColor(0x333333)
                nameAttribute[NSAttributedString.Key.font] = UIFont.systemFont(ofSize: 17)
                let nameString = NSMutableAttributedString(string: title, attributes: nameAttribute)
                pageContentAttr.append(nameString)
                let newContentAttr = NSAttributedString(string: DZMReadParser.onlyText(content), attributes: contentAttti)
                pageContentAttr.append(newContentAttr)
                return pageContentAttr
            }
            .bind(to: contentOutput)
            .disposed(by: bag)
        

    }
    
    private func iniitBookInfo(_ inputBookInfo: BookInfo) {
      
    }
    
    deinit {
        debugPrint("ChapterTailBookViewModel - deinit")
    }
}
