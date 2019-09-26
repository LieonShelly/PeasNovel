//
//  BookMallContainerCollectionViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/11.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift

class BookMallContainerCollectionViewCell: UICollectionViewCell {
    let bookTapInput: PublishSubject<RecommendBook> = .init()
    @IBOutlet weak var collectionView: UICollectionView!
    var bag = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.registerNibWithCell(BookRecommendCateCell.self)
    }
    
    
    func config(_ books: [RecommendBook]) {
        let items = Observable.just(books)
        items.bind(to: collectionView.rx.items(cellIdentifier: String(describing: BookRecommendCateCell.self), cellType: BookRecommendCateCell.self)) { (row, element, cell) in
              cell.config(element.img_url ?? "", title: element.short_name, subTitle: element.category_count_title, desc: element.book_count_title)
            }
            .disposed(by: bag)
        
        collectionView.rx.modelSelected(RecommendBook.self)
            .filter {$0.category_id != nil }
            .bind(to: bookTapInput)
            .disposed(by: bag)
        
         collectionView.rx.setDelegate(self).disposed(by: bag)
    }
    
   
    
}


extension BookMallContainerCollectionViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: (UIScreen.main.bounds.width - 14 * 2 - 16) / 2.80001, height: 90)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 14
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}

