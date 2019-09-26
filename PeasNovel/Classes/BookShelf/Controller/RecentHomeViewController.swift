//
//  RecentHomeViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/6.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import JXSegmentedView
import RxSwift
import RxCocoa

class RecentHomeViewController: BaseViewController {
    var selectedIndex: Int = 0
    var segmentedDataSource: JXSegmentedTitleDataSource?
    let segmentedView = JXSegmentedView()
    lazy var listContainerView: JXSegmentedListContainerView = {[weak self] in
        return JXSegmentedListContainerView(dataSource: self!)
    }()
    fileprivate var childVcs: [BaseViewController] = []
    
    
    convenience init( _ recentVM: RecentlyViewModel,
                      bookCollectionVM: BookCollectionViewModel = BookCollectionViewModel()) {
        self.init(nibName: "RecentHomeViewController", bundle: nil)
        let recentVC = RecentlyViewController(recentVM)
        let collectionVC = BookCollectionViewController(bookCollectionVM)
        addChild(recentVC)
        addChild(collectionVC)
        childVcs = [recentVC, collectionVC]
        
        collectionVC.exception
            .filter { $0.desc == "empty"}
            .observeOn(MainScheduler.instance)
            .mapToVoid()
            .subscribe(onNext: { [weak self](_) in
                guard let weakSelf = self else {
                    return
                }
                for subView in weakSelf.view.subviews {
                    subView.removeFromSuperview()
                }
                weakSelf.navigationController?.popToRootViewController(animated: false)
                (UIApplication.shared.keyWindow?.rootViewController as! TabBarController).selectedIndex = 1
            })
            .disposed(by: bag)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        segmentedView.frame = CGRect(x: 0, y: 0, width: 215, height: 32)
        segmentedDataSource = JXSegmentedTitleDataSource()
        segmentedDataSource?.isTitleColorGradientEnabled = true
        segmentedDataSource?.titleNormalColor = UIColor(0x999999)
        segmentedDataSource?.titleSelectedColor = UIColor(0x333333)
        segmentedDataSource?.titleNormalFont = UIFont.systemFont(ofSize: 17)
        segmentedDataSource?.isTitleZoomEnabled = true
        segmentedDataSource?.titleSelectedZoomScale = 1
        segmentedDataSource?.isTitleStrokeWidthEnabled = true
        segmentedDataSource?.isSelectedAnimable = true
        segmentedDataSource?.titles = ["最近阅读", "书架收藏"]
        segmentedDataSource?.reloadData(selectedIndex: selectedIndex)
        let indicator = JXSegmentedIndicatorLineView()
        indicator.indicatorWidth = 50
        indicator.indicatorColor = UIColor.theme
        segmentedView.indicators = [indicator]
        segmentedView.dataSource = segmentedDataSource
        segmentedView.delegate = self
        segmentedView.selectItemAt(index: selectedIndex)
        navigationItem.titleView = segmentedView
        view.addSubview(listContainerView)
        segmentedView.contentScrollView = listContainerView.scrollView
        listContainerView.snp.makeConstraints {
            $0.left.right.bottom.top.equalTo(0)
        }
    }
    
    func selectItem( _ index: Int) {
        self.selectedIndex = index
        segmentedView.selectItemAt(index: index)
        listContainerView.segmentedViewScrolling(from: 0, to: 1, percent: 1, selectedIndex: index)
    }
}


extension RecentHomeViewController: JXSegmentedViewDelegate {
    func segmentedView(_ segmentedView: JXSegmentedView, didSelectedItemAt index: Int) {
        selectedIndex = index
    }
    
    func segmentedView(_ segmentedView: JXSegmentedView, didClickSelectedItemAt index: Int) {
         listContainerView.didClickSelectedItem(at: index)
    }
    
    func segmentedView(_ segmentedView: JXSegmentedView, scrollingFrom leftIndex: Int, to rightIndex: Int, percent: CGFloat) {
        listContainerView.segmentedViewScrolling(from: leftIndex, to: rightIndex, percent: percent, selectedIndex: segmentedView.selectedIndex)
    }
}



extension RecentHomeViewController: JXSegmentedListContainerViewDataSource {
    func numberOfLists(in listContainerView: JXSegmentedListContainerView) -> Int {
        
        return childVcs.count
    }
    
    func listContainerView(_ listContainerView: JXSegmentedListContainerView, initListAt index: Int) -> JXSegmentedListContainerViewListDelegate {
        return childVcs[index]
    }
}

