//
//  ClassifyViewController.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/21.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxDataSources
import PKHUD

/// 书城 -> 分类
class ClassifyViewController: BaseViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    let dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<String?, ClassifyModel>>(configureCell: {_, cv, ip, model in
            let cell = cv.dequeueCell(ClassifyCollectionViewCell.self, for: ip)
            cell.set(model.category_img)
            return cell
    }, configureSupplementaryView: { (ds, cv, kind, ip) in
        if kind == UICollectionView.elementKindSectionHeader {
            let header = cv.dequeueReusableView(BookMallSectionView.self, ofKind: UICollectionView.elementKindSectionHeader, for: ip)
            header.onlyTitle(ds[ip.section].model)
            return header
        }else {
            let reuseView = cv.dequeueReusableView(UICollectionReusableView.self, ofKind: kind, for: ip)
            reuseView.backgroundColor = UIColor(0xF4F6F9)
            return reuseView
        }
    })


    convenience init(_ viewModel: ClassifyViewModel) {
        self.init(nibName: "ClassifyViewController", bundle: nil)
        
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
    
    func config(_ viewModel: ClassifyViewModel) {
        viewModel.activityDriver
            .drive(self.rx.loading)
            .disposed(by: bag)
        
        viewModel.activityDriver
            .drive(HUD.loading)
            .disposed(by: bag)
        
        viewModel.dataEmpty
            .drive(collectionView.rx.isHidden)
            .disposed(by: bag)
        
        viewModel.exceptionOuptputDriver
            .drive(self.rx.exception)
            .disposed(by: bag)
        
        collectionView
            .rx
            .modelSelected(ClassifyModel.self)
            .bind(to: viewModel.itemDidSelected)
            .disposed(by: bag)
        
        
        viewModel
            .sections
            .drive(self.collectionView.rx.items(dataSource: self.dataSource))
            .disposed(by: bag)
        
        viewModel
            .classifyListViewModel
            .subscribe(onNext: { [unowned self] in
                let vc = ClassifyListController($0)
                self.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: bag)
    }
    
    func configUI() {
        
        self.title = "分类"
        
        collectionView.registerNibWithCell(ClassifyCollectionViewCell.self)
        collectionView.registerNibWithReusableView(BookMallSectionView.self,
                                                   forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader)
        
        collectionView.registerClassWithReusableView(UICollectionReusableView.self,
                                                     forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter)
        collectionView.delegate = self
        
    }
    
}

extension ClassifyViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 13
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 7
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 50)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = (UIScreen.main.bounds.size.width - 14*2 - 7)/2.0001
        let height = width * 288/486
        return CGSize(width: width, height: height)
    }
    
}
