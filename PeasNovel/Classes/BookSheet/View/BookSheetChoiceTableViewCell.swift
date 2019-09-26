//
//  BookSheetChoiceTableViewCell.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/22.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxDataSources

class BookSheetChoiceTableViewCell: UITableViewCell {
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var favorButton: UIButton!
    @IBOutlet weak var introLabel: UILabel!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var countLabel: InsetsLabel!
    @IBOutlet weak var tagLabel: InsetsLabel!
    
    var favorAction: PublishSubject<String> = .init()
    
    let itemSelected: PublishSubject<BookSheetListModel> = .init()
    
    let dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<Void, BookSheetListModel>>(configureCell: {_, cv, ip, model in
        let cell = cv.dequeueCell(ClassifyCollectionViewCell.self, for: ip)
        cell.set(model.cover_url)
        return cell
    })
    
    var bag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        countLabel.edgeInsets = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
        countLabel.layer.cornerRadius = 2
        countLabel.layer.masksToBounds = true
        countLabel.layer.borderColor = UIColor(0x999999).cgColor
        countLabel.layer.borderWidth = 0.5
        
        tagLabel.edgeInsets = UIEdgeInsets(top: 4, left: 6, bottom: 4, right: 6)
        tagLabel.layer.cornerRadius = 2
        tagLabel.layer.masksToBounds = true
        tagLabel.layer.borderColor = UIColor(0x999999).cgColor
        tagLabel.layer.borderWidth = 0.5
        
        collectionView.registerNibWithCell(ClassifyCollectionViewCell.self)
        collectionView.delegate = self
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }
    
    func set(_ item: BookSheetModel) {
        titleLabel.text = item.boutique_title
        introLabel.text = item.boutique_intro
        countLabel.text = "\(item.book_num)本书"
        if let tag = item.category_short_name, tag.length > 0 {
            tagLabel.text = tag
            tagLabel.isHidden = false
        }else{
            tagLabel.isHidden = true
        }
        
        favorButton.isHidden = item.is_case
        
        config(item.id, list: item.book_lists ?? [])
    }
    
    private func config(_ bookId: String, list: [BookSheetListModel]) {
        
        
        bag = DisposeBag()
        
        Observable
            .just(list)
            .map{ [SectionModel<Void, BookSheetListModel>(model: (), items: $0)] }
            .bind(to: self.collectionView.rx.items(dataSource: self.dataSource))
            .disposed(by: bag)
        
        collectionView
            .rx
            .modelSelected(BookSheetListModel.self)
            .bind(to: self.itemSelected)
            .disposed(by: bag)
        
        favorButton
            .rx
            .tap
            .map{ bookId }
            .bind(to: favorAction)
            .disposed(by: bag)
    }
    
}


extension BookSheetChoiceTableViewCell: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (ScreenWidth-14*2-12*3)/4.0001
        return CGSize(width: width, height: width/75*103)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 6, left: 14, bottom: 6, right: 14)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 12
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 0
    }
}
