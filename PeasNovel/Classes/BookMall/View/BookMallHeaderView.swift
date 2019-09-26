//
//  BookMallHeaderView.swift
//  PeasNovel
//
//  Created by lieon on 2019/3/29.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import JXSegmentedView

class BookMallHeaderView: UIView {
    
    @IBOutlet weak var searchVIew: UIStackView!
    @IBOutlet weak var searchInputBtn: UIButton!
    @IBOutlet weak var searchInputBtn1: UIButton!
    @IBOutlet weak var signBtn: UIButton!
    @IBOutlet weak var categoryBtn: UIButton!
    @IBOutlet weak var titleViewContainerView: UIView!
    fileprivate var status: BookMallHeaderViewStatus = .normal
    fileprivate var willBackColor: UIColor?
    var segmentedDataSource: JXSegmentedTitleDataSource?
    let segmentedView = JXSegmentedView()
    var titleTapAction: ((_ index: Int) -> Void)?
    var selectedIndex: Int = 0
    var segementScrollingFrom: ((_ leftIndex: Int, _ rightIndex: Int, _ percent: CGFloat, _ selectedIndex: Int) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()

        titleViewContainerView.addSubview(segmentedView)
        //配置数据源
        segmentedDataSource = JXSegmentedTitleDataSource()
        segmentedDataSource?.isTitleColorGradientEnabled = true
        segmentedDataSource?.titleNormalColor = UIColor.white
        segmentedDataSource?.titleSelectedColor = UIColor.theme
        segmentedDataSource?.titleNormalFont = UIFont.boldSystemFont(ofSize: 17)
        segmentedDataSource?.isTitleZoomEnabled = true
        segmentedDataSource?.titleSelectedZoomScale = 1.3
        segmentedDataSource?.isTitleStrokeWidthEnabled = true
        segmentedDataSource?.isSelectedAnimable = true
        let indicator = JXSegmentedIndicatorLineView()
        indicator.indicatorWidth = 20
        indicator.indicatorColor = UIColor.theme
        segmentedView.indicators = [indicator]
        segmentedView.dataSource = segmentedDataSource
        segmentedView.delegate = self
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        segmentedView.frame = titleViewContainerView.bounds
    }

    
    func config(_ titles:[String], selectedIndex: Int = 0) {
        self.selectedIndex = selectedIndex
        titleViewContainerView.backgroundColor = .clear
        segmentedDataSource?.titles = titles
        segmentedDataSource?.reloadData(selectedIndex: selectedIndex)
        segmentedView.reloadData()
        segmentedView.selectItemAt(index: selectedIndex)
        
        
    }
    
    func setTitle(progress: Float, sourceIndex: Int, targetIndex: Int) {
        if progress > 0.9 {
            selectedIndex = targetIndex
        }
         segmentedView.selectItemAt(index: targetIndex)
    }
    
    static func loadView() -> BookMallHeaderView {
        guard let view = Bundle.main.loadNibNamed("BookMallHeaderView", owner: nil, options: nil)?.first as? BookMallHeaderView else {
            return BookMallHeaderView()
        }
        
        return view
    }
    
    func styleChange(_ backgroundColor: UIColor) {
        willBackColor = backgroundColor
        if status.rawValue == BookMallHeaderViewStatus.top.rawValue {
            topStyle()
        } else {
            normalStyle()
        }
    }
    
    func topStyle() {
        if status.rawValue != BookMallHeaderViewStatus.top.rawValue {
             // 0x333333
            segmentedDataSource?.titleNormalColor = UIColor(0x333333)
            segmentedDataSource?.reloadData(selectedIndex: selectedIndex)
            segmentedView.reloadData()
            segmentedView.selectItemAt(index: selectedIndex)
        }
        status = .top
        self.searchVIew.alpha = 0
        self.categoryBtn.alpha = 0
        self.searchInputBtn1.alpha = 1
        self.backgroundColor = UIColor.white
       
    }
    
    
    func normalStyle() {
        if status.rawValue != BookMallHeaderViewStatus.normal.rawValue {
            segmentedDataSource?.titleNormalColor = UIColor.white
            segmentedDataSource?.reloadData(selectedIndex: selectedIndex)
            segmentedView.reloadData()
            segmentedView.selectItemAt(index: selectedIndex)
        }
         status = .normal
        self.searchVIew.alpha = 1
        self.categoryBtn.alpha = 1
        self.searchInputBtn1.alpha = 0
        self.backgroundColor = self.willBackColor
        
    }
}

enum BookMallHeaderViewStatus: Int {
    case normal = 0
    case top = 1
}




extension BookMallHeaderView: JXSegmentedViewDelegate {
    func segmentedView(_ segmentedView: JXSegmentedView, didSelectedItemAt index: Int) {
        selectedIndex = index
//        segmentedView.reloadItem(at: index)
        
    }
    
    func segmentedView(_ segmentedView: JXSegmentedView, didClickSelectedItemAt index: Int) {
        titleTapAction?(index)
    }
    
    func segmentedView(_ segmentedView: JXSegmentedView, scrollingFrom leftIndex: Int, to rightIndex: Int, percent: CGFloat) {
        segementScrollingFrom?(leftIndex, rightIndex, percent, segmentedView.selectedIndex)
    }
}
