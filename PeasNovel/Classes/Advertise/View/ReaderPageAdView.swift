//
//  ReaderPageAdView.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/2.
//  Copyright © 2019 NotBroken. All rights reserved.
//  阅读页页码中的广告View

import UIKit
import RxSwift
import RxCocoa

class ReaderPageAdView: UIView {
    var infoView: UIView?
    let bag = DisposeBag()
    var viewModel: ReaderPageAdViewModel?
    fileprivate lazy var placeHolder: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFit
        view.image = UIImage(named: "flash_logo")
        return view
    }()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(placeHolder)
        placeHolder.snp.makeConstraints{
            $0.center.equalTo(self.snp.center)
            $0.size.equalTo(CGSize(width: 80, height: 120))
        }
    }
    
    convenience init(_ viewModel: ReaderPageAdViewModel) {
        let adSize = viewModel.adUIConfig.infoAdSize(AdvertiseType(rawValue: viewModel.adConfig.ad_type))
        self.init(frame: CGRect(x: 0, y: 0, width: adSize.width, height: adSize.height))
        clipsToBounds = true
        backgroundColor = .white
        self.viewModel = viewModel
        viewModel.loadAdInput.onNext(())
        viewModel.adOutput
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self](config) in
                guard let weakSelf = self else {
                    return
                }
                guard let infoView = ReaderViewInfoService.choosePageInfoAdView(config.localConfig, viewFrame: weakSelf.bounds) else {
                    return
                }
                weakSelf.infoView?.removeFromSuperview()
                weakSelf.infoView = infoView
                weakSelf.addSubview(infoView)
                ReaderViewInfoService.configPageInfoData(config, view: infoView)
                if let infoView = infoView as? IMReaderPageInfoView {
                    infoView.isDefaultCloseAction.accept(false)
                    infoView.adContainerHeight.constant = adSize.height
                    infoView.backgroundColor = .white
                    infoView.closeBtn.rx.tap.mapToVoid()
                        .mapToVoid()
                        .subscribe(onNext: { (_) in
                            NotificationCenter.default.post(name: Notification.Name.UIUpdate.readerCloseAd, object: nil)
                        })
                        .disposed(by: weakSelf.bag)
                }
                
                if let infoView = infoView as? BUNativeFeedView {
                    infoView.isDefaultCloseAction.accept(false)
                    infoView.backgroundColor = .clear
                    infoView.closeBtn.rx.tap.mapToVoid()
                        .mapToVoid()
                        .subscribe(onNext: { (_) in
                            NotificationCenter.default.post(name: Notification.Name.UIUpdate.readerCloseAd, object: nil)
                        })
                        .disposed(by: weakSelf.bag)
                }
            })
            .disposed(by: bag)
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    deinit {
        viewModel = nil
        print("deinit - ReaderPageAdView")
    }
}
