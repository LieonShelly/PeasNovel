//
//  ReaderLastPageUnfinishTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/22.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ReaderLastPageUnfinishTableViewCell: UITableViewCell {
    let updateBtnOutput: PublishSubject<Bool> = .init()
    let backBookShelfOutput: PublishSubject<Void> = .init()
    
    @IBOutlet weak var updateBtn: UIButton!
    
    @IBOutlet weak var backBtn: UIButton!
    
    var bag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configRx()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        configRx()
    }
    
    func configRx() {
        bag = DisposeBag()
         updateBtn.rx.tap.mapToVoid()
            .subscribe(onNext: { [weak self](_) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.updateBtn.isSelected = !weakSelf.updateBtn.isSelected
                weakSelf.updateBtnOutput.onNext( weakSelf.updateBtn.isSelected)
            })
            .disposed(by: bag)
     
        
        backBtn.rx.tap.mapToVoid()
            .bind(to: backBookShelfOutput)
            .disposed(by: bag)
    }
    
    
}
