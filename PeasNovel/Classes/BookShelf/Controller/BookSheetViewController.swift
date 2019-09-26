//
//  BookSheetViewController.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/17.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxDataSources

class BookSheetViewController: BaseViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var closeButton: UIButton!
    @IBOutlet weak var nameLabel: UILabel!
    private var originRect = UIScreen.main.bounds
    
    var headerBackgroundImage: UIImage?
    
    let dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<Void, BookSheetListModel>>(configureCell: { (dataSource, collectionView, ip, model) -> UICollectionViewCell in
        let cell = collectionView.dequeueCell(TopImageDownTextCollectionViewCell.self, for: ip)
        cell.set(model)
        return cell
    })
    
    @IBOutlet weak var flurImageView: UIImageView!
    convenience init(_ viewModel: BookSheetViewModel, from rect: CGRect = UIScreen.main.bounds) {
        self.init(nibName: "BookSheetViewController", bundle: nil)
        
        originRect = rect
        
        self.rx
            .viewDidLoad
            .subscribe(onNext: { [unowned self] in
                self.configUI()
                self.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx
            .viewWillAppear
            .bind(to: viewModel.viewWillAppear)
            .disposed(by: bag)
        
        self.rx
            .viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
        
    }


    func config(_ viewModel: BookSheetViewModel) {
        
        closeButton
            .rx
            .tap
            .asObservable()
            .subscribe(onNext: { [unowned self] in
                self.dismiss(animated: true, completion: nil)
                self.navigationController?.popViewController(animated: true)
            })
            .disposed(by: bag)
        
        collectionView
            .rx
            .modelSelected(BookSheetListModel.self)
            .bind(to: viewModel.itemSelected)
            .disposed(by: bag)
        
        viewModel
            .sections
            .drive(self.collectionView.rx.items(dataSource: self.dataSource))
            .disposed(by: bag)
        
        viewModel
            .sheetName
            .drive(self.nameLabel.rx.text)
            .disposed(by: bag)
        
        viewModel
            .toReader
            .subscribe(onNext: {
                BookReaderHandler.jump($0.book_id)
            })
            .disposed(by: bag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.delegate = nil
    }
   
    func configUI() {
        
        navigationController?.delegate = self
        
        self.collectionView.delegate = self
        self.collectionView.registerNibWithCell(TopImageDownTextCollectionViewCell.self)
        
        let count = self.navigationController?.viewControllers.count ?? 2
        if let vc = self.navigationController?.viewControllers[count-2] {
            let size = CGSize(width: UIScreen.main.bounds.width,
                              height: UIScreen.main.bounds.width * 9/16)
            self.flurImageView.image = UIImage.screenshot(size: size, in: vc.view)
        }
        
    }
}

extension BookSheetViewController: UINavigationControllerDelegate {
    
    func navigationController(_ navigationController: UINavigationController, animationControllerFor operation: UINavigationController.Operation, from fromVC: UIViewController, to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return ScaleTransitionAnimation(from: originRect, isPresent: operation == .push)
    }
}

extension BookSheetViewController: UICollectionViewDelegateFlowLayout {
    
    
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
        return CGSize(width: width, height: width*4/3 + 10 + 24 + 10)
    }
}
