//
//  SearchEmptyWithNetPageTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/2.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift

class SearchEmptyWithNetPageTableViewCell: UITableViewCell {
    
    var model: SearchWebSwitchModel?
    let buttonAction: PublishSubject<Int> = .init() 
    
    var bag = DisposeBag()
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        selectionStyle = .none
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        bag = DisposeBag()
    }

    @IBAction func middleAction(_ sender: Any) {
        buttonAction.on(.next(0))
    }
    @IBAction func leftAction(_ sender: Any) {
        buttonAction.on(.next(1))
    }
    @IBAction func rightAction(_ sender: Any) {
        buttonAction.on(.next(2))
    }
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
