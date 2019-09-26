//
//  TwoBtnTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/2.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift

class TwoBtnTableViewCell: UITableViewCell {
    
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    let buttonTap: PublishSubject<String> = .init()
    
    var bag = DisposeBag()

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        bag = DisposeBag()
    }

    func set(_ item: [BoutiqueActiveModel]) {
        
        bag = DisposeBag()
        
        for (index, model) in item.enumerated() {
            let url = URL(string: model.boutique_img ?? "")
            if index == 0 {
                leftButton.kf.setBackgroundImage(with: url, for: UIControl.State.normal)
                leftButton
                    .rx
                    .tap
                    .map{ model.jump_url }
                    .unwrap()
                    .bind(to: self.buttonTap)
                    .disposed(by: bag)
                
                
            }else if index == 1 {
                rightButton.kf.setBackgroundImage(with: url, for: UIControl.State.normal)
                rightButton
                    .rx
                    .tap
                    .map{ model.jump_url }
                    .unwrap()
                    .bind(to: self.buttonTap)
                    .disposed(by: bag)
            }
            
        }
    }
    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
