//
//  SmallReaderTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/8.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import YYText

class SmallReaderTableViewCell: UITableViewCell {
    fileprivate lazy var contentTextLabel: YYTextView = {
        let textLabel = YYTextView()
        textLabel.backgroundColor = .clear
        textLabel.textVerticalAlignment = .top
        textLabel.textContainerInset = .zero
        textLabel.isScrollEnabled = false
        return textLabel
    }()
    
    /// 内容
    var content: NSMutableAttributedString? {
        didSet{
            if content != nil && (content!.length > 0) {
                frameRef = DZMReadParser.GetReadFrameRef(attrString: content!, rect: GetReadViewFrame())
            }
        }
    }
    
    /// CTFrame
    var frameRef:CTFrame? {
        didSet{
            if frameRef != nil { setNeedsDisplay() }
        }
    }
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        addSubview(contentTextLabel)
        contentView.backgroundColor = .clear
        backgroundColor = .clear
        contentTextLabel.snp.makeConstraints {
            $0.top.bottom.equalTo(0)
            $0.left.equalTo(16)
            $0.right.equalTo(-16)
        }
        selectionStyle = .none
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    
    func config(_ atttString: NSAttributedString?) {
        contentTextLabel.attributedText = atttString
        self.content = NSMutableAttributedString(attributedString: atttString!)
    }
    
    
    override func draw(_ rect: CGRect) {
        
        //        if (frameRef == nil) {return}
        //
        //        let ctx = UIGraphicsGetCurrentContext()
        //
        //        ctx?.textMatrix = CGAffineTransform.identity
        //
        //        ctx?.translateBy(x: 0, y: bounds.size.height)
        //
        //        ctx?.scaleBy(x: 1.0, y: -1.0)
        //
        //        let path = CGMutablePath()
        //
        //        DZMColor_253_85_103.withAlphaComponent(0.5).setFill()
        //        ctx?.addPath(path)
        //        ctx?.fillPath()
        //        CTFrameDraw(frameRef!, ctx!)
    }
    

}
