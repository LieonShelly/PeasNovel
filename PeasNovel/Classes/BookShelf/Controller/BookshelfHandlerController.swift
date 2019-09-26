//
//  BookshelfHandlerController.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/16.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxDataSources
import PKHUD

class BookshelfHandlerController: BaseViewController {

    @IBOutlet weak var selectButton: UIButton!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var deleteButton: UIButton!
    
    let dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<Void, BookInfo>>(configureCell: { (dataSource, collectionView, ip, model) -> UICollectionViewCell in
        if model.book_type == 2 {
            let cell = collectionView.dequeueCell(BookListCollectionViewCell.self, for: ip)
            cell.set(model, isFlur: true)
            return cell
        } else if model.book_type == 3 {
            let cell = collectionView.dequeueCell(BookCollectionWebCell.self, for: ip)
            cell.subtitleHeigiht.constant = 0
             cell.set(model, isFlur: true)
            return cell
        } else{
            let cell = collectionView.dequeueCell(TopImageDownTextCollectionViewCell.self, for: ip)
            cell.set(model, isFlur: true)
            return cell
        }
    })
    
    convenience init(_ viewModel: BookshelfHandlerViewModel) {
        self.init(nibName: "BookshelfHandlerController", bundle: nil)
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
    
    func config(_ viewModel: BookshelfHandlerViewModel) {
        
        collectionView
            .rx
            .modelSelected(BookInfo.self)
            .bind(to: viewModel.itemSelected)
            .disposed(by: bag)
        
        selectButton
            .rx
            .tap
            .bind(to: viewModel.leftAction)
            .disposed(by: bag)
        
        deleteButton
            .rx
            .tap
            .bind(to: viewModel.deleteAction)
            .disposed(by: bag)
        
        viewModel
            .sections
            .drive(self.collectionView.rx.items(dataSource: self.dataSource))
            .disposed(by: bag)
        
        viewModel
            .leftButtonTitle
            .drive(selectButton.rx.title(for: .normal))
            .disposed(by: bag)
        
        viewModel
            .deleteButtonTitle
            .drive(deleteButton.rx.title(for: .normal))
            .disposed(by: bag)
        
        viewModel
            .popController
            .subscribe(onNext: { [unowned self] in
                self.dismiss(animated: true, completion: nil)
            })
            .disposed(by: bag)
        
        viewModel
            .deleteButtonEnable
            .drive(deleteButton.rx.isEnabled)
            .disposed(by: bag)
        
        viewModel
            .tipHud
            .drive(HUD.flash)
            .disposed(by: bag)
        
    }
    
    func configUI() {
        
        modalPresentationStyle = .custom
        modalTransitionStyle = .crossDissolve
        
        collectionView.delegate = self
        
        deleteButton.setBackgroundImage(UIImage(color: 0x00CF7A), for: .normal)
        deleteButton.setBackgroundImage(UIImage(color: 0xEEEEEE), for: .disabled)
        
        collectionView.registerNibWithCell(BookCollectionWebCell.self)
        collectionView.registerNibWithCell(TopImageDownTextCollectionViewCell.self)
        collectionView.registerNibWithCell(BookListCollectionViewCell.self)
    }

    @IBAction func cancelAction(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    

}

extension BookshelfHandlerController: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 14, left: 14, bottom: 30, right: 14)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 18
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 18
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {        
        let width = (UIScreen.main.bounds.width - 14 * 2  - 18 * 2) / 3.0001
        return CGSize(width: width, height: width * 4 / 3 + 10 + 24 + 10)
    }
}
