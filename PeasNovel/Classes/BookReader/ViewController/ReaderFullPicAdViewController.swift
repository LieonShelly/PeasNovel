//
//  ReaderFullPicAdViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/9.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift

class ReaderFullPicAdViewController: BaseViewController {
    @IBOutlet weak var guideView: UIButton!
    let noAdInput: PublishSubject<Void> = .init()
    private var infoView: UIView?
    @IBOutlet weak var closeBg: UIView!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var panView: UIView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        bag = DisposeBag()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

    }
    
    convenience init(_ viewModel: ReaderFullPicAdViewModel) {
        self.init(nibName: "ReaderFullPicAdViewController", bundle: nil)
        self.rx
            .viewDidLoad
            .subscribe(onNext: { [weak self] in
                self?.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx
            .viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
        
    }
    
    
    private func config(_ viewModel: ReaderFullPicAdViewModel) {
        closeBg.layer.cornerRadius = 13
        closeBg.layer.masksToBounds = true
        view.backgroundColor = DZMReadConfigure.shared().readColor()
        let isShowGuide = UserDefaults.standard.value(forKey: Constant.UserDefaultsKey.readerFullScreenAdGuide) as? Bool  ?? false
        if !isShowGuide {
            guideView.rx.tap
                .mapToVoid()
                .subscribe(onNext: { [weak self](_) in
                    guard let weakSelf = self else {
                        return
                    }
                    UserDefaults.standard.set(true, forKey: Constant.UserDefaultsKey.readerFullScreenAdGuide)
                    UserDefaults.standard.synchronize()
                    weakSelf.guideView.isHidden = true
                })
                .disposed(by: bag)
        } else {
            guideView.removeFromSuperview()
        }
        
        var adUIConfig = ReaderFullScreenAdUIConfig()
        adUIConfig.holderVC = self
        Observable.just(adUIConfig)
            .bind(to: viewModel.adUIConfigInput)
            .disposed(by: bag)
        
        closeBtn.rx.tap
            .bind(to: viewModel.noAdBtnInput)
            .disposed(by: bag)
        
        viewModel.chargeOutput
            .subscribe(onNext: { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.navigationController?.pushViewController(ChargeViewController($0), animated: true)
            })
            .disposed(by: bag)
        
        viewModel.chargeAlertOutput
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                let vcc = ChargeAlertViewController($0)
                let nav = NavigationViewController(rootViewController: vcc)
                nav.modalPresentationStyle = .overCurrentContext
                weakSelf.present(nav, animated: true, completion: nil)
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.clickClose)
            .map { $0.object as? LocalAdvertise }
            .unwrap()
            .filter { $0.ad_position == viewModel.config.ad_position }
            .mapToVoid()
            .subscribe(onNext: { [weak self](_) in
                if let weakSelf = self {
                    weakSelf.noAdInput.onNext(())
                }
            })
            .disposed(by: bag)
        
        view.isHidden = true
        view.isUserInteractionEnabled = false
        viewModel.infoAdOutput
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self](config) in
                guard let weakSelf = self else {
                    return
                }
                guard let infoView = ReaderAdService.choosePicAdView(config.localConfig, viewFrame: weakSelf.view.bounds) else {
                    return
                }
                weakSelf.view.isHidden = false
                weakSelf.view.isUserInteractionEnabled = true
                weakSelf.infoView?.removeFromSuperview()
                weakSelf.infoView = infoView
                infoView.backgroundColor = .clear
                weakSelf.panView.insertSubview(infoView, at: 0)
                ReaderAdService.configPicAdData(config, view: infoView)
            })
            .disposed(by: bag)
        
    }
    
    
    fileprivate func dismiss() {
        self.view.removeFromSuperview()
        self.removeFromParent()
    }
    
}




struct ReaderFullScreenAdUIConfig: AdvertiseUIInterface {
    var holderVC: UIViewController?
    
    init() {
        
    }
    
    func adClickHandler(_ config: LocalAdvertise?) -> Bool {
        NotificationCenter.default.post(name: NSNotification.Name.Advertise.clickClose, object: config)
        return true
    }
    
    func infoAdSize(_ type: AdvertiseType?) -> CGSize {
        return GetReadTableViewFrame().size
    }
}

