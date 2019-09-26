//
//  ReaderMenuController.swift
//  ReaderKit
//
//  Created by lieon on 2017/5/11.
//  Copyright © 2018年lieon. All rights reserved.
//

/// 翻页类型
enum DZMRMEffectType:NSInteger {
    case none               // 无效果
    case translation        // 平移
    case simulation         // 仿真
//    case upAndDown          // 上下
    case leftRightScroll    // 左右滑动
}

/// 字体类型
enum DZMRMFontType:NSInteger {
    case system             // 系统
    case one                // 黑体
    case two                // 楷体
    case three              // 宋体
}

import UIKit
import RxSwift
import RxCocoa

@objc protocol DZMReadMenuDelegate:NSObjectProtocol {
    
    /// 状态栏 将要 - 隐藏以及显示状态改变
    @objc optional func readMenuWillShowOrHidden(readMenu:ReaderMenuController, isShow:Bool)
    
    /// 状态栏 完成 - 隐藏以及显示状态改变
    @objc optional func readMenuDidShowOrHidden(readMenu:ReaderMenuController, isShow:Bool)
    
    /// 点击下载
    @objc optional func readMenuClickDownload(readMenu:ReaderMenuController)
    
    /// 点击书签按钮
    @objc optional func readMenuClickMarkButton(readMenu:ReaderMenuController, button:UIButton)

    /// 点击返回按钮
    @objc optional func readMenuClickBackButton(readMenu:ReaderMenuController, button:UIButton)
    
    /// 点击目录按钮
    @objc optional func readMenuCatelogButton(readMenu:ReaderMenuController, button:UIButton)
    
    /// 点击上一章（上一话）
    @objc optional func readMenuClickPreviousChapter(readMenu:ReaderMenuController)
    
    /// 点击下一章（下一话）
    @objc optional func readMenuClickNextChapter(readMenu:ReaderMenuController)
    
    /// 停止滚动进度条
    @objc optional func readMenuSliderEndScroll(readMenu:ReaderMenuController,slider:UISlider)
    
    /// 点击背景颜色
    @objc optional func readMenuClickSetuptColor(readMenu:ReaderMenuController,index:NSInteger,color:UIColor)
    
    /// 点击翻书动画
    @objc optional func readMenuClickSetuptEffect(readMenu:ReaderMenuController,index:NSInteger)
    
    /// 点击字体
    @objc optional func readMenuClickSetuptFont(readMenu:ReaderMenuController,index:NSInteger)
    
    /// 点击字体大小
    @objc optional func readMenuClickSetuptFontSize(readMenu:ReaderMenuController,fontSize:CGFloat)
    
    /// 点击日间夜间
    @objc optional func readMenuClickLightButton(readMenu:ReaderMenuController,isDay:Bool)
    
    /// 点击章节列表
    @objc optional func readMenuClickChapterList(readMenu:ReaderMenuController,readChapterListModel:DZMReadChapterListModel)
    
    /// 点击书签列表
    @objc optional func readMenuClickMarkList(readMenu:ReaderMenuController,readMarkModel:DZMReadMarkModel)
    
}

class ReaderMenuController: NSObject,UIGestureRecognizerDelegate {
    
    /// 控制器
    private(set) weak var vc:ReaderController!
    
    /// 代理
    private(set) weak var delegate:DZMReadMenuDelegate!
    
    /// 阅读页面动画的时间
    private var animateDuration:TimeInterval = 0.20
    
    /// 菜单显示
    private(set) var menuShow:Bool = false
    
    /// TopView
    private(set) var topView:ReaderTopView!
    
    /// BottomView
    private(set) var bottomView: ReaderBootomView!
    
    /// 亮度
    private(set) var lightView: ReaderLightView!
    
    /// 遮盖亮度
    private(set) var coverView:UIView!
    
    /// 小说阅读设置
    private var novelsSettingView:ReaderSettingView!
    
    /// 进度View
    private(set) var progressView: ReaderProgressView!
    
    /// BottomView 高
    private var BottomViewH:CGFloat {
       return UIDevice.current.isiPhoneXSeries ? 52 + UIDevice.current.safeAreaInsets.bottom : 52
    }
    
    /// BottomView Y
    private var bottomViewY: CGFloat {
        if self.vc.readerMode.value.rawValue == ReaderMode.advertise.rawValue {
            return UIScreen.main.bounds.height - self.BottomViewH - UIDevice.current.safeAreaInsets.bottom
        }
        return UIScreen.main.bounds.height - self.BottomViewH
    }
    
    /// LightView 高
    private let LightViewH:CGFloat = isX ? 120 : 100
    
    /// LightButton 宽高
    private let lightButtonWH:CGFloat = 84
    
    /// NovelsSettingView 高
    private let NovelsSettingViewH:CGFloat = 230
    
    private let progressViewH: CGFloat = 145
    
    private let bookMarkViewH: CGFloat = 180
    
    var bottomBanner: UIView?
    
    /// 书签列表
    lazy var bookMarkView: ReaderBookMarkView = {
        let bookMarkView = ReaderBookMarkView.loadView()
        return bookMarkView
    }()
    
    
    /// 初始化函数
    init(vc:ReaderController,delegate:DZMReadMenuDelegate) {
        
        super.init()
        
        // 记录
        self.vc = vc
        self.delegate = delegate
        
        // 允许获取电量信息
        UIDevice.current.isBatteryMonitoringEnabled = true
        // 创建UI
        creatUI()
        
        // 初始化数据
        initData()
        
        /// 看了激励视频，免5章节广告
        NotificationCenter.default.rx
            .notification(NSNotification.Name.Advertise.rewardVideoAdWillDismiss)
            .map { $0.object as? LocalAdvertise }
            .unwrap()
            .filter { $0.ad_position == AdPosition.readerRewardVideoAd.rawValue }
            .subscribe(onNext: {[weak self] (_) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.bottomBanner?.isHidden = true
                NotificationCenter.default.post(name: NSNotification.Name.Event.reloadReader, object: nil)
            })
            .disposed(by: vc.bag)
        
        NotificationCenter.default.rx
            .notification(NSNotification.Name.AppleIAP.chargeSuccess)
            .subscribe(onNext: {[weak self] (_) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.bottomBanner?.removeFromSuperview()
            })
            .disposed(by: vc.bag)
        
        NotificationCenter.default.rx
            .notification(NSNotification.Name.UIUpdate.readerIntroPagedidTap)
            .subscribe(onNext: {[weak self] (_) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.menuSH()
            })
            .disposed(by: vc.bag)
        
    }
    
    private func creatUI() {
        initTopView()
        initBottomView()
        initLightView()
        initBookMarkView()
        initNovelsSettingView()
        initProgressView()
        initCoverView()
        NotificationCenter.default.rx.notification(Notification.Name.Book.ListenBook.didStartAllTask)
            .map {_ in false }
            .subscribe(onNext: {[weak self] (isHideen) in
                guard let weakSelf = self else {
                    return
                }
               weakSelf.menu(isShow: isHideen)
            })
            .disposed(by: vc.bag)
    }

    func initData() {
        progressView.sliderUpdate()
        bottomView.bookMarkBtn.isSelected = vc.readModel.checkMark()
    }

    
    private func initNovelsSettingView() {
        novelsSettingView = ReaderSettingView.loadView(readMenu: self)
        novelsSettingView.frame = CGRect(x: 0, y: ScreenHeight, width: ScreenWidth, height: NovelsSettingViewH)
        novelsSettingView.isHidden = true
        vc.view.addSubview(novelsSettingView)
    }
    
    private func initCoverView() {
        
        coverView = UIView()
        
        coverView.isUserInteractionEnabled = false
        
        coverView.backgroundColor = UIColor.black.withAlphaComponent(0.6)
        
        coverView.alpha = CGFloat(DZMUserDefaults.floatForKey(ReaderBrightnessKey))
        
        vc.view.addSubview(coverView)
        
        coverView.frame = vc.view.bounds
    }
    
    private func initLightView() {
        
        lightView = ReaderLightView.loadView(readMenu: self)
        
        lightView.isHidden = true
        
        vc.view.addSubview(lightView)
        
        lightView.frame = CGRect(x: 0, y: ScreenHeight, width: ScreenWidth, height: LightViewH)
    }
    
    private func initBookMarkView() {
        
        bookMarkView.isHidden = true
        
        vc.view.addSubview(bookMarkView)
        
        bookMarkView.frame = CGRect(x: 0, y: ScreenHeight, width: ScreenWidth, height: bookMarkViewH)
    }
    
    func initProgressView() {
        progressView = ReaderProgressView.loadView(readMenu: self)
        progressView.frame = CGRect(x: 0, y: ScreenHeight, width: ScreenWidth, height: progressViewH)
        progressView.isHidden = true
        vc.view.addSubview(progressView)
    }
    
     func clickLightButton(button:UIButton) {
        
        if button.tag == 1 { /// 夜间模式
            UIView.animate(withDuration: animateDuration, animations: { [weak self] ()->Void in
                
                self?.coverView.alpha = 1.0
            })
        } else if button.tag == 2 {
            
            UIView.animate(withDuration: animateDuration, animations: { [weak self] ()->Void in
                
                self?.coverView.alpha = 0.7
            })
        } else if button.tag == 3 {
            UIView.animate(withDuration: animateDuration, animations: { [weak self] ()->Void in
                
                self?.coverView.alpha = 1 - UIScreen.main.brightness
            })
        }
        if let coverView = self.coverView {
            DZMUserDefaults.setFloat(Float(coverView.alpha), key: ReaderBrightnessKey)
        }
        delegate?.readMenuClickLightButton?(readMenu: self, isDay:  button.tag != 1)
    }
    
    @objc func backButtonAction(button:UIButton) {
        delegate?.readMenuClickBackButton?(readMenu: self, button: topView.backBtn)
    }
    
    @objc func catelogButtonAction(button:UIButton) {
        delegate?.readMenuCatelogButton?(readMenu: self, button: topView.listenBtn)
    }
    
    func adjustLightWithSlider(_ slider: UISlider) {
        UIView.animate(withDuration: animateDuration, animations: { [weak self] ()->Void in
            self?.coverView.alpha = 1 - CGFloat(slider.value)
        })
    }
    
    func adjustLight(with value: CGFloat) {
        self.lightView.slider.setValue(Float(value), animated: false)
        UIView.animate(withDuration: animateDuration, animations: { [weak self] ()->Void in
            self?.coverView.alpha = 1 - value
        })
    }
    
    func adjustLightWithSliderExit(_ slider: UISlider) {
        if let coverView = self.coverView {
            DZMUserDefaults.setFloat(Float(coverView.alpha), key: ReaderBrightnessKey)
        }
    }
    
    private func initTopView() {
        
        topView = ReaderTopView.loadView(readMenu: self)
        
        topView.isHidden = !menuShow
        
        vc.view.addSubview(topView)
        
        topView.frame = CGRect(x: 0, y: -NavgationBarHeight, width: ScreenWidth, height: NavgationBarHeight)
        
        topView.backBtn.addTarget(self, action: #selector(backButtonAction), for: .touchUpInside)
        
        topView.listenBtn.addTarget(self, action: #selector(catelogButtonAction(button:)), for: .touchUpInside)
    
        topView.shareBtn.rx.tap
            .mapToVoid()
            .subscribe(onNext: {[weak self] (_) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.hiddenchilidMenu()
                weakSelf.topView(isShow: true, complete: nil)
                weakSelf.bottomView(isShow: false, complete: nil)
                let shareVc = ReaderShareViewController(ShareViewModel(param: ["book_id": self?.vc.readModel.bookID ?? "", "content_id": self?.vc.readModel.readRecordModel.readChapterModel?.id ?? ""]))
                shareVc.modalPresentationStyle = .overCurrentContext
                weakSelf.vc.present(shareVc, animated: true, completion: nil)
            })
            .disposed(by: vc.bag)
        
        
        topView.mroeBtn.rx.tap
            .mapToVoid()
            .subscribe(onNext: {[weak self] (_) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.menu(isShow: true)
                let shareVc = ReaerPopMenuViewController(ReaderPopMenuViewModel(self?.vc.readModel.bookID ?? "", contentId: self?.vc.currentReadViewController?.readRecordModel?.readChapterModel?.id))
                shareVc.topInset = (self?.topView.frame.maxY ?? 80) + 10
                shareVc.modalPresentationStyle = .overCurrentContext
                shareVc.modalTransitionStyle = .crossDissolve
                shareVc.bookDetailOutput.subscribe(onNext: {(bookVm) in
                    shareVc.dismiss(animated: true, completion: {
                        weakSelf.vc.navigationController?.pushViewController(BookDetailViewController(bookVm), animated: false)
                    })
                })
                     .disposed(by: weakSelf.vc.bag)
                
                shareVc.reportOutput.subscribe(onNext: {(bookVm) in
                    shareVc.dismiss(animated: true, completion: {
                        weakSelf.vc.navigationController?.pushViewController(ChapterErrorReportViewController(bookVm), animated: false)
                    })
                })
                    .disposed(by: weakSelf.vc.bag)
                
                shareVc.downloadOutput.subscribe(onNext: {(bookVm) in
                    shareVc.dismiss(animated: true, completion: {
                        weakSelf.vc.navigationController?.pushViewController(ChooseChapterViewController(bookVm), animated: false)
                    })
                })
                    .disposed(by: weakSelf.vc.bag)
                
                shareVc.catelogOutput.subscribe(onNext: {(bookVm) in
                    shareVc.dismiss(animated: true, completion: {
                        weakSelf.vc.navigationController?.pushViewController(BookCatalogController(bookVm), animated: false)
                    })
                })
                    .disposed(by: weakSelf.vc.bag)

                weakSelf.vc.present(shareVc, animated: true, completion: nil)
            })
            .disposed(by: vc.bag)

    }
    
    private func initBottomView() {
        
        bottomView = ReaderBootomView.loadView(readMenu: self)
        
        bottomView.isHidden = !menuShow
        bottomView.frame = CGRect(x: 0, y: bottomViewY, width: UIScreen.main.bounds.width, height: BottomViewH)
        vc.view.addSubview(bottomView)
    }
    
     func bringSubToFont() {
        if let bannerView = bottomBanner {
            vc.view.bringSubviewToFront(bannerView)
        }
        vc.view.bringSubviewToFront(bottomView)
        vc.view.bringSubviewToFront(topView)
        vc.view.bringSubviewToFront(coverView)
        vc.view.bringSubviewToFront(novelsSettingView)
        vc.view.bringSubviewToFront(bookMarkView)
        vc.view.bringSubviewToFront(progressView)
        vc.view.bringSubviewToFront(lightView)
     
    }
    
    
    private var isAnimateComplete:Bool = true
    
    func menuSH() {
        menuSH(isShow: !menuShow)
    }
    

    func menuSH(isShow:Bool) {
        menu(isShow: isShow)
    }
    

    private func menu(isShow: Bool) {
        UIApplication.shared.setStatusBarStyle(isShow ? .lightContent: .default, animated: true)
        UIApplication.shared.setStatusBarHidden(!isShow, with: UIStatusBarAnimation.fade)
        if menuShow == isShow || !isAnimateComplete {return}
        isAnimateComplete = false
        menuShow = isShow
        delegate?.readMenuWillShowOrHidden?(readMenu: self, isShow: menuShow)
        
        bottomView(isShow: isShow, complete:nil)
        
        lightView(isShow: false, complete:nil)
        
        progressView(isShow: false, complete: nil)
        
        novelsSettingView(isShow: false, complete:nil)
        
        bookMarkView(isShow: false, complete:nil)
        
        topView(isShow: isShow) { [weak self] ()->Void in
            guard let weakSelf = self else {
                return
            }
            weakSelf.isAnimateComplete = true
            weakSelf.delegate?.readMenuDidShowOrHidden?(readMenu: self!, isShow: self!.menuShow)
        }
        
       
    }
    
    private func hiddenchilidMenu() {
        bookMarkView.isHidden = true
        lightView.isHidden = true
        progressView.isHidden = true
        novelsSettingView.isHidden = true
    }
    
    func topView(isShow:Bool,complete:(()->Void)?) {
        
        if topView.isHidden == !isShow {return}
        
        if isShow {topView.isHidden = false}
       
        UIView.animate(withDuration: animateDuration, animations: { [weak self] ()->Void in
            
            if isShow {
                
                self?.topView.frame = CGRect(x: 0, y: 0, width: ScreenWidth, height: NavgationBarHeight)
                
            }else{
                
                self?.topView.frame = CGRect(x: 0, y: -NavgationBarHeight, width: ScreenWidth, height: NavgationBarHeight)
            }
            
        }) {[weak self] (isOK) in
            
            if !isShow {self?.topView.isHidden = true}
            
            if complete != nil {complete!()}
        }
    }
    
    func bottomView(isShow:Bool,complete:(()->Void)?) {
        if isShow {
            bottomView.setSelected(false)
        }
        if bottomView.isHidden == !isShow {return}
        if isShow {bottomView.isHidden = false}
        UIView.animate(withDuration: animateDuration, animations: {  ()->Void in
            if isShow {
                if self.vc.readerMode.value.rawValue == ReaderMode.advertise.rawValue, self.bottomBanner != nil {
                    self.bottomView.frame.origin.y = self.bottomBanner!.frame.origin.y - self.BottomViewH
                } else {
                   self.bottomView.frame.origin.y = ScreenHeight - self.BottomViewH
                }
            }else{
                self.bottomView.frame.origin.y = ScreenHeight
            }
        }) {[weak self] (isOK) in
            if !isShow {self?.bottomView.isHidden = true}
            if complete != nil {complete!()}
        }
    }
    
    func lightView(isShow:Bool,complete:(()->Void)?) {
        hiddenchilidMenu()
        lightView.isHidden = !isShow
        UIView.animate(withDuration: animateDuration, animations: { [weak self] ()->Void in
            
            if isShow {
                self?.lightView.frame = CGRect(x: 0, y: (self!.bottomView.frame.origin.y) - self!.LightViewH, width: ScreenWidth, height: self!.LightViewH)
                
            }else{
                
                self?.lightView.frame = CGRect(x: 0, y: ScreenHeight, width: ScreenWidth, height: self!.LightViewH)
            }
            
        }) {[weak self] (isOK) in
            
            if !isShow {self?.lightView.isHidden = true}
            
            if complete != nil {complete!()}
        }
    }
    
    
    func novelsSettingView(isShow:Bool,complete:(()->Void)?) {
         hiddenchilidMenu()
        novelsSettingView.isHidden = !isShow
        UIView.animate(withDuration: animateDuration, animations: { [weak self] ()->Void in
            
            if isShow {
                self?.novelsSettingView.frame = CGRect(x: 0, y: self!.bottomView.frame.origin.y - self!.NovelsSettingViewH, width: ScreenWidth, height: self!.NovelsSettingViewH)
                
            }else{
                
                self?.novelsSettingView.frame = CGRect(x: 0, y: ScreenHeight, width: ScreenWidth, height: self!.NovelsSettingViewH)
            }
            
        }) {[weak self] (isOK) in
            
            if !isShow {self?.novelsSettingView.isHidden = true}
            
            if complete != nil {complete!()}
        }
    }
    
    func progressView(isShow: Bool, complete:(()->Void)?) {
         hiddenchilidMenu()
        progressView.isHidden = !isShow
        UIView.animate(withDuration: animateDuration, animations: { [weak self] ()->Void in
            if isShow {
                self?.progressView.frame = CGRect(x: 0, y: self!.bottomView.frame.origin.y - self!.progressViewH, width: ScreenWidth, height: self!.progressViewH)
            } else {
                self?.progressView.frame = CGRect(x: 0, y: ScreenHeight, width: ScreenWidth, height: self!.progressViewH)
            }
            
        }) {[weak self] (isOK) in
            
            if !isShow {self?.progressView.isHidden = true}
            
            if complete != nil {complete!()}
        }
    }
    
    
    
    func bookMarkView(isShow: Bool, complete:(()->Void)?) {
        hiddenchilidMenu()
        bookMarkView.isHidden = !isShow
        UIView.animate(withDuration: animateDuration, animations: { [weak self] ()->Void in
            if isShow {
                self?.bookMarkView.frame = CGRect(x: 0, y: self!.bottomView.frame.origin.y - self!.bookMarkViewH, width: ScreenWidth, height: self!.bookMarkViewH)
            } else {
                self?.bookMarkView.frame = CGRect(x: 0, y: ScreenHeight, width: ScreenWidth, height: self!.bookMarkViewH)
            }
            
        }) {[weak self] (isOK) in
            
            if !isShow {self?.bookMarkView.isHidden = true}
            
            if complete != nil {complete!()}
        }
    }
    
}
