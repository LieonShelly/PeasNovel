//
//  BookMallBannerCollectionViewCell.swift
//  Arab
//
//  Created by lieon on 2018/9/10.
//  Copyright © 2018年lieon. All rights reserved.
//

import UIKit
import FSPagerView

class BookMallBannerCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var pagerView: FSPagerView!
    @IBOutlet weak var pageControl: FSPageControl!
    @IBOutlet weak var bgView: UILabel!
//    @IBOutlet weak var colorView: UILabel!
    
    var didSelected:((Int) -> Void)?
    var urls: [String]?
    var colorStrs: [String]?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        contentView.backgroundColor = .clear
        pagerView.dataSource = self
        pagerView.delegate = self
        pagerView.register(UINib(nibName: "BannerImageCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "BannerImageCollectionViewCell")
        pagerView.interitemSpacing = 0
        pagerView.automaticSlidingInterval = 3.0
        pagerView.isInfinite = true
        pageControl.currentPage = 0
        
        pagerView.layer.cornerRadius = 3
        pagerView.layer.masksToBounds = true

        
//        pageControl.setImage(UIImage(named: "dot1"), for: UIControl.State.selected)
//        pageControl.setImage(UIImage(named: "dot0"), for: UIControl.State.normal)
    }
    
    func config(_ urls: [String], colors: [String]) {
        self.urls = urls
        self.colorStrs = colors
        pagerView.reloadData()
        pageControl.numberOfPages = urls.count
        if let color = self.colorStrs?[pagerView.currentIndex], !color.isEmpty {
            UIView.animate(withDuration: 0.25, animations: {
                self.contentView.backgroundColor = UIColor(color)
            })
            NotificationCenter.default.post(name: NSNotification.Name.UIUpdate.bookMallColorChange, object: UIColor(color))
        }
    }
    
    
    override func layoutSubviews() {
        super.layoutSubviews()
        pagerView.interitemSpacing = 0
        pagerView.itemSize = CGSize(width: UIScreen.main.bounds.size.width - 16 * 2, height: bounds.height - 10)
        let path0 = UIBezierPath()
        let height: CGFloat = bounds.height
        let width = UIScreen.main.bounds.width
        path0.move(to: CGPoint(x: 0, y: height - 70))
        path0.addLine(to: CGPoint(x: 0, y: height))
        path0.addLine(to: CGPoint(x: width, y: height))
        path0.addLine(to: CGPoint(x: width, y: height - 70))
        path0.addQuadCurve(to: CGPoint(x: 0, y: height - 70), controlPoint: CGPoint(x: width * 0.5, y: height - 140))
        path0.close()
        
        let maskLayer = CAShapeLayer()
        maskLayer.frame = bgView.bounds
        maskLayer.path = path0.cgPath
        maskLayer.fillColor = UIColor.white.cgColor
        maskLayer.strokeColor = UIColor.white.cgColor
        maskLayer.lineWidth = 1
        bgView.layer.addSublayer(maskLayer)
    }
}

extension BookMallBannerCollectionViewCell: FSPagerViewDataSource {
    public func numberOfItems(in pagerView: FSPagerView) -> Int {
        return urls?.count ?? 0
    }
    
    public func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        guard let cell = pagerView.dequeueReusableCell(withReuseIdentifier: "BannerImageCollectionViewCell", at: index) as? BannerImageCollectionViewCell else {
            return FSPagerViewCell()
        }
        if let urls = urls, index < urls.count {
            cell.customImageView.kf.setImage(with: URL(string: urls[index]))
        }
        return cell
    }
}

extension BookMallBannerCollectionViewCell: FSPagerViewDelegate {
    func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
        pagerView.deselectItem(at: index, animated: true)
        pagerView.scrollToItem(at: index, animated: true)
        self.pageControl.currentPage = index
        self.didSelected?(index)
    }
    
    func pagerViewDidScroll(_ pagerView: FSPagerView) {
        guard self.pageControl.currentPage != pagerView.currentIndex else {
            return
        }
        self.pageControl.currentPage = pagerView.currentIndex
        if let color = self.colorStrs?[pagerView.currentIndex], !color.isEmpty {
            UIView.animate(withDuration: 0.25, animations: {
                 self.contentView.backgroundColor = UIColor(color)
            })
            NotificationCenter.default.post(name: NSNotification.Name.UIUpdate.bookMallColorChange, object: UIColor(color))
        }
    }
}
