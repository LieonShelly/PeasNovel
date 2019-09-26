//
//  ReaderLastPageCollectionTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/22.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ReaderLastPageCollectionTableViewCell: UITableViewCell {
    @IBOutlet weak var collectionView: UICollectionView!
    var bag = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.registerNibWithCell(BookTopImageCollectionViewCell.self)
        collectionView.delegate = self
        collectionView.backgroundColor = UIColor(0xE6DBBF)
    }
    
    func config(_ books: [ReaderLastPageGuessBook]) {
        let items = Observable.just(books)
        items.bind(to: collectionView.rx.items(cellIdentifier: String(describing: BookTopImageCollectionViewCell.self), cellType: BookTopImageCollectionViewCell.self)) { (row, element, cell) in
             cell.contentView.backgroundColor = UIColor(0xE6DBBF)
            cell.label.textAlignment = .left
             cell.config(element.cover_url, title: element.book_title)
            }
            .disposed(by: bag)
        
        collectionView.rx.modelSelected(ReaderLastPageGuessBook.self)
            .asObservable()
            .map { $0.book_id }
            .unwrap()
            .subscribe(onNext: { (book_id) in
                BookReaderHandler.jump(book_id)
            })
            .disposed(by: bag)
    }
    
    
}



extension ReaderLastPageCollectionTableViewCell: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 16, left: 16, bottom: 16, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let minInterSpace: CGFloat = 16
        let inset: CGFloat = 16
        let labelheight: CGFloat = 35
        let width: CGFloat = 88
        let rowHeight: CGFloat = width * 116 / 88.0 + minInterSpace + inset + labelheight
        return CGSize(width: width, height: rowHeight)
    }
    
    
}

