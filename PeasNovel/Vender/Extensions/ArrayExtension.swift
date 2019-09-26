//
//  ArrayExtension.swift
//  Arab
//
//  Created by lieon on 2018/9/12.
//  Copyright © 2018年lieon. All rights reserved.
//

import Foundation
import UIKit

extension Array {
    func rtl() -> Array {
        if UIApplication.shared.isRtl() {
          return self.reversed()
        }
        return self
    }
    
    func shuffle() -> Array {
        var list = self
        for index in 0..<list.count {
            let newIndex = Int(arc4random_uniform(UInt32(list.count - index))) + index
            if index != newIndex {
                list.swapAt(index, newIndex)
            }
        }
        return list
    }
    
    func sample(size: Int, noRepeat: Bool = false ) -> [Element]? {
        guard !isEmpty else {
            return nil
        }
        var sampleElements: [Element] = []
        if !noRepeat {
             sampleElements.append(contentsOf: self[ 0..<size])
        } else {
            var copy = self.map { $0 }
            for _ in 0..<size {
                if copy.isEmpty { break }
                let randomIndex = Int(arc4random_uniform(UInt32(copy.count)))
                let element = copy[randomIndex]
                sampleElements.append(element)
                copy.remove(at: randomIndex)
            }
        }
        return sampleElements
    }
}


extension Double {
    var fitScale: CGFloat {
        return CGFloat(self) * CGFloat (UIScreen.main.bounds.size.width / 375.0)
    }
    
    var tenK: String {
        if self > 10000 {
            return String(format: "%.1f万", self / 10000.0)
        }
        return "\(String(format: "%.0f", self))"
    }
}
