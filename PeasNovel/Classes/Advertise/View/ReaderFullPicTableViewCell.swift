//
//  ReaderFullPicTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/9/7.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class ReaderFullPicTableViewCell: UITableViewCell {
    private var infoView: UIView?
    @IBOutlet weak var closeBg: UIView!
    @IBOutlet weak var closeBtn: UIButton!
    var bag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        closeBg.layer.cornerRadius = 13
        closeBg.layer.masksToBounds = true
        contentView.backgroundColor = DZMReadConfigure.shared().readColor()
    }

    override func prepareForReuse() {
        prepareForReuse()
        bag = DisposeBag()
    }

    func config(_ viewModel: ReaderFullPicAdViewModel, adUIConfig: ReaderFullScreenAdUIConfig) {
        viewModel.clearLogInput.onNext(())
        Observable.just(adUIConfig)
            .bind(to: viewModel.adUIConfigInput)
            .disposed(by: bag)
        
        closeBtn.rx.tap
            .subscribe(onNext: { (_) in
                NotificationCenter.default.post(name: Notification.Name.UIUpdate.readerCloseAd, object: nil)
            })
            .disposed(by: bag)

        
        viewModel.infoAdOutput
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self](config) in
                guard let weakSelf = self else {
                    return
                }
                guard let infoView = ReaderAdService.choosePicAdView(config.localConfig, viewFrame: CGRect(x: 0, y: 0, width: GetReadViewFrame().width, height: weakSelf.bounds.height)) else {
                    return
                }
                infoView.frame.origin = .zero
                weakSelf.infoView?.removeFromSuperview()
                weakSelf.infoView = infoView
                infoView.backgroundColor = .clear
                weakSelf.contentView.insertSubview(infoView, at: 0)
                ReaderAdService.configPicAdData(config, view: infoView)
            })
            .disposed(by: bag)
        
    }
    
}
