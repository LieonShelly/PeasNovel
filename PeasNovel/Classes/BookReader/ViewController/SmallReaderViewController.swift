//
//  SmallReaderViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/8.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import PKHUD

class SmallReaderViewController: BaseViewController {
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var topView: UIView!
    @IBOutlet weak var addBtn: UIButton!
    @IBOutlet weak var detailBtn: UIButton!
    @IBOutlet weak var cateLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var textView: UITextView!
    let didScroll: PublishSubject<UIScrollView> = .init()
    @IBOutlet weak var tapBtn: UIButton!
    @IBOutlet weak var titleLabelHeight: NSLayoutConstraint!
    @IBOutlet weak var topHeight: NSLayoutConstraint!
    
    convenience init( _ viewModel: SmallReaderVewModel) {
        self.init(nibName: "SmallReaderViewController", bundle: nil)
        self.rx.viewDidLoad
            .subscribe(onNext: { [weak self](_) in
                self?.configUI()
                self?.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx.viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
    }
    
    private func configUI() {
        addBtn.layer.cornerRadius = 3
        addBtn.layer.masksToBounds = true
        topView.layer.cornerRadius = 20
        topView.layer.masksToBounds = true
        textView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: UIDevice.current.safeAreaInsets.bottom, right: 16)
        view.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        textView.delegate = self
    }
    
    private func config(_ viewModel: SmallReaderVewModel) {
        addBtn.rx.tap
            .subscribe(onNext: { [weak self](_) in
                guard let weakSelf = self else {
                    return
                }
                viewModel.addBookShlefInput.on(.next(weakSelf.addBtn.isSelected))
            })
            .disposed(by: bag)
        
        
       Observable.merge(detailBtn.rx.tap.mapToVoid(), tapBtn.rx.tap.mapToVoid())
            .bind(to: viewModel.detailBtnInput)
            .disposed(by: bag)
        
        viewModel.bookInfo
            .bind(to: self.rx.bookInfo)
            .disposed(by: bag)
        
        viewModel.isAddedStatus
            .drive(addBtn.rx.isSelected)
            .disposed(by: bag)
        
        viewModel.message
            .bind(to: HUD.flash)
            .disposed(by: bag)
        
        viewModel.textFrameInput.on(.next(view.bounds))
        viewModel.loadContentInput.onNext(())
      
         viewModel.contentOutput
            .asObservable()
            .unwrap()
            .asDriverOnErrorJustComplete()
            .drive(onNext: { [weak self](attr) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.textView.attributedText = attr
            })
             .disposed(by: bag)
        
        viewModel.bookDetailVM
            .drive(onNext: {[weak self] (vm) in
                guard let weakSelf = self else {
                    return
                }
                let vcc = BookDetailViewController(vm)
                weakSelf.navigationController?.pushViewController(vcc, animated: true)
            })
            .disposed(by: bag)
    }
    
    func updateUI(_ book: BookInfo) {
        titleLabel.text = book.book_title
        if let author = book.author_name {
            authorLabel.text = author
        }
        cateLabel.text = book.writing_process.desc
        cateLabel.text = " |  " + book.writing_process.desc + "  |  " + (book.category_id_1?.short_name ?? "")
    }
}

extension SmallReaderViewController: UITextViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        didScroll.onNext(scrollView)
      
    }
}



extension Reactive where Base: SmallReaderViewController {
    var bookInfo: Binder<BookInfo> {
        return Binder<BookInfo>(base, scheduler: MainScheduler.instance, binding: { (control, value) in
            control.updateUI(value)
        })
    }
}
