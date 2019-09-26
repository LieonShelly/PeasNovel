//
//  DZMReadParser.swift
//  ReaderKit
//
//  Created by lieon on 2017/5/12.
//  Copyright © 2018年lieon. All rights reserved.
//

import UIKit
import CoreText
import SwiftSoup
import YYText

open class DZMReadParser: NSObject {
    /// 防止多次进入
    static var isInProgress = false
    /// 获得阅读模型，如果需要跳转章节，传入相应的章节contentId
    open class func getBookDetail(bookID: String, contentId: String?, completion:@escaping (DZMReadModel) -> Void) {
        if isInProgress {
            return
        }
        isInProgress = true
        // 需要跳转章节
        if let contentId = contentId, !contentId.isEmpty {
            // 是否存在章节缓存
            if DZMReadChapterModel.IsExistReadChapterModel(bookID: bookID, chapterID: contentId) {
                let model = DZMReadModel.readModel(bookID: bookID)
                if (model.readRecordModel.readChapterModel?.order == 1 && model.readRecordModel.page == -1) || model.readRecordModel.readChapterModel?.order == 0 { /// 如果是第一页或者本来就是扉页，则跳转到扉页
                     model.modifyReadRecordModel(chapterID: ReaderSpecialChapterValue.firstPageValue, isSave: true)
                } else {
                      model.modifyReadRecordModel(chapterID: contentId, isSave: true)
                }
              
                completion(model)
                isInProgress = false
            }else{
                ReaderController.cache(bookID, contentId: contentId) { res in
                    let model = DZMReadModel.readModel(bookID: bookID)
                    if (model.readRecordModel.readChapterModel?.order == 1 && model.readRecordModel.page == -1) || model.readRecordModel.readChapterModel?.order == 0 { /// 如果是第一页或者本来就是扉页，则跳转到扉页
                        model.modifyReadRecordModel(chapterID: ReaderSpecialChapterValue.firstPageValue, isSave: true)
                    } else {
                        model.modifyReadRecordModel(chapterID: contentId, isSave: true)
                    }
                    completion(model)
                    isInProgress = false
                }
            }
        }else if DZMReadModel.IsExistReadModel(bookID: bookID) { // 不需要跳转章节，存在书籍缓存
            let model = DZMReadModel.readModel(bookID: bookID)
            if (model.readRecordModel.readChapterModel?.order == 1 && model.readRecordModel.page == -1) || model.readRecordModel.readChapterModel?.order == 0 { /// 如果是第一页或者本来就是扉页，则跳转到扉页
                model.modifyReadRecordModel(chapterID: ReaderSpecialChapterValue.firstPageValue, isSave: true)
            }
            completion(model)
            isInProgress = false
        }else{  // 不存在书籍缓存，不需要跳转章节
            ReaderController.cache(bookID, contentId: contentId) { res in
                let model = DZMReadModel.readModel(bookID: bookID)
                if (model.readRecordModel.readChapterModel?.order == 1 && model.readRecordModel.page == -1)  || model.readRecordModel.readChapterModel?.order == 0 { /// 如果是第一页或者本来就是扉页，则跳转到扉页
                    model.modifyReadRecordModel(chapterID: ReaderSpecialChapterValue.firstPageValue, isSave: true)
                }
                completion(model)
                isInProgress = false
            }
        }
    }
    
    
    // MARK: -- 解析Context
    private class func ParserContent(bookID:String, content:String) ->[DZMReadChapterListModel] {
        
        // 章节列表数组
        var readChapterListModels:[DZMReadChapterListModel] = []
        
        // 正则
        let parten = "第[0-9一二三四五六七八九十百千]*[章回].*"
        
        // 排版
        let content = ContentTypesetting(content: content)
        
        // 搜索
        var results:[NSTextCheckingResult] = []
        
        do{
            let regularExpression:NSRegularExpression = try NSRegularExpression(pattern: parten, options: .caseInsensitive)
            
            results = regularExpression.matches(in: content, options: .reportCompletion, range: NSRange(location: 0, length: content.length))
            
        }catch{
            
            return readChapterListModels
        }
        
        // 解析搜索结果
        if !results.isEmpty {
            
            // 记录最后一个Range
            var lastRange = NSMakeRange(0, 0)
            
            // 数量
            let count = results.count
            
            // 记录 上一章 模型
            var lastReadChapterModel:DZMReadChapterModel?
            
            // 有前言
            var isPreface:Bool = true
            
            // 便利
            for i in 0...count {
                
                // 章节数量分析:
                // count + 1  = 搜索到的章节数量 + 最后一个章节,
                // 1 + count + 1  = 第一章前面的前言内容 + 搜索到的章节数量 + 最后一个章节
                print("总章节数:\(count + 1)  当前解析到:\(i + 1)")
                
                // range
                var range = NSMakeRange(0, 0)
                
                var location = 0
                
                if i < count {
                    
                    range = results[i].range
                    
                    location = range.location
                }
                
                // 创建章节内容模型
                let readChapterModel = DZMReadChapterModel()
                
                // 书ID
                readChapterModel.bookID = bookID
                
                // 章节ID
                readChapterModel.id = "\(i + NSNumber(value: isPreface).intValue)"
                
                // 优先级
                readChapterModel.priority = NSNumber(value: (i - NSNumber(value: !isPreface).intValue))
                
                if i == 0 { // 开始
                    
                    // 章节名
                    readChapterModel.name = "开始"
                    
                    // 内容
                    readChapterModel.content = content.substring(NSMakeRange(0, location))
                    
                    // 记录
                    lastRange = range
                    
                    // 说不定没有内容 则不需要添加到列表
                    if (readChapterModel.content ?? "").isEmpty {
                        
                        isPreface = false
                        
                        continue
                    }
                    
                }else if i == count { // 结尾
                    
                    // 章节名
                    readChapterModel.name = content.substring(lastRange)
                    
                    // 内容
                    readChapterModel.content = content.substring(NSMakeRange(lastRange.location, content.length - lastRange.location))
                    
                }else { // 中间章节
                    
                    // 章节名
                    readChapterModel.name = content.substring(lastRange)
                    
                    // 内容
                    readChapterModel.content = content.substring(NSMakeRange(lastRange.location, location - lastRange.location))
                }
                
                // 清空章节名,保留纯内容
                guard let content = readChapterModel.content, let name = readChapterModel.name else {
                    return readChapterListModels
                }
                readChapterModel.content = DZMParagraphHeaderSpace + content.replacingOccurrences(of: name, with: "").removeSpaceHeadAndTailPro
                
                // 分页
                readChapterModel.updateFont()
                
                // 添加章节列表模型
                readChapterListModels.append(GetReadChapterListModel(readChapterModel: readChapterModel))
                
                // 设置上下章ID
                readChapterModel.lastChapterId = lastReadChapterModel?.id
                lastReadChapterModel?.nextChapterId = readChapterModel.id
                
                // 保存
                readChapterModel.saveData()
                if let _ = lastReadChapterModel {
                      lastReadChapterModel!.saveData()
                }
                // 记录
                lastRange = range
                lastReadChapterModel = readChapterModel
            }
            
        }else{
            
            // 创建章节内容模型
            let readChapterModel = DZMReadChapterModel()
            
            // 书ID
            readChapterModel.bookID = bookID
            
            // 章节ID
            readChapterModel.id = "1"
            
            // 章节名
            readChapterModel.name = "开始"
            
            // 优先级
            readChapterModel.priority = NSNumber(value: 0)
            
            // 内容
            readChapterModel.content = DZMParagraphHeaderSpace + content.removeSpaceHeadAndTailPro
            
            // 分页
            readChapterModel.updateFont()
            
            // 添加章节列表模型
            readChapterListModels.append(GetReadChapterListModel(readChapterModel: readChapterModel))
            
            // 保存
            readChapterModel.saveData()
        }
        
        return readChapterListModels
    }
    
    /**
     通过阅读章节内容模型 获得 阅读章节列表模型
     
     - parameter readChapterModel: 阅读章节内容模型
     
     - returns: 阅读章节列表模型
     */
    private class func GetReadChapterListModel(readChapterModel:DZMReadChapterModel) ->DZMReadChapterListModel {
        
        let readChapterListModel = DZMReadChapterListModel()
        
        readChapterListModel.bookID = readChapterModel.bookID
        
        readChapterListModel.id = readChapterModel.id
        
        readChapterListModel.name = readChapterModel.name
        
        readChapterListModel.priority = readChapterModel.priority
        
        return readChapterListModel
    }
    
    // MARK: -- 内容分页
    
    /// 内容分页 (内容 + 显示范围)
    class func ParserPageRange(attrString:NSAttributedString, rect:CGRect) ->[NSRange] {
        
        var rangeArray:[NSRange] = []
        
        let frameSetter = CTFramesetterCreateWithAttributedString(attrString as CFAttributedString)
        
        let path = CGPath(rect: rect, transform: nil)
        
        var range = CFRangeMake(0, 0)
        
        var rangeOffset:NSInteger = 0
        
        repeat {
            
            let frame = CTFramesetterCreateFrame(frameSetter, CFRangeMake(rangeOffset, 0), path, nil)
            
            range = CTFrameGetVisibleStringRange(frame)
            
            rangeArray.append(NSMakeRange(rangeOffset, range.length))
            
            rangeOffset += range.length
            
        } while(range.location + range.length < attrString.length)
        

        
        return rangeArray
    }
    
    
    class func adSize() -> CGSize {
        let adHeight: CGFloat = 200
        let adWidth: CGFloat = UIScreen.main.bounds.width - 16 * 2
        return CGSize(width: adWidth, height: adHeight)
    }
    
   class func adSpace() -> NSAttributedString {
        struct RunStruct {
            let ascent: CGFloat
            let descent: CGFloat
            let width: CGFloat
        }
        let adHeight: CGFloat = adSize().height
        let adWidth: CGFloat = adSize().width
        let extenBuffer = UnsafeMutablePointer<RunStruct>.allocate(capacity: 1)
        extenBuffer.initialize(to: RunStruct(ascent: adHeight, descent: 0, width: adWidth))
        var callbacks = CTRunDelegateCallbacks(version: kCTRunDelegateVersion1, dealloc: { (pointer) in
            
        }, getAscent: { (pointer) -> CGFloat in
            let d = pointer.assumingMemoryBound(to: RunStruct.self)
            return d.pointee.ascent
        }, getDescent: { (pointer) -> CGFloat in
            let d = pointer.assumingMemoryBound(to: RunStruct.self)
            return d.pointee.descent
        }, getWidth: {  (pointer) -> CGFloat in
            let d = pointer.assumingMemoryBound(to: RunStruct.self)
            return d.pointee.width
        })
        let delegate = CTRunDelegateCreate(&callbacks, extenBuffer)
        let attrDictionaryDelegate = [(kCTRunDelegateAttributeName as NSAttributedString.Key): (delegate as Any)]
        let imageSpace = NSAttributedString(string: " ", attributes: attrDictionaryDelegate)
        return imageSpace
    }
    
    // MARK: -- 对内容进行整理排版
    
    /// 内容排版整理 - 去除多余回车空格，段头留空。
    class func ContentTypesetting(content:String) ->String {

        // 替换单换行
        var content = content.replacingOccurrences(of: "\r", with: "")
        
        // 替换换行 以及 多个换行 为 换行加空格
        content = content.replacingCharacters("\\s*\\n+\\s*", "\n" + DZMParagraphHeaderSpace)
        
        // 返回
        return content
    }
    
    // MARK: -- 解码URL
    
    /// 解码URL
    class func EncodeURL(_ url:URL) ->String {
        
        var content = ""
        
        // 检查URL是否有值
        if url.absoluteString.isEmpty {
            
            return content
        }
        
        // NSUTF8StringEncoding 解析
        content = EncodeURL(url, encoding: String.Encoding.utf8.rawValue)
        
        // 进制编码解析
        if content.isEmpty {
            
            content = EncodeURL(url, encoding: 0x80000632)
        }
        
        if content.isEmpty {
            
            content = EncodeURL(url, encoding: 0x80000631)
        }
        
        if content.isEmpty {
            
            content = ""
        }
        
        return content
    }
    
    /// 解析URL
    private class func EncodeURL(_ url:URL,encoding:UInt) ->String {
        
        do{
            return try NSString(contentsOf: url, encoding: encoding) as String
            
        }catch{}
        
        return ""
    }
    
    // MARK: -- 获得 FrameRef CTFrame
    
    /// 获得 CTFrame
    class func GetReadFrameRef(attrString:NSMutableAttributedString, rect:CGRect) ->CTFrame {
        
        let framesetter = CTFramesetterCreateWithAttributedString(attrString)
        
        let path = CGPath(rect: rect, transform: nil)
        
        let frameRef = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
        
        return frameRef
    }
    
    
    /// 获取单个指定章节
    class func parser(readModel:DZMReadModel!, chapterID: String!, isUpdateFont:Bool = true) ->DZMReadChapterModel? {
        
        return nil
    }
    
  class  func stringSize(ctfrmae: CTFrame) -> CGFloat {
        let lines = CTFrameGetLines(ctfrmae) as Array
        var origins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(ctfrmae, CFRange(location: 0, length: 0), &origins)
        let line = lines.last! as! CTLine
        var ascent: CGFloat = 0
        var dscent: CGFloat = 0
        var leading: CGFloat = 0
        CTLineGetTypographicBounds(line, &ascent, &dscent, &leading)
        let height = GetReadTableViewFrame().maxY - ( origins.last?.y ?? 0) + dscent
        return height
    }
    
    class func replaceATag(_ inputStr: String,
                           attributes: [NSAttributedString.Key: Any]) -> (String, NSMutableAttributedString, [ATagModel]) {
        guard let doc = try? SwiftSoup.parse(inputStr), let allAtgEls = try? doc.select("a"), let onlytext = try? doc.text() else {
            let content = NSMutableAttributedString(string: inputStr, attributes: attributes)
            return (inputStr, content, [])
        }
        let contentText = onlytext
        let content = NSMutableAttributedString(string: contentText, attributes: attributes)

        let atagModels = allAtgEls.map { (elemet) -> ATagModel in
            var atagModel = ATagModel()
            let aText = (try? elemet.text()) ?? ""
            let aHref = (try? elemet.attr("href")) ?? ""
            atagModel.href = aHref
            atagModel.text = aText
            return atagModel
        }
        let pattern = atagModels.map { $0.text ?? ""}.joined(separator: "|")
        if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive) {
            let results = regex.matches(in: contentText, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSRange(location: 0, length: contentText.count))
            for result in results {
                autoreleasepool {
                    let range = result.range
                    let text = onlytext.substring(range)
                    if let index = atagModels.firstIndex(where: { $0.text == text }) {
                        let aTag = atagModels[index]
                        content.yy_setTextHighlight(range, color: UIColor(0x002ECF), backgroundColor: .clear) { (_, _, _, _) in
                            let newA = (aTag.href ?? "").addingPercentEncoding(.urlQueryAllowed)
                            if let url = URL(string: newA) {
                                let vcc = CommonWebViewController(WebViewModel(url))
                                navigator.push(vcc)
                            }
                        }
                    }
                }
            }
        }
     
        return (contentText, content, atagModels)
    }
    
    static func matchSogouKeyWords(_ inputAttr: NSMutableAttributedString) -> (NSMutableAttributedString, [ATagModel])  {
        let sogouKeywords = CommomData.share.sogouKeywords.value
        let num = CommomData.share.sogouKeywordsPrePageNum.value
        if num == 0 || sogouKeywords.isEmpty {
            return (inputAttr, [])
        }
        let pattern = sogouKeywords.map { $0.content ?? ""}.joined(separator: "|")
        let contentText = inputAttr.string
        if let regx = try? NSRegularExpression(pattern: pattern, options: NSRegularExpression.Options.caseInsensitive) {
            var results = regx.matches(in: contentText, options: NSRegularExpression.MatchingOptions.init(rawValue: 0), range: NSRange(location: 0, length: contentText.count))
            var atagModels: [ATagModel] = []
            if results.count > num {
                results = Array(results[0 ..< num])
            }
            for result in results {
                let range = result.range
                let keyword = contentText.substring(result.range)
                if let index = sogouKeywords.firstIndex(where: {$0.content == keyword}) {
                    let model = sogouKeywords[index]
                    if let url = URL(string: model.url!) {
                        inputAttr.yy_setTextHighlight(range,
                                                      color: UIColor(0x002ECF),
                                                      backgroundColor: UIColor.clear) { (_, _, _, _) in
                                                        let vm = SogouWebViewModel(url, title: model.content ?? "")
                                                        navigator.push(SogouWebViewController(vm))
                        }
                        var atagModel = ATagModel()
                        atagModel.href = model.url
                        atagModel.text = keyword
                        atagModels.append(atagModel)
                    }
                }
            }
            return (inputAttr, atagModels)
        }
        return (inputAttr, [])
    }
    
    class func onlyText(_ inputStr: String) -> String {
        if let doc = try? SwiftSoup.parse(inputStr), let allTetx = try? doc.text() {
            return allTetx
        }
        return inputStr
    }

    class func getLineStartLocation(_ line: CTLine) -> Int {
        guard let glyphRuns = CTLineGetGlyphRuns(line) as? [CTRun], let run = glyphRuns.first else {
            return 0
        }
        let runRange = CTRunGetStringRange(run)
        return runRange.location
    }
    
}
