//
//  BookMallViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/3/26.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import SnapKit
import RxSwift
import JXSegmentedView

class BookMallViewController: BaseViewController {
    struct UISize {
        static let headerHeight: CGFloat = UIDevice.current.isiPhoneXSeries ? 120: 140
    }
    fileprivate lazy var headerView: BookMallHeaderView = {
        let view = BookMallHeaderView.loadView()
        return view
    }()
    lazy var listContainerView: JXSegmentedListContainerView = {[weak self] in
        return JXSegmentedListContainerView(dataSource: self!)
    }()
    
    fileprivate var childVcs: [BaseViewController] = []
    
    convenience init(_ viewModel: BookMallViewModel) {
        self.init()
        self.rx.viewDidLoad
            .subscribe(onNext: { [weak self]() in
                self?.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx.viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
        
        self.rx
            .viewDidAppear
            .bind(to: viewModel.viewDidAppear)
            .disposed(by: bag)
        
        self.rx
            .viewDidDisappear
            .bind(to: viewModel.viewDidDisappear)
            .disposed(by: bag)
    }
    
    
    fileprivate func changeContentInset(_ currentIndex: Int, _ headerView: (BookMallHeaderView)) {
        
        if currentIndex >= childVcs.count {
            return
        }
        let maxY = headerView.frame.maxY 
        for (index, value) in childVcs.enumerated() {
            if index == 0 {
                guard let recomendVC = value as? BookMallRecommendViewController else {
                    return
                }
                if  recomendVC.collectionView != nil {
                    recomendVC.collectionView.contentInset = UIEdgeInsets(top: maxY, left: 0, bottom: 88, right: 0)
                }
                /// -50 mj_header的高度
                recomendVC.outterContentInset =  UIEdgeInsets(top: maxY - 50, left: 0, bottom: 88, right: 0)
            } else {
                guard let recomendCateVC = value as? BookMallRecommendCateViewController else {
                    return
                }
                if recomendCateVC.collectionView != nil {
                    recomendCateVC.collectionView.contentInset = UIEdgeInsets(top: maxY, left: 0, bottom: 88, right: 0)
                }
                recomendCateVC.outterContentInset =  UIEdgeInsets(top: maxY, left: 0, bottom: 88, right: 0)
            }
            
        }
    }
    
    fileprivate func config(_ viewModel: BookMallViewModel) {
        let recommnedVm = BookMallRecommendViewModel()
        viewModel.userCategorylists
            .asObservable()
            .bind(to: recommnedVm.userCategorylistsInput)
            .disposed(by: bag)
        
        headerView.categoryBtn.rx.tap.map { ReadFavorViewModel() }
            .subscribe(onNext: { [weak self] in
                self?.present(NavigationViewController(rootViewController: ReadFavorViewController($0)), animated: true, completion: nil)
            })
            .disposed(by: bag)
       
        headerView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UISize.headerHeight)
        view.addSubview(listContainerView)
        view.addSubview(headerView)
        headerView.segmentedView.contentScrollView = listContainerView.scrollView
        listContainerView.snp.makeConstraints {
            $0.left.right.bottom.top.equalTo(0)
        }
        headerView.titleTapAction = {[weak self] targetIndex in
            self?.listContainerView.didClickSelectedItem(at: targetIndex)
        }
        
        headerView.segementScrollingFrom = {[weak self] (leftIndex, rightIndex, percent, selectedIndex) in
             self?.listContainerView.segmentedViewScrolling(from: leftIndex,
                                                           to: rightIndex,
                                                           percent: percent,
                                                           selectedIndex: selectedIndex)
        }
        view.backgroundColor = UIColor.white
        recommnedVm.recommendPositionMoreInput
            .asObservable()
            .bind(to: viewModel.recommendPositionMoreInput)
            .disposed(by: bag)
        
        viewModel.activity
            .debug()
            .drive(self.rx.loading)
            .disposed(by: bag)
        
        viewModel.exception
            .drive(self.rx.exception)
            .disposed(by: bag)
        
        self.exception.asObservable()
            .mapToVoid()
            .bind(to: viewModel.reloadInput)
            .disposed(by: bag)
        
        self.exception.asObservable()
            .mapToVoid()
            .bind(to: recommnedVm.exceptionInput)
            .disposed(by: bag)
        
        viewModel.userCategorylists
            .asObservable()
            .debug()
            .map { $0.isEmpty }
            .bind(to: headerView.rx.isHidden)
            .disposed(by: bag)
        
        viewModel.userCategorylists
            .asObservable()
            .debug()
            .map { $0.isEmpty }
            .bind(to: listContainerView.rx.isHidden)
            .disposed(by: bag)

   
       viewModel.userReaderFavorOutput
            .drive(onNext: {[weak self] (lists) in
                guard let weakSelf = self else {
                    return
                }
                var titles = ["精品"]
                titles.append(contentsOf:lists.map {$0.short_name ?? ""})
                weakSelf.headerView.config(titles)
                if weakSelf.childVcs.isEmpty {
                    let recommendVC = BookMallRecommendViewController(recommnedVm, contentInset: UIEdgeInsets(top: weakSelf.headerView.frame.maxY, left: 0, bottom: 0, right: 0))
                    weakSelf.childVcs.append(recommendVC)
                } else {
                    /// 精品不移除
                    weakSelf.childVcs.removeAll(where: {$0 is BookMallRecommendCateViewController})
                    weakSelf.listContainerView.didClickSelectedItem(at: 0)
                }
                var categoryVcs: [BookMallRecommendCateViewController] = []
                for _ in lists {
                 categoryVcs.append( BookMallRecommendCateViewController(BookMallCategoryViewModel(), contentInset: UIEdgeInsets(top: weakSelf.headerView.frame.maxY, left: 0, bottom: 88, right: 0)))
                   
                }
                weakSelf.childVcs.append(contentsOf: categoryVcs)
                for(index, model) in lists.enumerated() {
                    categoryVcs[index].rx.viewDidLoad
                        .map { model }
                        .bind(to:  categoryVcs[index].categoryInput)
                        .disposed(by:  categoryVcs[index].bag)

                }
                weakSelf.listContainerView.reloadData()
            })
            .disposed(by: bag)
        
        viewModel.indexOutput
            .subscribe(onNext: {[weak self] (index) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.headerView.setTitle(progress: 1, sourceIndex: 0, targetIndex: index + 1)
                weakSelf.listContainerView.didClickSelectedItem(at: index + 1)
            })
            .disposed(by: bag)
        
        
        headerView.searchInputBtn1
            .rx.tap.mapToVoid()
            .subscribe(onNext: { [weak self] in
                let vc = SearchViewController(SearchViewModel())
                self?.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: bag)
        
        headerView.searchInputBtn
            .rx.tap.mapToVoid()
            .subscribe(onNext: { [weak self] in
                let vc = SearchViewController(SearchViewModel())
                self?.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx
            .notification(Notification.Name.UIUpdate.bookMallColorChange)
            .map {$0.object}
            .unwrap()
            .map { $0 as? UIColor }
            .unwrap()
            .subscribe(onNext: { [weak self] (color) in
                UIView.animate(withDuration: 0.25, animations: {
                    self?.headerView.styleChange(color)
                })
            })
            .disposed(by: bag)
        //
        NotificationCenter.default.rx
            .notification(Notification.Name.UIUpdate.bookMallBackTop)
            .mapToVoid()
            .subscribe(onNext: {[weak self] (sv) in
                guard let weakSelf = self else {
                    return
                }
                UIView.animate(withDuration: 0.25, animations: {
                    weakSelf.headerView.frame.origin.y = 0
                    weakSelf.headerView.normalStyle()
                }, completion: { flag in
                    if flag {
                        NotificationCenter.default.post(name: NSNotification.Name.UIUpdate.bookMallHeaderViewChange, object:  weakSelf.headerView)
                    }
                })
                UIApplication.shared.setStatusBarStyle(.lightContent, animated: true)
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx
            .notification(Notification.Name.UIUpdate.bookMallScrollChange)
            .map {$0.object}
            .unwrap()
            .map { $0 as? UIScrollView }
            .subscribe(onNext: {[weak self] (sv) in
                
                guard let weakSelf = self, let velocity = sv?.panGestureRecognizer.velocity(in: sv?.superview) else {
                    return
                }
                if velocity.y > 0 {
                    UIView.animate(withDuration: 0.25, animations: {
                        weakSelf.headerView.frame.origin.y = 0
                        weakSelf.headerView.normalStyle()
                    }, completion: { flag in
                        if flag {
                               NotificationCenter.default.post(name: NSNotification.Name.UIUpdate.bookMallHeaderViewChange, object:  weakSelf.headerView)
                        }
                    })
                    UIApplication.shared.setStatusBarStyle(.lightContent, animated: true)
                  
                } else if velocity.y < 0  {
                    UIApplication.shared.setStatusBarStyle(.default, animated: true)
                    UIView.animate(withDuration: 0.25, animations: {
                        if UIDevice.current.isiPhoneXSeries {
                             weakSelf.headerView.frame.origin.y = -(UISize.headerHeight + 22 - 80)
                        } else {
                            weakSelf.headerView.frame.origin.y = -(UISize.headerHeight - 80)
                        }
                       
                        weakSelf.headerView.topStyle()
                    }, completion: {  flag in
                        if flag {
                            NotificationCenter.default.post(name: NSNotification.Name.UIUpdate.bookMallHeaderViewChange, object:  weakSelf.headerView)
                        }
                    })
                }
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.UIUpdate.bookMallHeaderViewChange)
            .map { $0.object as? BookMallHeaderView}
            .unwrap()
            .map { $0 }
            .subscribe(onNext: { [weak self](headerView) in
                guard let weakSelf = self else {
                    return
                }
                let currentIndex = headerView.selectedIndex
                weakSelf.changeContentInset(currentIndex, headerView)
            })
            .disposed(by: bag)
        
        
        NotificationCenter.default.rx.notification(Notification.Name.UIUpdate.adjustReadFavorAction)
            .subscribe(onNext: {[weak self] (_) in
                guard let weakSelf = self else {
                    return
                }
                 weakSelf.present(NavigationViewController(rootViewController: ReadFavorViewController(ReadFavorViewModel())), animated: true, completion: nil)
            })
            .disposed(by: bag)
    }
    
    private var islayout: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !islayout {
            if UIDevice.current.isiPhoneXSeries {
                headerView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UISize.headerHeight + UIDevice.current.safeAreaInsets.top)
            } else {
                headerView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: UISize.headerHeight)
            }
        }
        islayout = true
    }
}

extension BookMallViewController: JXSegmentedListContainerViewDataSource {
    func numberOfLists(in listContainerView: JXSegmentedListContainerView) -> Int {
       
        return childVcs.count
    }
    
    func listContainerView(_ listContainerView: JXSegmentedListContainerView, initListAt index: Int) -> JXSegmentedListContainerViewListDelegate {
        return childVcs[index]
    }
}


