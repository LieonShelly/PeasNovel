//
//  URL+Ex.swift
//  PeasNovel
//
//  Created by xinyue on 2019/6/3.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

extension URL {
    /// url query转字典
    var queryToParams: [String: Any]? {
        
        guard let query = self.query else {
            return nil
        }
        let urlComponents = query.components(separatedBy: "&")

        var params = [String: Any]()

        for keyValuePair in urlComponents {
            
            let pairComponents = keyValuePair.components(separatedBy:"=")
            let key = pairComponents.first?.removingPercentEncoding
            let value = pairComponents.last?.removingPercentEncoding
            
            if let key = key, let value = value {
                if let existValue = params[key] {
                    if var existValue = existValue as? [Any] {
                        existValue.append(value)
                        params[key] = existValue
                    } else {
                        params[key] = [existValue, value]
                    }
                } else {
                    params[key] = value
                }
            }
        }
        return params
    }

}
