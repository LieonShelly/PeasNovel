//
//  CacheService.swift
//  Arab
//
//  Created by weicheng wang on 2018/10/29.
//  Copyright © 2018 kanshu.com. All rights reserved.
//

import Foundation
import RxSwift
import HandyJSON

fileprivate struct CacheService {
    
    fileprivate static func cachePath() -> String? {
        
        if let cacheDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.cachesDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first {
            let filePath = "\(cacheDir)/Peas"
            debugPrint(filePath)
            if FileManager.default.fileExists(atPath: filePath) {
                return filePath
            } else {
                try? FileManager.default.createDirectory(atPath: filePath, withIntermediateDirectories: true, attributes: nil)
                return filePath
            }
        }
        return nil
    }
    
}

extension HandyJSON {
    
    func cache(_ flag: String?) -> Bool {
        if let path = CacheService.cachePath() {
            let filePath = path + "/" + (flag ?? "\(self)")
            guard let json = self.toJSON() else {
                return false
            }
            return NSKeyedArchiver.archiveRootObject(json, toFile: filePath)
        }
        return false
    }
    
    func get(_ flag: String?) -> Self? {
        if let path = CacheService.cachePath() {
            let filePath = path + "/" + (flag ?? "\(self)")
            debugPrint("[CACHE] ", filePath)
            if FileManager.default.fileExists(atPath: filePath),
                let json = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as? [String: Any] {
                guard let model = JSONDeserializer<Self>.deserializeFrom(dict: json) else {
                    return nil
                }
                return model
            }
        }
        return nil
    }
}

extension ObservableType {
    
    func store<T: HandyJSON>(_ flag: String?) -> RxSwift.Observable<Element> where Self.Element == T {
        return map{ model in
            DispatchQueue(label: "CacheService").async(flags: DispatchWorkItemFlags.barrier) {
                _ = model.cache(flag)
            }
            return model
        }
    }
    
    /// 读取本地缓存
    public static func readCache<T: HandyJSON>(_ flag: String?) -> RxSwift.Observable<Element> where Self.Element == T {
        
        if let path = CacheService.cachePath() {
            let filePath = path + "/" + (flag ?? "\(self)")
            debugPrint("[CACHE] ", filePath)
            if FileManager.default.fileExists(atPath: filePath),
                let json = NSKeyedUnarchiver.unarchiveObject(withFile: filePath) as? [String: Any] {
                guard let model = JSONDeserializer<Element>.deserializeFrom(dict: json) else {
                    return Observable<Element>.never()
                }
                return Observable<Element>.just(model)
            } else {
                return Observable<Element>.never()
            }
        }
        return Observable<Element>.never()
    }
    
//    func start(by elements: Self.E...) -> RxSwift.Observable<Self.E> {
//        
//        let model = <#value#>
//        
//        return startWith(<#T##elements: ObservableType.E...##ObservableType.E#>)
//    }
}
