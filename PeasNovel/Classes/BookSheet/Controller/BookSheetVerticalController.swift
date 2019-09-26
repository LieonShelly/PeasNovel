//
//  BookSheetVerticalController.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/22.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import FSPagerView
import RxSwift
import PKHUD
import RxCocoa

class BookSheetVerticalController: BaseViewController {

    @IBOutlet weak var coverImageView: UIImageView!
    @IBOutlet weak var introLabel: UILabel!
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var bgImageView: UIImageView!
    @IBOutlet weak var pagerView: FSPagerView!
    
    let bookList = BehaviorRelay<[BookSheetListModel]>(value: [])
    let itemDidSelected: PublishSubject<BookSheetListModel> = .init()
    var cellAction: PublishSubject<(Int, BookSheetListModel)> = .init()
    
    convenience init(_ viewModel: BookSheetDetailViewModel) {
        self.init(nibName: "BookSheetVerticalController", bundle: nil)
        self.rx
            .viewDidLoad
            .subscribe(onNext: { [unowned self] in
                self.configUI()
                self.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx
            .viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
    }
    
    func config(_ viewModel: BookSheetDetailViewModel) {
        
        viewModel.activityDriver
            .drive(self.rx.loading)
            .disposed(by: bag)
        
        viewModel.activityDriver
            .drive(HUD.loading)
            .disposed(by: bag)
        
        viewModel.dataEmpty
            .drive(pagerView.rx.isHidden)
            .disposed(by: bag)
        
        viewModel.exceptionOuptputDriver
            .drive(self.rx.exception)
            .disposed(by: bag)
        
        self.exception
            .mapToVoid()
            .bind(to: viewModel.exceptionInput)
            .disposed(by: bag)
        
        
        cellAction
            .bind(to: viewModel.cellAction)
            .disposed(by: bag)
        
        addButton
            .rx
            .tap
            .bind(to: viewModel.addBookshelfAction)
            .disposed(by: bag)
        
        viewModel
            .toReader
            .subscribe(onNext: { 
                BookReaderHandler.jump($0.book_id, contentId: $0.content_id)
            })
            .disposed(by: bag)
        
        viewModel
            .isBookshelf
            .drive(addButton.rx.isHidden)
            .disposed(by: bag)
        
        viewModel
            .dataSource
            .map{ $0.book_lists }
            .unwrap()
            .bind(to: self.bookList)
            .disposed(by: bag)
        
        viewModel
            .dataSource
            .subscribe(onNext: { [unowned self] in
                let url = URL(string: $0.boutique_img ?? "")
                self.bgImageView.kf.setImage(with: url, placeholder: UIImage())
                self.coverImageView.kf.setImage(with: url, placeholder: UIImage())
                self.introLabel.text = $0.boutique_title
                self.pagerView.reloadData()
            })
            .disposed(by: bag)
    }
    
    func configUI() {
        
        if self.title == nil {
             self.title = "书单详情"
        }
        coverImageView.layer.cornerRadius = 2
        coverImageView.layer.masksToBounds = true
        pagerView.dataSource = self
        pagerView.delegate = self
        pagerView.register(UINib(nibName: "BookSheetVerticalViewCell", bundle: nil),
                           forCellWithReuseIdentifier: "BookSheetVerticalViewCell")
        
        pagerView.transformer = FSPagerViewTransformer(type: .linear)
        pagerView.interitemSpacing = 10
        pagerView.itemSize = CGSize(width:  pagerView.bounds.size.width - 43 * 2, height: (pagerView.bounds.height - 41 * 2))
    }


    func config() {
        pagerView.reloadData()
    }

}

extension BookSheetVerticalController: FSPagerViewDataSource {
    public func numberOfItems(in pagerView: FSPagerView) -> Int {
        return self.bookList.value.count
    }
    
    public func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        guard let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "BookSheetVerticalViewCell", at: index) as? BookSheetVerticalViewCell else {
            return FSPagerViewCell()
        }
        if  index < self.bookList.value.count {
            let model = self.bookList.value[index]
            cell.set(model)
            cell.cellAction
                .bind(to: cellAction)
                .disposed(by: cell.bag)
        }
        return cell
    }
}

extension BookSheetVerticalController: FSPagerViewDelegate {
    func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
        pagerView.deselectItem(at: index, animated: true)
        pagerView.scrollToItem(at: index, animated: true)
//        itemDidSelected.on(.next())
    }
}
