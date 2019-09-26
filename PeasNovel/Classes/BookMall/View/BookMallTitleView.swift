//
//  BookMallTitleView.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/30.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class BookMallTitleView: UIView {
    @IBOutlet weak var collectionView: UICollectionView!
    fileprivate lazy var  titles: [BookMallTitleModel] = []
    var titleTapAction: ((_ index: Int) -> Void)?
    var scrollLine: UILabel!
    

    override func layoutSubviews() {
        super.layoutSubviews()
        scrollLine.frame = CGRect(x: 0, y: collectionView.bounds.height, width: 30, height: 3)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        scrollLine = UILabel()
        scrollLine.backgroundColor = UIColor.theme
        collectionView.addSubview(scrollLine)
        collectionView.registerNibWithCell(BookMallTitleVIewCell.self)
        collectionView.dataSource = self
        collectionView.delegate = self
        scrollLine.isHidden = false
        
        
        
    }
    
    static func loadView() -> BookMallTitleView {
        guard let view = Bundle.main.loadNibNamed("BookMallTitleView", owner: nil, options: nil)?.first as? BookMallTitleView else {
            return BookMallTitleView()
        }
        return view
    }
    
    func config( _ titles: [BookMallTitleModel], selecedIndex: Int) {
        if titles.isEmpty {
            return
        }
        self.titles = titles
        collectionView.reloadData()
       
    }
    
    func topStyle() {
        titles.forEach { $0.normalColor = UIColor(0x333333)}
         collectionView.reloadData()
    }
    
    func normalStyle() {
        titles.forEach { $0.normalColor = UIColor(0xffffff)}
         collectionView.reloadData()
    }
    
    
    func selected(_ index: Int) {
        let indexPath = IndexPath(item: index, section: 0)
        collectionView.scrollToItem(at: indexPath, at: UICollectionView.ScrollPosition.centeredHorizontally, animated: true)
       
    }
    
     func setTitle(progress: Float, sourceIndex: Int, targetIndex: Int) {
        if sourceIndex >= titles.count {
            return
        }
        if targetIndex >= titles.count {
            return
        }
        if progress > 0.9 {
            titles[sourceIndex].isSelected = false
            titles[targetIndex].isSelected = true
            let model = titles[targetIndex]
            let indexPath = IndexPath(item: targetIndex, section: 0)
            if let cell = collectionView.cellForItem(at: indexPath) as? BookMallTitleVIewCell {
                if model.isSelected {
                    cell.label.textColor = model.selectedColor
                    cell.label.font = model.selectedFont
                } else {
                    cell.label.textColor = model.normalColor
                    cell.label.font = model.normalFont
                }
            }
            if let cell = collectionView.cellForItem(at: indexPath) {
                UIView.animate(withDuration: 0.25) {
                    self.scrollLine.origin.x = cell.frame.origin.x
                }
                 scrollRectToVisibleCentered(on: cell.frame, isAnimate: true)
            }
            collectionView.reloadData()
           
        }
    
    }
    
    fileprivate func scrollRectToVisibleCentered(on visibleRect: CGRect, isAnimate: Bool) {
        let centeredRect = CGRect(x: visibleRect.origin.x + visibleRect.size.width / 2.0 - self.collectionView.frame.size.width / 2.0, y: visibleRect.origin.y + visibleRect.size.height / 2.0 - self.collectionView.frame.size.height / 2.0, width: self.collectionView.frame.size.width, height: self.collectionView.frame.size.height)
        self.collectionView.scrollRectToVisible(centeredRect, animated: isAnimate)
    }
}

extension BookMallTitleView: UICollectionViewDataSource {
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return titles.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueCell(BookMallTitleVIewCell.self, for: indexPath)
        let model = titles[indexPath.row]
         cell.label.text = model.title
        if model.isSelected {
            cell.label.textColor = model.selectedColor
            cell.label.font = model.selectedFont
        } else {
            cell.label.textColor = model.normalColor
            cell.label.font = model.normalFont
        }
        return cell
    }
}

extension BookMallTitleView: UICollectionViewDelegateFlowLayout, UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
            return UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 28
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.row >= titles.count {
            return .zero
        }
        let model = titles[indexPath.row]
        if model.isSelected {
            return CGSize(width: model.selectedlWidth, height: collectionView.bounds.height)
        } else {
            return CGSize(width: model.normalWidth, height: collectionView.bounds.height)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        titleTapAction?(indexPath.row)
        var sourceIndex = 0
        let targeIndex = indexPath.row
        for (index, title) in titles.enumerated() {
            if title.isSelected  {
                sourceIndex = index
            }
              titles[index].isSelected = false
        }
        titles[indexPath.row].isSelected = true
        if let cell = collectionView.cellForItem(at: indexPath) {
            let cellCenter = collectionView.convert(cell.center, to: self)
//            let inset =  titles[indexPath.row].selectedlWidth - titles[indexPath.row].normalWidth
            UIView.animate(withDuration: 0.25) {
                if targeIndex > sourceIndex {
                    self.scrollLine.center.x = cellCenter.x
                } else {
                    self.scrollLine.center.x = cellCenter.x
                }
            }
        }
        collectionView.reloadData()
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let model = titles[0]
        if model.isSelected, let cell = collectionView.cellForItem(at: IndexPath(item: 0, section: 0)){
            scrollLine.isHidden = false
            let cellCenter = collectionView.convert(cell.center, to: self)
            UIView.animate(withDuration: 0.25) {
                self.scrollLine.center.x = cellCenter.x
            }
        }
    }
}

class BookMallTitleModel {
    var title: String
    var normalColor: UIColor
    var selectedColor: UIColor
    var selectedFont: UIFont
    var normalFont: UIFont
    var isSelected: Bool = false
    var normalWidth: CGFloat {
       return title.width(font: normalFont, height: 25)
    }
    var selectedlWidth: CGFloat {
       return title.width(font: selectedFont, height: 30)
    }
    
    init(_ title: String,
         normalColor: UIColor,
         selectedColor: UIColor,
         isSelected: Bool,
         normalFont: UIFont,
         selectedFont: UIFont) {
        self.title = title
        self.normalColor = normalColor
        self.selectedColor = selectedColor
        self.isSelected = isSelected
        self.selectedFont = selectedFont
        self.normalFont = normalFont
    }
}
