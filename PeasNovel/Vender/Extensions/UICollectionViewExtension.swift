//
//  UICollectionViewExtension.swift
//  Arab
//
//  Created by lieon on 2018/9/6.
//  Copyright © 2018年lieon. All rights reserved.
//

import UIKit

extension UICollectionView {
    //MARK: - Cell
    func registerNibWithCell<T: UICollectionViewCell>(_ cell: T.Type) {
        register(UINib(nibName: String(describing: cell), bundle: nil), forCellWithReuseIdentifier: String(describing: cell))
    }
    
    func registerClassWithCell<T: UICollectionViewCell>(_ cell: T.Type) {
        register(cell, forCellWithReuseIdentifier: String(describing: cell))
    }
    
    func dequeueCell<T: UICollectionViewCell>(_ cell: T.Type, for indexPath: IndexPath) -> T {
        return dequeueReusableCell(withReuseIdentifier: String(describing: cell), for: indexPath) as! T
    }
    
    func registerNibWithReusableView<T: UICollectionReusableView>(_ cell: T.Type, forSupplementaryViewOfKind kind: String) {
        register(UINib(nibName: String(describing: cell), bundle: nil), forSupplementaryViewOfKind: kind, withReuseIdentifier: String(describing: cell))
    }
    
    func dequeueReusableView<T: UICollectionReusableView>(_ cell: T.Type,  ofKind kind: String, for indexPath: IndexPath) -> T {
        return dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: String(describing: cell), for: indexPath) as! T
    }
    
    func registerClassWithReusableView<T: UICollectionReusableView>(_ cell: T.Type, forSupplementaryViewOfKind kind: String) {
        register(cell, forSupplementaryViewOfKind: kind, withReuseIdentifier: String(describing: cell))
    }

}
