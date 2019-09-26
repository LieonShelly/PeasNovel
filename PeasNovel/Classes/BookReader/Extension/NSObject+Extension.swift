//
//  NSObject+Extension.swift
//  ReaderKit
//
//  Created by lieon on 2017/5/11.
//  Copyright © 2018年lieon. All rights reserved.
//
import Foundation

class BookModel: NSObject {
    
    var toJSON: [String: Any?] {
        var dict = [String : Any?]()
        
        // 这个类型可以使用CUnsignedInt,对应Swift中的UInt32
        var count: UInt32 = 0
        
        let properties = class_copyPropertyList(self.classForCoder, &count)
        
        for i in 0 ..< Int(count) {
            
            // 获取属性名称
            let property = properties![i]
            let name = property_getName(property)
            let propertyName = String(cString: name)
            
            if (!propertyName.isEmpty) {
                
                // 获取Value数据
                let propertyValue = self.value(forKey: propertyName)
                
                dict[propertyName] = propertyValue
            }
        }
        
        return dict
    }
    
}
