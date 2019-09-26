//
//  ChapterConnectionAdViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/9.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import InMobiSDK
import RxSwift
import RxCocoa

class ChapterConnectionAdViewController: BaseViewController {
    @IBOutlet weak var activity: UIActivityIndicatorView!
    @IBOutlet weak var titleTop: NSLayoutConstraint!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var noAdBtn: UIButton!
    @IBOutlet weak var adContainerView: UIView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var adContainerHeight: NSLayoutConstraint!
    var bannerView: UIView?
    @IBOutlet weak var adCotainnerWidth: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    let noAdInput: PublishSubject<Void> = .init()
    private var infoView: UIView?
    private var isShowBottom: Bool = false
    fileprivate var bottomBanner: UIView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        activity.startAnimating()
        noAdBtn.layer.cornerRadius = 23
        noAdBtn.layer.masksToBounds = true
        adCotainnerWidth.constant =  UIScreen.main.bounds.width
        adContainerHeight.constant  = (UIScreen.main.bounds.width - 16 * 2) * 2.0 / 3.0 + 110
        containerView.backgroundColor = DZMReadConfigure.shared().readColor()
        scrollView.backgroundColor = DZMReadConfigure.shared().readColor()
        scrollView.contentSize = CGSize(width: 0, height: UIScreen.main.bounds.height * 2)
        noAdBtn.setTitle(CommomData.share.switcherConfig.value?.buy_vip ?? false ? "0元免广告阅读": "购买VIP会员免广告" , for: .normal)
        continueBtn.isHidden = !isShowBottom
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    convenience init(_ viewModel: ChapterConnectionAdViewModel,
                     isShowBottomBanner: Bool = false,
                     bannerConfig: LocalAdvertise? =  AdvertiseService.advertiseConfig(AdPosition.readerBottomBanner)) {
        self.init(nibName: "ChapterConnectionAdViewController", bundle: nil)
        self.isShowBottom = isShowBottomBanner
        self.rx
            .viewDidLoad
            .subscribe(onNext: { [weak self] in
                self?.config(viewModel, bannerConfig: bannerConfig)
            })
            .disposed(by: bag)
        
        self.rx
            .viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    private func config(_ viewModel: ChapterConnectionAdViewModel, bannerConfig: LocalAdvertise?) {
        clearErrorLog(bannerConfig)
        titleTop.constant = 40 + UIDevice.current.safeAreaInsets.top
        let isShowBottombanner = self.isShowBottom
        viewModel.titleOutput!
            .subscribe(onNext: { [weak self](title) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.titleLabel.text = title
            })
            .disposed(by: bag)
        
        continueBtn.rx.tap.mapToVoid()
            .subscribe(onNext: {[weak self] (_) in
                guard let weakSelf = self else {
                    return
                }
                viewModel.infoAdViewModel = nil
                viewModel.bannerViewModel = nil
                weakSelf.dismiss(animated: true, completion: {
                    
                })
            })
            .disposed(by: bag)
        
        noAdBtn.rx.tap
            .mapToVoid()
            .bind(to: viewModel.noAdBtnInput)
            .disposed(by: bag)
        
        noAdInput
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
        
        var adUIConfig = ChapterConnectionAdUIConfig()
        adUIConfig.holderVC = self
        Observable.just(adUIConfig)
            .bind(to: viewModel.adUIConfigInput)
            .disposed(by: bag)
        
        viewModel.bannerConfigOutput.accept(bannerConfig)
        
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.loadSuccess)
            .observeOn(MainScheduler.instance)
            .map { $0.object as? LocalAdvertise }
            .unwrap()
            .filter { $0.ad_position == viewModel.config.ad_position }
            .mapToVoid()
            .subscribe(onNext: { [weak self](_) in
                if let weakSelf = self {
                      weakSelf.activity.stopAnimating()
                }
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.allTypeLoadFail)
            .map { $0.object as? LocalAdvertise }
            .unwrap()
            .filter { $0.ad_position == AdPosition.readerPerPageBigPic.rawValue || $0.ad_position == AdPosition.readerPer5PageBigPic.rawValue }
            .mapToVoid()
            .subscribe(onNext: { [weak self](_) in
                if let weakSelf = self {
                    weakSelf.dismiss(animated: true, completion: {
                    })
                }
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
        
     NotificationCenter.default.rx.notification(NSNotification.Name.Event.dismissAdChapter)
        .mapToVoid()
        .observeOn(MainScheduler.instance)
        .subscribe(onNext: {[weak self] (_) in
            guard let weakSelf = self else {
                return
            }
            weakSelf.dismiss(animated: true, completion: {
            })
        })
        .disposed(by: bag)

        viewModel.infoAdOutput
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self](config) in
                guard let weakSelf = self else {
                    return
                }
                guard let infoView = ReaderViewInfoService.chooseInfoAdView(config.localConfig, viewFrame: weakSelf.adContainerView.bounds) else {
                    return
                }
                weakSelf.infoView?.removeFromSuperview()
                weakSelf.infoView = infoView
                weakSelf.adContainerView.addSubview(infoView)
                ReaderViewInfoService.configData(config, view: infoView)
                if let infoView = infoView as? IMReaderChapterinfoAdView {
                    infoView.isDefaultCloseAction.accept(false)
                    infoView.backgroundColor = .clear
                    infoView.closeBtn.rx.tap.mapToVoid()
                        .mapToVoid()
                        .bind(to: viewModel.noAdBtnInput)
                        .disposed(by: weakSelf.bag)
                }
                
                if let infoView = infoView as? BUNativeFeedView {
                    infoView.isDefaultCloseAction.accept(false)
                    infoView.backgroundColor = .clear
                    infoView.closeBtn.rx.tap.mapToVoid()
                        .mapToVoid()
                        .bind(to: viewModel.noAdBtnInput)
                        .disposed(by: weakSelf.bag)
                }
            })
            .disposed(by: bag)
       
        viewModel.bannerConfigOutput
            .asObservable()
            .unwrap()
            .filter {_ in isShowBottombanner }
            .filter { $0.ad_type == AdvertiseType.GDT.rawValue }
            .subscribe(onNext: { [weak self](config) in
                guard let weakSelf = self else {
                    return
                }
                let gdtViewModel = GDTBannerViewModel(config, outterConfig: weakSelf, viewController: weakSelf)
                gdtViewModel.nativeAdOutput
                    .asObservable()
                    .map { LocalTempAdConfig(config, adType: .GDT($0))}
                    .bind(to: viewModel.bannerOutput)
                    .disposed(by: viewModel.bag)
                viewModel.bannerViewModel = gdtViewModel
            })
            .disposed(by: bag)
        
        viewModel.bannerConfigOutput
            .asObservable()
            .unwrap()
            .filter {_ in isShowBottombanner }
            .filter { $0.ad_type == AdvertiseType.todayHeadeline.rawValue }
            .subscribe(onNext: { [weak self](config) in
                guard let weakSelf = self else {
                    return
                }
                let buViewModel =  BUNativeBannerViewModel(config, viewController: weakSelf)
                buViewModel.nativeAdOutput
                    .asObservable()
                    .map { LocalTempAdConfig(config, adType: .todayHeadeline($0))}
                    .bind(to: viewModel.bannerOutput)
                    .disposed(by: viewModel.bag)
                viewModel.bannerViewModel = buViewModel
            })
            .disposed(by: bag)
        
        viewModel.bannerOutput
            .asObservable()
            .filter {_ in isShowBottombanner }
            .subscribe(onNext: { [weak self](config) in
                guard let weakSelf = self else {
                    return
                }
                let bottomBanner = weakSelf.setupBottombannr(config.localConfig)
                ViewBannerSerVice.configData(config, bannerView: bottomBanner)
            }, onError: { (error) in
                
            })
            .disposed(by: bag)
    }
    
  
    fileprivate func setupBottombannr(_ config: LocalAdvertise) -> UIView? {
        guard let  bottomBanner =  ViewBannerSerVice.chooseBanner(config, bannerFrame: CGRect(x: 0, y: UIScreen.main.bounds.height - 75 - UIDevice.current.safeAreaInsets.bottom, width: UIScreen.main.bounds.width , height: 75 +  UIDevice.current.safeAreaInsets.bottom)) else {
            return nil
        }
        bottomBanner.backgroundColor = DZMReadConfigure.shared().readColor()
        if let bottom = bottomBanner as? IMBannerView {
            bottom.isDefaultCloseAction.accept(false)
            bottom.closeBtn.rx.tap.mapToVoid()
                .subscribe(onNext: {[weak self] (_) in
                    guard let weakSelf = self else {
                        return
                    }
                    weakSelf.noAdInput.onNext(())
                })
                .disposed(by: bag)
        }
        if let bottom = bottomBanner as? BUNativeBannerView {
            bottom.isDefaultCloseAction.accept(false)
            bottom.closeBtn.rx.tap.mapToVoid()
                .subscribe(onNext: {[weak self] (_) in
                    guard let weakSelf = self else {
                        return
                    }
                    weakSelf.noAdInput.onNext(())
                })
                .disposed(by: bag)
        }
        if self.bottomBanner != nil {
            self.bottomBanner?.removeFromSuperview()
        }
        self.bottomBanner = bottomBanner
        self.bottomBanner!.isHidden = !isShowBottom
        containerView.addSubview(bottomBanner)
        bottomBanner.snp.makeConstraints {
            $0.left.right.equalTo(0)
            $0.bottom.equalTo(0)
            $0.height.equalTo(75 +  UIDevice.current.safeAreaInsets.bottom)
        }
        return bottomBanner
    }
    
    deinit {
        debugPrint("ChapterConnectionAdViewController - deinit")
    }
    
}

extension ChapterConnectionAdViewController: Advertiseable {
    func adClickHandler(_ config: LocalAdvertise?) -> Bool {
        noAdInput.onNext(())
        return true
    }
}
