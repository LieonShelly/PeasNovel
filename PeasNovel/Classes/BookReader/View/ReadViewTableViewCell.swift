//
//  ReadViewTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/1.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import YYText
import Foundation
import CoreText
import PKHUD
import RxSwift
import RxCocoa


class ReadViewTableViewCell: UITableViewCell {
    var bag = DisposeBag()
    fileprivate let cursorViewOffset: CGFloat = -20
    fileprivate lazy var contentTextLabel: YYLabel = {
        let textLabel = YYLabel()
        textLabel.backgroundColor = .clear
        textLabel.textVerticalAlignment = .top
        textLabel.textContainerInset = .zero
        textLabel.numberOfLines = 0
        textLabel.textAlignment = NSTextAlignment.justified
        return textLabel
    }()
    var leftCursorView: ReadLongPressCursorView!
    var rightCursorView: ReadLongPressCursorView!
    var currentHightlighText: String?
    var pageModel: ChapterPageModel?
    var content: NSMutableAttributedString? {
        didSet{
            if content != nil && (content!.length > 0) {
                frameRef = DZMReadParser.GetReadFrameRef(attrString: content!, rect: GetReadViewFrame())
            }
        }
    }
    
    var frameRef:CTFrame? {
        didSet{
            if frameRef != nil { setNeedsDisplay() }
        }
    }
    fileprivate var isCursorLorR:Bool = true
    fileprivate var isTouchCursor:Bool = false
    fileprivate var selectedRange: NSRange?
    fileprivate var selectedRects: [CGRect] = []
    private(set) var isOpenDrag:Bool = false
    fileprivate var tap = UITapGestureRecognizer()
    fileprivate var longpressGes = UILongPressGestureRecognizer()
    fileprivate var cursorPanGes = UIPanGestureRecognizer()
    fileprivate var rightPanGes = UIPanGestureRecognizer()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        contentView.addSubview(contentTextLabel)
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        contentTextLabel.snp.makeConstraints { $0.edges.equalTo(0)}
        selectionStyle = .none
        
        contentTextLabel.addGestureRecognizer(longpressGes)
        contentTextLabel.isUserInteractionEnabled = true
        longpressGes.minimumPressDuration = 0.5
        longpressGes.addTarget(self, action: #selector(self.longpressAction))

        tap.isEnabled = false
        contentTextLabel.addGestureRecognizer(tap)
        tap.addTarget(self, action: #selector(self.tapAction))
        
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func config(_ pageModel: ChapterPageModel?,
                attchModel: AttachmentModel?,
                appendAttchViewHandler: (() -> UIView?)?) {
        
        if let atttString = pageModel?.pangeContent {
            self.pageModel = pageModel
            contentTextLabel.attributedText = atttString
            self.content = NSMutableAttributedString(attributedString: atttString)
            for subView in contentView.subviews {
                if subView.tag == 100 {
                    subView.removeFromSuperview()
                }
            }
            if let ctframe = frameRef {
                DispatchQueue.main.async {
                    self.attachImageWithFrame(ctframe, attchModel: attchModel)
                    if let attchViewHandler = appendAttchViewHandler,
                        let attchView = attchViewHandler() {
                        self.appendAttachImage(ctframe, attchView: attchView)
                    }
                }
            }
            addNotification()
        }
    }
    
    var currentLocation: Int = 0
    var selectedTextIndex: Int = 0
    func addNotification() {
        NotificationCenter.default.rx.notification(Notification.Name.Book.ListenBook.statusCallback)
            .map { $0.object as? SpeechManager.Stattus }
            .unwrap()
            .subscribe(onNext: {[weak self] (result) in
                guard let weakSelf = self else {
                    return
                }
                switch result {
                case .playBegin(result: nil, currentPageModel: let outputModel, currentText: let currentText ):
                    if let currentText = currentText,
                        let range = weakSelf.pageModel?.pangeContent?.string.range(currentText.trimmingCharacters(in: .whitespacesAndNewlines)),
                        outputModel?.page == weakSelf.pageModel?.page {
                            weakSelf.selectedRange = range
                            weakSelf.selectedRects = DZMReadAuxiliary.GetRangeRects(range: range, frameRef: weakSelf.frameRef)
                            DispatchQueue.main.async {
                                weakSelf.setNeedsDisplay()
                            }
                    }
                case .stop:
                     weakSelf.selectedRange = nil
                     weakSelf.selectedRects = []
                    DispatchQueue.main.async {
                        weakSelf.setNeedsDisplay()
                    }
                default:
                    break
                }
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(UIApplication.willEnterForegroundNotification)
            .mapToVoid()
            .subscribe(onNext: {[weak self] (_) in
                guard let weakSelf = self, weakSelf.selectedRange != nil else {
                    return
                }
                weakSelf.reset()
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx
            .notification(NSNotification.Name.Advertise.rewardVideoAdWillDismiss)
            .map { $0.object as? LocalAdvertise }
            .unwrap()
            .filter { $0.ad_position == AdPosition.readerRewardVideoAd.rawValue }
            .mapToVoid()
            .subscribe(onNext: {[weak self] () in
                guard let weakSelf = self else {
                    return
                }
                for subView in weakSelf.contentView.subviews {
                    if subView.tag == 100 {
                        subView.removeFromSuperview()
                    }
                }
            })
            .disposed(by: bag)
    }
    
    func attachImageWithFrame(_ ctfrmae: CTFrame, attchModel: AttachmentModel?) {
        guard let attchModel = attchModel,
            let pageModel = self.pageModel,
            let pageStartLocation = pageModel.range?.location,
            pageModel.page == attchModel.page else {
            return
        }
        let result = ReaderAdService.shouldShowChapterpageAd()
        let record = result.config
        guard  let config = record, result.isShow else {
            return 
        }
        let location = attchModel.location - pageStartLocation
        let rects = DZMReadAuxiliary.GetRangeRects(range: NSRange(location: location, length: 1), frameRef: ctfrmae)
        if let rect = rects.first {
            let attchmentView = ReaderPageAdView(ReaderPageAdViewModel(config))
            attchmentView.frame = CGRect(x: 0, y: bounds.height - rect.height -  rect.origin.y, width: bounds.width, height: rect.height)
            attchmentView.tag = 100
            contentView.insertSubview(attchmentView, aboveSubview: contentTextLabel)
            contentView.bringSubviewToFront(attchmentView)
        }
    }
    
    fileprivate func appendAttachImage(_ ctfrmae: CTFrame, attchView: UIView) {
       
        guard let pageModel = self.pageModel,
             let range = pageModel.pangeContent?.yy_rangeOfAll() else {
                return
        }
        guard let textRect = DZMReadAuxiliary.GetRangeRects(range: range, frameRef: ctfrmae).last else {
            return
        }
        let attchViewY = bounds.height - textRect.origin.y + 10
        let attchViewHeight: CGFloat = attchView.size.height
        if attchViewY + attchViewHeight <=  GetReadViewFrame().height {
            attchView.frame.origin = CGPoint(x: 0, y: attchViewY)
            attchView.tag = 100
            contentView.insertSubview(attchView, aboveSubview: contentTextLabel)
            contentView.bringSubviewToFront(attchView)
        }
    }
    
    override func draw(_ rect: CGRect) {
        if (frameRef == nil) {
            return
        }
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.textMatrix = CGAffineTransform.identity
        ctx?.translateBy(x: 0, y: bounds.size.height)
        ctx?.scaleBy(x: 1.0, y: -1.0)
        if selectedRange != nil && !selectedRects.isEmpty {
            let path = CGMutablePath()
            UIColor.theme.withAlphaComponent(0.5).setFill()
            path.addRects(selectedRects)
            ctx?.addPath(path)
            ctx?.fillPath()
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(clickCopy) {
            return true
        }
        return false
    }
}


extension ReadViewTableViewCell {
    
    @objc fileprivate func tapAction() {
        reset()
    }
    
    @objc fileprivate func longpressAction(_ ges: UILongPressGestureRecognizer) {
        guard let frameRef = frameRef else {
            return
        }
        let point = ges.location(in: contentTextLabel)
        switch ges.state {
            case .began:
                NotificationCenter.default.post(name: NSNotification.Name.Book.readerViewHandling, object: true)
                break
            case .changed:
                break
            case .ended:
                selectedRange = DZMReadAuxiliary.GetTouchLineRange(point: point, frameRef: frameRef)
                selectedRects = DZMReadAuxiliary.GetRangeRects(range: selectedRange!, frameRef: frameRef)
                if !selectedRects.isEmpty {
                    selectedRects[0].origin.x += 20
                    selectedRects[0].size.width -= 40
                }
                setNeedsDisplay()
                showMenu(isShow: true)
                cursor(isShow: true)
                if !selectedRects.isEmpty {
                    isOpenDrag = true
                    tap.isEnabled = true
                    longpressGes.isEnabled = false
                }
                break
            default:
                break
        }
    }
    
    private func reset() {
        tap.isEnabled = false
        isOpenDrag = false
        longpressGes.isEnabled = true
        showMenu(isShow: false)
        selectedRange = nil
        selectedRects.removeAll()
        cursor(isShow: false)
        setNeedsDisplay()
        NotificationCenter.default.post(name: NSNotification.Name.Book.readerViewHandling, object: false)
    }
    
    private func showMenu(isShow: Bool) {
        if isShow {
            if !selectedRects.isEmpty {
                let rect = DZMReadAuxiliary.GetMenuRect(rects: selectedRects, viewFrame: bounds)
                becomeFirstResponder()
                let menuController = UIMenuController.shared
                let copy = UIMenuItem(title: "错别字反馈", action: #selector(clickCopy))
                menuController.menuItems = [copy]
                menuController.setTargetRect(rect, in: self)
                DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 1) {
                    menuController.setMenuVisible(true, animated: true)
                }
            }
        } else {
            UIMenuController.shared.setMenuVisible(false, animated: true)
        }
    }
    
    
    @objc private func clickCopy() {
        if let selectedRange = selectedRange, let content = pageModel?.pangeContent?.string {
            let string = content.substring(selectedRange)
            let uipasteboard = UIPasteboard.general
            uipasteboard.string = string
            NotificationCenter.default.post(name: NSNotification.Name.Book.readerViewClickReportError, object: nil)
            reset()
        }
    }
    
    private func cursor(isShow: Bool) {
        if isShow {
            if !selectedRects.isEmpty, leftCursorView == nil {
                leftCursorView = ReadLongPressCursorView()
                leftCursorView.isTorB = true
                contentView.addSubview(leftCursorView)
                rightCursorView = ReadLongPressCursorView()
                rightCursorView.isTorB = false
                contentView.addSubview(rightCursorView)
                updateCursorViewFrame()
                contentView.addGestureRecognizer(cursorPanGes)
                cursorPanGes.addTarget(self, action: #selector(self.cursorViewPanAction(_:)))
            }
        } else {
            if leftCursorView != nil {
                leftCursorView.removeFromSuperview()
                leftCursorView = nil
                contentView.removeGestureRecognizer(cursorPanGes)
                rightCursorView.removeFromSuperview()
                rightCursorView = nil
                
            }
        }
    }

    private func updateCursorViewFrame() {
        if !selectedRects.isEmpty, leftCursorView != nil {
            let cursorViewW: CGFloat = 10
            let cursorViewSpaceW: CGFloat = cursorViewW / 4
            let cursorViewSpcaeH: CGFloat = cursorViewW / 1.1
            let firt = selectedRects.first!
            let last = selectedRects.last!
            leftCursorView.frame = CGRect(x: firt.minX - cursorViewW + cursorViewSpaceW,
                                          y: bounds.height - firt.minY - firt.height - cursorViewSpcaeH,
                                          width: cursorViewW,
                                          height: firt.height + cursorViewSpcaeH)
            
            rightCursorView.frame = CGRect(x: last.maxX - cursorViewSpaceW,
                                          y: bounds.height - last.minY - last.height,
                                          width: cursorViewW,
                                          height: last.height + cursorViewSpcaeH)
        }
    }
    

    fileprivate func drag(status: UIGestureRecognizer.State, point:CGPoint, windowPoint:CGPoint) {
        
        if status == .began {
            showMenu(isShow: false)
            if leftCursorView.frame.insetBy(dx: cursorViewOffset, dy: cursorViewOffset).contains(point) {
                isCursorLorR = true
                isTouchCursor = true
            }else if rightCursorView.frame.insetBy(dx: cursorViewOffset, dy: cursorViewOffset).contains(point) {
                isCursorLorR = false
                isTouchCursor = true
            }else{
                isTouchCursor = false
            }
        }else if status == .changed {
            if isTouchCursor && selectedRange != nil {
                let location = DZMReadAuxiliary.GetTouchLocation(point: point, frameRef: frameRef)
                if location == -1 {
                    return
                }
                updateSelectRange(location: location)
                selectedRects = DZMReadAuxiliary.GetRangeRects(range: selectedRange!, frameRef: frameRef, content: pageModel!.pangeContent!.string)
                updateCursorViewFrame()
            }
        } else {
             showMenu(isShow: true)
            isTouchCursor = false
        }
        setNeedsDisplay()
    }
    
    
    private func updateSelectRange(location: Int) {
        let LLocation = selectedRange!.location
        let RLocation = selectedRange!.location + selectedRange!.length
        if isCursorLorR {
            if location < RLocation {
                if location > LLocation {
                    selectedRange!.length -= location - LLocation
                    selectedRange!.location = location
                }else if location < LLocation {
                    selectedRange!.length += LLocation - location
                    selectedRange!.location = location
                }
            } else {
                isCursorLorR = false
                var length = location - RLocation
                let tempLength = (length == 0 ? 1 : 0)
                length = (length == 0 ? 1 : length)
                selectedRange!.length = length
                selectedRange!.location = RLocation - tempLength
                updateSelectRange(location: location)
            }
            
        }else{ // 右边
            if location > LLocation {
                if location > RLocation {
                    selectedRange!.length += location - RLocation
                } else if location < RLocation {
                    selectedRange!.length -= RLocation - location
                }
             } else {
                isCursorLorR = true
                let tempLength = LLocation - location
                let length = (tempLength == 0 ? 1 : tempLength)
                selectedRange!.length = length
                selectedRange!.location = LLocation - tempLength
                updateSelectRange(location: location)
            }
        }
    }
    

    
    @objc fileprivate func cursorViewPanAction(_ ges: UIPanGestureRecognizer) {
        if isOpenDrag {
            let point = ges.location(in: self)
            let windowPoint = ges.location(in: self.window)
            drag(status: ges.state, point: point, windowPoint: windowPoint)
        }
    }
    
}

extension ReadViewTableViewCell {
  
}
