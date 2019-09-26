//
//  PageTitleView.swift
//  Arab
//
//  Created by lieon on 2018/9/11.
//  Copyright © 2018年lieon. All rights reserved.
//

import Foundation
import UIKit

private let scrollowLineH: CGFloat = 3.0
private let zoomScale: CGFloat = 1.2

class  PageTitleView: UIView {
    
    private var normalColor: (CGFloat, CGFloat, CGFloat) = (255, 255, 255)
    private var selectColor: (CGFloat, CGFloat, CGFloat) = (255, 255, 255)
    var isTapEnabled = true
    var titleTapAction: ((_ index: Int) -> Void)?
    var currentIndex: Int = 0 {
        didSet {
            self.scrollRectToVisibleCentered(on: self.titleLabels[currentIndex].frame, isAnimate: true)
        }
    }
    var labelCountPerPage: Int = 2
    var titleSpace: Float = 0.0
    fileprivate var labelWidth: CGFloat = 0.0
    fileprivate var titles: [String] = []
    fileprivate lazy var colorLineWidths: [CGFloat] = [CGFloat]()
    var titleLabels: [UILabel] = [UILabel]()
    var didSelected: ((UILabel, UILabel) -> Void)?
    fileprivate var fontSize: CGFloat = 18
    var normalFont: UIFont = UIFont.boldSystemFont(ofSize: 18)
    var selecetFont: UIFont = UIFont.boldSystemFont(ofSize: 21)
    fileprivate lazy var scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        sv.scrollsToTop = false
        sv.bounces = true
        return sv
    }()
    fileprivate lazy var colorLine: UIView = {
        let colorLine = UIView()
        colorLine.backgroundColor = UIColor(red: selectColor.0 / 255.0, green: selectColor.1 / 255.0, blue: selectColor.2 / 255.0, alpha: 1)
        return colorLine
    }()
    
    fileprivate lazy var scrollLine: UIView = {
        let scrollLine = UIView()
        scrollLine.backgroundColor = self.backgroundColor
        return scrollLine
    }()
    
    init(frame: CGRect, titles: [String]? = nil, callback: (([UILabel],PageTitleView) -> Void)? = nil) {
        self.textColor = UIColor.white
        super.init(frame: frame)
        if let titles = titles {
            self.titles = titles
            setupUI()
            if let callback = callback {
                callback(titleLabels, self)
                guard let firtLabel = titleLabels.first else { return  }
                firtLabel.textColor = UIColor(red: selectColor.0 / 255.0, green: selectColor.1 / 255.0, blue: selectColor.2 / 255.0, alpha: 1)
                scrollLine.frame = CGRect(x: firtLabel.frame.origin.x, y: frame.height - scrollowLineH, width: firtLabel.frame.width, height: scrollowLineH)
                caculateColorLineWidth()
            }
            
        }
    }
    /// 设置标题组
    func setTitles(_ titles: [String]) {
        self.titles.removeAll(keepingCapacity: false)
        titleLabels.removeAll(keepingCapacity: false)
        self.titles = titles
        subviews.forEach { $0.removeFromSuperview() }
        setupUI()
        currentIndex = 0
    }
    /// 选中字体颜色
    override var tintColor: UIColor! {
        didSet{
            colorLine.backgroundColor = tintColor
            let color = tintColor.cgColor
            let numComponents = color.components
            selectColor = (numComponents![0]*255, numComponents![1]*255, numComponents![2]*255)
            if currentIndex >= titleLabels.count {
                return
            }
            let label = titleLabels[currentIndex]
            label.textColor = tintColor
        }
    }
    /// 字体颜色
    var textColor: UIColor {
        didSet {
            let color = textColor.cgColor
            let numComponents = color.components
            normalColor = (numComponents![0]*255, numComponents![1]*255, numComponents![2]*255)
            for (idx, label) in titleLabels.enumerated() {
                if idx == currentIndex { continue }
                label.textColor = textColor
            }
        }
    }
    
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}

extension  PageTitleView {
    func setTitle(progress: Float, sourceIndex: Int, targetIndex: Int) {
        if sourceIndex >= titleLabels.count || targetIndex >= titleLabels.count || targetIndex < 0 || sourceIndex < 0 {
            return
        }
        let souceLabel = titleLabels[sourceIndex]
        let targetLabel = titleLabels[targetIndex]
        let offsetX = targetLabel.frame.origin.x  - souceLabel.frame.origin.x
        let totalX = offsetX * CGFloat(progress)
        scrollLine.frame.origin.x = souceLabel.frame.origin.x + totalX
        let colorDelta = (selectColor.0 - normalColor.0, selectColor.1 - normalColor.1, selectColor.2 - normalColor.2)
        souceLabel.textColor = UIColor(red: (selectColor.0 - colorDelta.0 * CGFloat(progress)) / 255.0, green: (selectColor.1 - colorDelta.1 * CGFloat(progress)) / 255.0, blue: (selectColor.2 - colorDelta.2 * CGFloat(progress)) / 255.0, alpha: 1)
        targetLabel.textColor = UIColor(red: (normalColor.0 + colorDelta.0 * CGFloat(progress)) / 255.0, green: (normalColor.1 + colorDelta.1 * CGFloat(progress)) / 255.0, blue: (normalColor.2 + colorDelta.2 * CGFloat(progress)) / 255.0, alpha: 1)
        currentIndex = targetIndex
        if progress > 0.9 {
             didSelected?(souceLabel, targetLabel)
        }
    
    }
}

extension  PageTitleView {
    
    func resize(_ labelCountPerPage: Int) {
        self.labelCountPerPage = labelCountPerPage
        scrollView.contentSize = CGSize(width: CGFloat(titles.count) * frame.width / CGFloat(labelCountPerPage), height: bounds.height)
        let labelW: CGFloat = frame.width / CGFloat(labelCountPerPage)
        labelWidth = labelW
        let labelH: CGFloat = frame.height
        let labelY: CGFloat = 0.0
        for (index, label) in titleLabels.enumerated() {
            let labelX = labelW * CGFloat(index)
            label.frame = CGRect(x: labelX, y: labelY, width: labelW, height: labelH)
        }
    }
    
    fileprivate  func setupUI() {
        setupScrollView()
        setupTtitleLabels()
        setupBottomLineAndScrollLine()
        caculateColorLineWidth()
    }
    
    fileprivate func setupScrollView() {
        addSubview(scrollView)
        colorLine.isHidden = false
        scrollView.frame = bounds
        
        if titleSpace > 0 {
            let initWidth = CGFloat(titles.count)*CGFloat(titleSpace)
            /// 左右距离屏幕宽度+titleSpace
            let titleWidth = CGFloat(titleSpace) + titles.reduce(initWidth, { $0 + $1.width(fontSize: fontSize)})
            if (titleWidth - CGFloat(titleSpace)/2) < UIScreen.main.bounds.width { // 如果标题总长度小于屏幕宽，铺满
                titleSpace = 0
                labelCountPerPage = titles.count
            }else{
                scrollView.contentSize = CGSize(width: titleWidth, height: bounds.height)
            }
            
        }else{
            scrollView.contentSize = CGSize(width: CGFloat(titles.count) * frame.width / CGFloat(labelCountPerPage), height: bounds.height)
        }
    }
    
    

    fileprivate  func setupTtitleLabels() {
        let labelW: CGFloat = frame.width / CGFloat(labelCountPerPage)
        var preOriginX: CGFloat = CGFloat(titleSpace)/2
        labelWidth = labelW
        let labelH: CGFloat = frame.height
        let labelY: CGFloat = 0.0
        for (index, title) in titles.enumerated() {
            let label = UILabel()
            label.textColor = UIColor(red: normalColor.0 / 255.0, green: normalColor.1 / 255.0, blue: normalColor.2 / 255.0, alpha: 1)
            label.tag = index
            label.textAlignment = .center
            label.text = title
            label.font = UIFont.systemFont(ofSize: 18)
            fontSize = 18
            
            
            if titleSpace > 0 {
                let titleWidth = title.width(fontSize: fontSize)
                label.frame = CGRect(x: preOriginX,
                                     y: labelY,
                                     width: titleWidth + CGFloat(titleSpace),
                                     height: labelH)
            }else{
                label.frame = CGRect(x: preOriginX,
                                     y: labelY,
                                     width: labelW,
                                     height: labelH)
            }
            preOriginX = label.frame.maxX
            scrollView.addSubview(label)
            titleLabels.append(label)
            label.isUserInteractionEnabled = true
            let tap = UITapGestureRecognizer(target: self, action: #selector(titleLabelClilck(tap:)))
            label.addGestureRecognizer(tap)
        }
    }
    
    fileprivate  func setupBottomLineAndScrollLine() {
        guard let firtLabel = titleLabels.first else { return  }
        firtLabel.textColor = UIColor(red: selectColor.0 / 255.0, green: selectColor.1 / 255.0, blue: selectColor.2 / 255.0, alpha: 1)
        scrollView.addSubview(scrollLine)
        scrollLine.frame = CGRect(x: firtLabel.frame.origin.x, y: frame.height - scrollowLineH, width: firtLabel.frame.width, height: scrollowLineH)
        scrollLine.addSubview(colorLine)
    }
    
    fileprivate func caculateColorLineWidth() {
        titles.forEach { text in
            let width = caculatetextWidth(text: text, fontSize: fontSize)
            self.colorLineWidths.append(width)
        }
//        if let colorLineWidth = colorLineWidths.first {
//            colorLine.frame = CGRect(x: scrollLine.bounds.width * 0.5 - colorLineWidth * 0.5, y: 0, width: colorLineWidth, height: scrollowLineH)
//            colorLine.layer.cornerRadius = scrollowLineH * 0.5
//            colorLine.layer.masksToBounds = true
//        }
        let colorLineWidth: CGFloat = 18
            colorLine.frame = CGRect(x: scrollLine.bounds.width * 0.5 - colorLineWidth * 0.5, y: 0, width: colorLineWidth, height: scrollowLineH)
            colorLine.layer.cornerRadius = scrollowLineH * 0.5
            colorLine.layer.masksToBounds = true
        
    }
    
    fileprivate func scrollRectToVisibleCentered(on visibleRect: CGRect, isAnimate: Bool) {
        let centeredRect = CGRect(x: visibleRect.origin.x + visibleRect.size.width / 2.0 - self.scrollView.frame.size.width / 2.0, y: visibleRect.origin.y + visibleRect.size.height / 2.0 - self.scrollView.frame.size.height / 2.0, width: self.scrollView.frame.size.width, height: self.scrollView.frame.size.height)
        self.scrollView.scrollRectToVisible(centeredRect, animated: isAnimate)
    }
    
    @objc func titleLabelClilck(tap: UITapGestureRecognizer) {
        if !isTapEnabled { return }
        guard let selectedLabel = tap.view as? UILabel else { return  }
        let oldLabel = titleLabels[currentIndex]
        oldLabel.textColor = UIColor(red: normalColor.0 / 255.0, green: normalColor.1 / 255.0, blue: normalColor.2 / 255.0, alpha: 1)
        selectedLabel.textColor = UIColor(red: selectColor.0 / 255.0, green: selectColor.1 / 255.0, blue: selectColor.2 / 255.0, alpha: 1)
        currentIndex = selectedLabel.tag
        didSelected?(oldLabel, selectedLabel)
        UIView.animate(withDuration: 0.1) {
            self.scrollLine.center.x = selectedLabel.center.x
            let colorLineWidth: CGFloat = 18 //self.colorLineWidths[selectedLabel.tag]
            self.colorLine.frame = CGRect(x: self.scrollLine.bounds.width * 0.5 - colorLineWidth * 0.5, y: 0, width: colorLineWidth, height: scrollowLineH)
        }
        if let block = titleTapAction {
            block(selectedLabel.tag)
        }
    }
    
    private func caculatetextWidth(text: String, fontSize: CGFloat) -> CGFloat {
        let nsstr = NSString(string: text)
        let maxSize = CGSize(width: frame.width / CGFloat(labelCountPerPage), height: 40)
        let size = nsstr.boundingRect(with: maxSize, options: .usesDeviceMetrics, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: fontSize)], context: nil)
        return size.width
    }
}
