//
//  SearchHotTableViewCell.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/16.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources

class SearchHotTableViewCell: UITableViewCell {

    @IBOutlet weak var collectionView: UICollectionView!
    
    let itemSelected: PublishSubject<SearchHotModel> = .init()
    
    let dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<String, SearchHotModel>>(configureCell: {_, cv, ip, model in
        let cell = cv.dequeueCell(SearchRecommnedCollectionViewCell.self, for: ip)
        cell.textLabel.text = model.title
        return cell
    })
    
    var bag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        collectionView.registerNibWithCell(SearchRecommnedCollectionViewCell.self)
        collectionView.delegate = self
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }

    func config(_ items: [SearchHotModel]) {
        bag = DisposeBag()
        
        Observable
            .just(items)
            .map{ [SectionModel<String, SearchHotModel>(model: "", items: $0)] }
            .bind(to: self.collectionView.rx.items(dataSource: self.dataSource))
            .disposed(by: bag)
        
        collectionView
            .rx
            .modelSelected(SearchHotModel.self)
            .bind(to: self.itemSelected)
            .disposed(by: bag)
    }
    
}


extension SearchHotTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width / 2.0001, height: 35)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 7, left: 0, bottom: 7, right: 0)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        UIApplication.shared.keyWindow?.endEditing(true)
    }
}
