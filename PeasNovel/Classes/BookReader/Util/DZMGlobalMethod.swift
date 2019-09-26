//
//  DZMGlobalMethod.swift
//  ReaderKit
//
//  Created by lieon on 2017/5/11.
//  Copyright © 2018年lieon. All rights reserved.
//

import UIKit
import RealmSwift

// MARK: -- 尺寸计算 以iPhone6为比例
func DZMSizeW(_ size:CGFloat) ->CGFloat {
    
    return size * (ScreenWidth / 375)
}

func DZMSizeH(_ size:CGFloat) ->CGFloat{
    
    return size * (ScreenHeight / 667)
}

// MARK: 公用
/// 章节内容标题
func DZMContentTitle(_ name: String)-> String {
    
    return "\n\(name)\n\n"
}

// MARK: 截屏
/// 获得截屏视图（无值获取当前Window）
func ScreenCapture(_ view:UIView? = nil, _ isSave:Bool = false) ->UIImage {
    
    let captureView = (view ?? (UIApplication.shared.keyWindow ?? UIApplication.shared.windows.first))!
    
    UIGraphicsBeginImageContextWithOptions(captureView.frame.size, false, 0.0)
    
    captureView.layer.render(in: UIGraphicsGetCurrentContext()!)
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    
    UIGraphicsEndImageContext()
    
    if isSave { UIImageWriteToSavedPhotosAlbum(image!, nil, nil, nil) }
    
    return image!
}

// MARK: -- 创建分割线
/// 给一个视图创建添加一条分割线 高度 : HJSpaceLineHeight
func SpaceLineSetup(view:UIView, color:UIColor? = nil) ->UIView {
    
    let spaceLine = UIView()
    
    spaceLine.backgroundColor = color != nil ? color : UIColor.lightGray
    
    view.addSubview(spaceLine)
    
    return spaceLine
}

// MARK: -- 获取时间

/// 传入时间以及格式获得对应时间字符串 "YYYY-MM-dd-HH-mm-ss"
func GetTimerString(dateFormat:String, date:Date = Date()) ->String {
    
    let dateformatter = DateFormatter()
    
    dateformatter.dateFormat = dateFormat
    
    return dateformatter.string(from: date)
}

/// 获取时间戳
func GetTime1970String(date:Date = Date()) -> String {
    
    return String(format: "%.0f",date.timeIntervalSince1970)
}


// MARK: -- 阅读ViewFrame
/// 阅读TableView的位置
func GetReadTableViewFrame() ->CGRect {
    if isX {
        // Y = 刘海高度 + 状态View高 + 间距
        let y =  TopLiuHeight + DZMSpace_25 + DZMSpace_10
        let bottomHeight = ReaderController.UISize.bannerHeight
    
        return CGRect(x: DZMSpace_15,
                      y: y,
                      width: ScreenWidth - 2 * DZMSpace_15,
                      height: ScreenHeight - y - bottomHeight - DZMSpace_25)
        
    } else {
        let y =  DZMSpace_25 + DZMSpace_10
        let bottomHeight = ReaderController.UISize.bannerHeight
        return CGRect(x: DZMSpace_15, y: y, width: ScreenWidth - 2 * DZMSpace_15, height: ScreenHeight - y - bottomHeight - DZMSpace_10)
    }
}

// MARK: 阅读视图位置
/* 阅读视图位置
 
 需要做横竖屏的可以在这里修改阅读View的大小
 
 GetReadViewFrame 会使用与 阅读View的Frame 以及计算分页的范围
 
 */
func GetReadViewFrame() ->CGRect {
   
    return CGRect(x: 0, y: 0, width: GetReadTableViewFrame().width, height: GetReadTableViewFrame().height)
}

// MARK: -- 创建文件夹
/// 创建文件夹 如果存在则不创建
func CreatFilePath(_ filePath:String) ->Bool {
    
    let fileManager = FileManager.default
    
    // 文件夹是否存在
    if fileManager.fileExists(atPath: filePath) {
        
        return true
    }
    
    do{
        try fileManager.createDirectory(atPath: filePath, withIntermediateDirectories: true, attributes: nil)
        
        return true
        
    }catch{}
    
    return false
}


// MARK: -- 文件链接处理
/// 文件类型
func GetFileExtension(_ url:URL) ->String {
    
    return url.path.pathExtension
}

/// 文件名称
func GetFileName(_ url:URL) ->String {
    
    return url.path.lastPathComponent.deletingPathExtension
}


// MARK: -- 阅读页面获取文件方法

/// 主文件夹名称
let ReadFolderName:String = "NovelCache"

/// 归档阅读文件文件
func ReadKeyedArchiver(folderName:String,fileName:String,object:AnyObject) {
    
    var path = (NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last!) + "/\(ReadFolderName)/\(folderName)"
    
    if (CreatFilePath(path)) { // 创建文件夹成功或者文件夹存在
        path = path + "/\(fileName)"
//        print("NovelPath:", path)
        NSKeyedArchiver.archiveRootObject(object, toFile: path)
    }
}

class ReaderFileService {
    static func bookSize(_ bookId: String ) -> Float {
        let path = (NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last!) + "/\(ReadFolderName)/\(bookId)"
        return FileService.folderSize(path)
    }
}

class FileService {
    static func fileSize(_ filePath: String ) -> Float {
        let manager = FileManager.default
        if manager.fileExists(atPath: filePath), let fileSize = try? manager.attributesOfItem(atPath: filePath)[FileAttributeKey.size] as? Float {
            return fileSize ?? 0
        }
        return 0
    }
    
    static func folderSize(_ folderPath: String) -> Float {
        let manager = FileManager.default
        if !manager.fileExists(atPath: folderPath) {
            return 0
        }
        guard let subPaths = manager.subpaths(atPath: folderPath) else {
            return 0
        }
        var tottalSize: Float = 0
        for subPath in subPaths {
            let fileAbsPath = folderPath + "/" + subPath
            let fileSize = FileService.fileSize(fileAbsPath)
            print(fileSize)
            tottalSize += fileSize
        }
        return tottalSize
    }
    
    static func fileSizeDesc(_ size: Float) -> String {
        if size < 1024.0 {
            return String(format: "%.2fB", size)
        } else if size > 1024.0 && size < 1024.0 * 1024.0 {
            return String(format: "%.2fKB", size / 1024.0)
        } else if size > 1024.0 * 1024 && size < 1024.0 * 1024.0 * 1024.0 {
            return String(format: "%.2fMB", size / (1024.0 * 1024.0))
        } else {
            return String(format: "%.2fGB", size / (1024.0 * 1024.0 * 1024.0))
        }
    }
    
    static func freeDiskSpaceDesc() -> String {
        return DiskSpaceTool.freeDiskSpaceInBytes()
    }
    
    static func totalDiskSpaceDesc() -> String {
        return DiskSpaceTool.totalDiskSpaceInBytes()
    }
    
    static func usedDiskSpaceInBytes() -> String {
        return DiskSpaceTool.usedDiskSpaceInBytes()
    }
    
}


/// 解档阅读文件文件
func ReadKeyedUnarchiver(folderName:String,fileName:String) ->AnyObject? {
    
    let path = ((NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last! as String) + "/\(ReadFolderName)/\(folderName)") + "/\(fileName)"
    
    return NSKeyedUnarchiver.unarchiveObject(withFile: path) as AnyObject?
}

/// 删除阅读归档文件
func ReadKeyedRemoveArchiver(folderName:String,fileName:String? = nil) {
    
    var path = ((NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last! as String) + "/\(ReadFolderName)/\(folderName)")
    
    if fileName != nil { path +=  "/\(fileName!)" }
    
    do{
        try FileManager.default.removeItem(atPath: path)
    }catch{}
}

/// 是否存在了该归档文件
func ReadKeyedIsExistArchiver(folderName:String,fileName:String? = nil) ->Bool {
    
    var path = ((NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.documentDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).last! as String) + "/\(ReadFolderName)/\(folderName)")
    
    if fileName != nil { path +=  "/\(fileName!)" }
    
    return FileManager.default.fileExists(atPath: path)
}
