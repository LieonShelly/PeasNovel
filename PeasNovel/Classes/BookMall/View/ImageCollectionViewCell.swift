//
//  ImageCollectionViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/1.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ImageCollectionViewCell: UICollectionViewCell {
    
    var bag = DisposeBag()
    
    @IBOutlet weak var imageView: UIImageView!
    let imageTapOutput: PublishSubject<Void> = .init()
    var tap: UITapGestureRecognizer?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        imageView.isUserInteractionEnabled = true
         tap = UITapGestureRecognizer()
        imageView.addGestureRecognizer(tap!)
    
    }
    override func prepareForReuse() {
        super.prepareForReuse()
         bag = DisposeBag()
    }
    
    func config(_ imageStr: String) {
        if let imageURL = URL(string: imageStr) {
          imageView.kf.setImage(with: imageURL)
        }
    }

}
