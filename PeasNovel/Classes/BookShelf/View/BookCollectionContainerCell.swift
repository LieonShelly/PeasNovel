//
//  BookCollectionContainerCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/6.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources

class BookCollectionContainerCell: UICollectionViewCell {
    struct UISize {
        static let imageWidth: CGFloat = 88
        static let imageHeight: CGFloat = 119
        static let adSize: CGSize = CGSize(width: imageWidth, height: imageHeight)
        static let cellWidth = UISize.adSize.width
        static let cellHeight = imageHeight + 10 + 24 + 10 + 20
        static let  minimumLineSpacing: CGFloat = 23
        static let  minimuminterSpacing: CGFloat = 23
    }
    @IBOutlet weak var collectionView: UICollectionView!
    let itemSelected: PublishSubject<BookInfo> = .init()
    let seeMore: PublishSubject<Void> = .init()
    let selectedFrame: PublishSubject<CGRect> = .init()
    
    let dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<String, BookInfo>>(configureCell: {_, cv, ip, model in
        if model.book_type == 2 {
            let cell = cv.dequeueCell(BookCollectionListCell.self, for: ip)
            cell.imgContainerHeight.constant = UISize.imageHeight
            cell.set(model)
            return cell
        } else if model.book_type == 3 {
            let cell = cv.dequeueCell(BookCollectionWebCell.self, for: ip)
            cell.set(model)
            return cell
        } else if model.book_type == -11 {
            let cell = cv.dequeueCell(BookCollotionSeeMoreCell.self, for: ip)
            return cell
        } else{
            let cell = cv.dequeueCell(BookCollectionTopImageDownTextCell.self, for: ip)
            cell.imageHeight.constant = UISize.imageHeight
            cell.set(model)
            return cell
        }
    })
    
    var bag = DisposeBag()
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        collectionView.frame = bounds
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.registerNibWithCell(BookCollectionWebCell.self)
        collectionView.registerNibWithCell(BookCollectionTopImageDownTextCell.self)
        collectionView.registerNibWithCell(BookCollectionListCell.self)
        collectionView.registerClassWithCell(UICollectionViewCell.self)
        collectionView.registerNibWithCell(BookCollotionSeeMoreCell.self)
        collectionView.delegate = self
    }
    
    func config(_ items: [BookInfo]) {
        let seeMore = BookInfo()
        seeMore.book_type = -11
        var items = items
        items.append(seeMore)
        Observable.just([SectionModel<String, BookInfo>(model: "", items: items)])
            .bind(to: collectionView.rx.items(dataSource: dataSource))
            .disposed(by: bag)
        
        collectionView
            .rx
            .modelSelected(BookInfo.self)
            .asObservable()
            .filter{ !$0.book_id.isEmpty }
            .bind(to: self.itemSelected)
            .disposed(by: bag)
        
        collectionView
            .rx
            .modelSelected(BookInfo.self)
             .debug()
            .asObservable()
            .filter { $0.book_type == -11 } // 瞎鸡巴写的一个类型
            .mapToVoid()
            .debug()
            .bind(to: self.seeMore)
            .disposed(by: bag)
       
    }
    
}


extension BookCollectionContainerCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width:UISize.cellWidth , height: UISize.cellHeight)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left:  UISize.minimumLineSpacing, bottom: 0, right:  UISize.minimumLineSpacing)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return UISize.minimumLineSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return UISize.minimuminterSpacing
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let cell = collectionView.cellForItem(at: indexPath)
        let frame1 = collectionView.convert(cell?.frame ?? .zero, to: self.contentView)
        let frame2 = self.contentView.convert(frame1, to: self)
        selectedFrame.onNext(frame2)
    }
}
