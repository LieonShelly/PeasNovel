//
//  Transform.swift
//  Arab
//
//  Created by lieon on 2018/10/31.
//  Copyright © 2018 kanshu.com. All rights reserved.
//

import Foundation
import HandyJSON

open class StringPercentEndingTransform: TransformType {
    public typealias Object = String
    
    public typealias JSON = String
    
    public func transformFromJSON(_ value: Any?) -> String? {
        if let str = value as? String {
            let newStr = str.removingPercentEncoding?.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed)
            return newStr
        }
        return  nil
    }
    
    public func transformToJSON(_ value: String?) -> String? {
        if let str = value?.removingPercentEncoding {
            return str
        }
        return  value
    }
}
