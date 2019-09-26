//
//  PageContentView.swift
//  Arab
//
//  Created by lieon on 2018/9/11.
//  Copyright © 2018年lieon. All rights reserved.
//

import UIKit

protocol PageContentViewDelegate {
    func contentView(_ contentView: PageContentView) -> CGSize
}

private let cellID = "cell"
class PageContentView: UIView {
    
    var tapAction:((_ progress: Float, _ sourceIndex: Int, _ targetIndx: Int) -> Void)?
    fileprivate var childVCs: [UIViewController] {
        didSet {
            setupUI()
        }
    }
    fileprivate var startOffsetX: CGFloat = 0.0
    fileprivate var  isForbiden: Bool = false
    fileprivate weak var parentVC: UIViewController?
    lazy var collectView: UICollectionView = { [weak self] in
        let layout = UICollectionViewFlowLayout()
        layout.itemSize = (self?.bounds.size)!
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.scrollDirection = .horizontal
        let collectionView = UICollectionView(frame: (self?.bounds)!, collectionViewLayout: layout)
        collectionView.isPagingEnabled = true
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.bounces = false
        collectionView.dataSource = self
        collectionView.delegate = self
        return collectionView
        }()
    
    init(frame: CGRect, childVCs: [UIViewController], parentVC: UIViewController?) {
        self.childVCs = childVCs
        self.parentVC = parentVC
        super.init(frame: frame)
        collectView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: cellID)
        collectView.backgroundColor = UIColor.white
        addSubview(collectView)
        setupUI()
    }
    
    
//    func resizeContent() {
//        collectView.isScrollEnabled = false
//        var size = CGSize.zero
//        if let vc = self.childVCs.first as? PageContentViewDelegate {
//            size = vc.contentView(self)
//        }
//        if let vc = self.childVCs.last as? PageContentViewDelegate {
//            size = vc.contentView(self)
//        }
//        
//        collectView.frame = CGRect(origin: CGPoint.zero, size: size)
//        collectView.reloadData()
//    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        collectView.frame = CGRect(origin: CGPoint.zero, size: bounds.size)
        collectView.reloadData()
    }
    
    convenience init(_ childVCs: [UIViewController], parentVC: UIViewController?) {
        self.init(frame: UIScreen.main.bounds, childVCs: childVCs, parentVC: parentVC)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
}

extension PageContentView {
    fileprivate  func setupUI() {
        self.childVCs.forEach {
            parentVC?.addChild($0)
        }
    }
    
    func reset(_ childViewControllers: [UIViewController]) {
       
        if self.parentVC != nil {
            self.childVCs.forEach {
                $0.view.removeFromSuperview()
                $0.removeFromParent()
            }
        }
        let children = self.parentVC?.children
        children?.forEach{
            $0.removeFromParent()
        }
        self.childVCs = childViewControllers
        self.childVCs.forEach {
            parentVC?.addChild($0)
        }
        collectView.reloadData()
        collectView.scrollToItem(at: IndexPath(item: 0, section: 0), at: UICollectionView.ScrollPosition.centeredHorizontally, animated: false)
    }
}

extension PageContentView {
    func selected(index: Int) {
        isForbiden = true
        let offsetX = CGFloat(index) * bounds.width
        let preoffset = collectView.contentOffset
        collectView.setContentOffset(CGPoint(x: offsetX, y: preoffset.y), animated: true)
    }
}

extension PageContentView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return childVCs.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellID, for: indexPath)
        cell.contentView.subviews.forEach {
            $0.removeFromSuperview()
        }

        let childVC = childVCs[indexPath.item]
        childVC.view.frame = bounds
        cell.contentView.addSubview(childVC.view)
        return cell
    }
}

extension PageContentView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.bounds.size
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        isForbiden = false
        startOffsetX = scrollView.contentOffset.x
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if isForbiden {
            return
        }
        let currentOffsetX = scrollView.contentOffset.x
        var targetIndex: Int = 0
        var sourceIndex: Int = 0
        var progress: CGFloat = 0.0
        let scrollViewWidth = scrollView.frame.width
        if currentOffsetX > startOffsetX {
            progress = currentOffsetX / scrollViewWidth - floor(currentOffsetX / scrollViewWidth)
            sourceIndex = Int(currentOffsetX / scrollViewWidth)
            targetIndex = sourceIndex + 1
            if targetIndex >= childVCs.count {
                targetIndex = childVCs.count - 1
            }
            if currentOffsetX - startOffsetX == scrollViewWidth {
                progress = 1
                targetIndex = sourceIndex
            }
        } else {
            progress = 1 - currentOffsetX/scrollViewWidth  + floor(currentOffsetX / scrollViewWidth)
            targetIndex = Int(currentOffsetX / scrollViewWidth)
            sourceIndex = targetIndex + 1
            if sourceIndex >= childVCs.count {
                sourceIndex = childVCs.count - 1
            }
        }
        
        pageDidChanged(Float(progress), sourceIndex, targetIndex)
    }
    
    @objc func pageDidChanged(_ progress: Float, _ sourceIndex: Int, _ targetIndx: Int) {
        if let block = tapAction {
            block(progress, sourceIndex, targetIndx)
        }
    }
}
