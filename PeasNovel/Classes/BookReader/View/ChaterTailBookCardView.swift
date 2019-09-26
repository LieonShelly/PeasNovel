//
//  ChaterTailBookCardView.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/5.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import PKHUD

class ChaterTailBookCardView: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var tapButton: UIButton!
    @IBOutlet weak var introLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var coverView: UIImageView!
    @IBOutlet weak var tagLabel0: InsetsLabel!
    @IBOutlet weak var tagLabel1: InsetsLabel!
    var viewModel: ChapterTailBookViewModel!
    var bag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        tagLabel0.edgeInsets = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
        tagLabel0.layer.cornerRadius = 2
        tagLabel0.layer.masksToBounds = true
        tagLabel0.layer.borderColor = UIColor(0x999999).cgColor
        tagLabel0.layer.borderWidth = 0.5
        tagLabel1.edgeInsets = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
        tagLabel1.layer.cornerRadius = 2
        tagLabel1.layer.masksToBounds = true
        tagLabel1.layer.borderColor = UIColor(0x999999).cgColor
        tagLabel1.layer.borderWidth = 0.5
    }
    

    static func loadView(_ viewModel: ChapterTailBookViewModel) -> ChaterTailBookCardView {
        guard let view = Bundle.main.loadNibNamed("ChaterTailBookCardView", owner: nil, options: nil)?.last as? ChaterTailBookCardView else {
            return ChaterTailBookCardView()
        }
        view.config(viewModel)
        return view
    }
    
    func config(_ viewModel: ChapterTailBookViewModel) {
        self.viewModel = viewModel
        addButton.rx.tap
            .subscribe(onNext: { [weak self](_) in
                guard let weakSelf = self else {
                    return
                }
                viewModel.addBookShlefInput.on(.next(weakSelf.addButton.isSelected))
            })
            .disposed(by: bag)
        
        viewModel.loadInput.onNext(())
        
        viewModel.bookInfo
            .bind(to: self.rx.bookInfo)
            .disposed(by: bag)
        
        viewModel.isAddedStatus
            .drive(addButton.rx.isSelected)
            .disposed(by: bag)
        
        viewModel.message
            .bind(to: HUD.flash)
            .disposed(by: bag)
    }
    
    
    func updateUI(_ book: BookInfo) {
        titleLabel.text = book.book_title
        if let author = book.author_name {
            authorLabel.text = author + "  著名"
        }
        introLabel.attributedText = book.book_intro?.withlineSpacing(8)
        tagLabel0.text = book.writing_process.desc
        tagLabel1.text = book.category_id_1?.short_name
        coverView.kf.setImage(with: URL(string: book.cover_url ?? ""))
    }

    deinit {
        debugPrint("ChaterTailBookCardView - init")
    }
}

extension Reactive where Base: ChaterTailBookCardView {
    var bookInfo: Binder<BookInfo> {
        return Binder<BookInfo>(base, scheduler: MainScheduler.instance, binding: { (control, value) in
            control.updateUI(value)
        })
    }
}
