//
//  ContainerCollectionViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/3/29.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources

class ContainerCollectionViewCell: UICollectionViewCell {
    struct UISize {
        static let imageWidth: CGFloat = (UIScreen.main.bounds.width - 14 * 5) / 4.0001
        static let imageHeight: CGFloat = UISize.imageWidth  * 104 / 76 * 1.0 + 20.0.fitScale
        static let adSize: CGSize = CGSize(width: imageWidth, height: imageHeight)
        static let cellWidth = UISize.adSize.width
        static let cellHeight = imageHeight + 10 + 25
        static let  minimumLineSpacing: CGFloat = 14
        static let  minimuminterSpacing: CGFloat = 14
    }
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    let recommendSelected: PublishSubject<BookInfo> = .init()
    let dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<String, BookInfo>>(configureCell: {_, cv, ip, element in
        if let config = element.localTempAdConfig {
            let cell = CollectionCellOneTitleService.chooseCell(config, collectionView: cv, indexPath: ip)
            return cell
        } else{
            let cell = cv.dequeueCell(TopImageDownTextCollectionViewCell.self, for: ip)
            cell.set(element)
            cell.badgeLabel.isHidden = true
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
        collectionView.registerNibWithCell(TopImageDownTextCollectionViewCell.self)
        collectionView.registerNibWithCell(IMInfoOneTitleCollectionViewCell.self)
        collectionView.registerClassWithCell(UICollectionViewCell.self)
        collectionView.registerNibWithCell(GDTOneImageNativeExpressCollectionViewCell.self)
        collectionView.registerNibWithCell(BUInfoOneTitleCollectionViewCell.self)
        collectionView.delegate = self
        collectionView.isScrollEnabled = false
    }
    
    func config(_ items: [BookInfo]) {
        Observable.just([SectionModel<String, BookInfo>(model: "", items: items)])
            .bind(to: collectionView.rx.items(dataSource: dataSource))
            .disposed(by: bag)
    
        collectionView
            .rx
            .modelSelected(BookInfo.self)
            .asObservable()
            .filter{ !$0.book_id.isEmpty }
            .bind(to: self.recommendSelected)
            .disposed(by: bag)
        
        /// 上报点击
        collectionView.rx.modelSelected(BookInfo.self)
            .filter { !$0.book_id.isEmpty}
            .subscribe(onNext: { [weak self](book) in
                StatisticHandler.userReadActionParam["from_type"] = "100"
                var reportParam = [String: String]()
                reportParam["from_type"] = "7"
                reportParam["book_id"] = book.book_id
                NotificationCenter.default.post(name: NSNotification.Name.Statistic.goodBookRecommend, object: reportParam)
                if let index = self?.dataSource.sectionModels[0].items.lastIndex(where: {$0.book_id == book.book_id}) {
                     NotificationCenter.default.post(name: NSNotification.Name.Statistic.clickEvent, object: "HSTJ_POSITION\(index + 1)_DD")
                }
            })
            .disposed(by: bag)
        
        /// 上报曝光
        collectionView.rx.willDisplayCell
            .debug()
            .map { $0.at }
            .subscribe(onNext: {[weak self] (idexPath) in
                guard let weakSelf = self else {
                    return
                }
                let item = weakSelf.dataSource.sectionModels[idexPath.section].items[idexPath.row]
                if !item.book_id.isEmpty {
                    var reportParam = [String: String]()
                    reportParam["from_type"] = "6"
                    reportParam["book_id"] = item.book_id
                    NotificationCenter.default.post(name: NSNotification.Name.Statistic.goodBookRecommend, object: reportParam)
                }
            })
            .disposed(by: bag)
        
        
    }
    

}


extension ContainerCollectionViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
       
      
        return CGSize(width:UISize.cellWidth , height: UISize.cellHeight) // 2: 3
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
}
