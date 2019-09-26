//
//  CollectionTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/8.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class CollectionTableViewCell: UITableViewCell {
    @IBOutlet weak var collectionView: UICollectionView!
    let questionOutput: PublishSubject<FeedbackQuestion> = .init()
    
    var bag = DisposeBag()
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.registerNibWithCell(ReadFavorCell.self)
        collectionView.delegate = self
    }

    func config(_ texts: [FeedbackQuestion]) {
        let items = Observable.just(texts)
        items.bind(to: collectionView.rx.items(cellIdentifier: String(describing: ReadFavorCell.self), cellType: ReadFavorCell.self)) { (row, element, cell) in
            cell.config(element.title, isSelcted: element.isSelected)
            cell.label.font = UIFont.systemFont(ofSize: 13)
        }
        .disposed(by: bag)
        
        collectionView.rx.modelSelected(FeedbackQuestion.self)
            .bind(to: questionOutput)
            .disposed(by: bag)
        
    }
  
    
}



extension CollectionTableViewCell: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 25, left: 14, bottom: 25, right: 14)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 8
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let rowHeight: CGFloat = 44
        let minInterSpace: CGFloat = 8
        let inset: CGFloat = 14
        return CGSize(width: (UIScreen.main.bounds.width - minInterSpace * 3 - inset * 2) / 4.0001, height: rowHeight)
    }
    
    
}

