//
//  BookShelfHomeViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/30.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import MXParallaxHeader
import RxSwift
import RxCocoa

enum BookShelfHeaderRefreshStatus: Int {
    case idle = 0
    case downPulling = 1
    case release = 2
    case refreshing = 3
}

class BookShelfHomeViewController: BaseViewController {
    struct UISize {
        static let headerHeight: CGFloat =  96 + 44 + 20 + UIApplication.shared.statusBarFrame.height
        static let headerNoRecordHeight: CGFloat = 85 + UIApplication.shared.statusBarFrame.height
    }
    var headerHeight: CGFloat =  UISize.headerHeight
    var heaerNavHeight: CGFloat = 44
    var headerTop: CGFloat = 0
   @IBOutlet weak var scrollView: MXScrollView!
    lazy var headerView: BookShelfHeaderView = {
        let headerView = BookShelfHeaderView.loadView()
        return headerView
    }()
    var shlefVC: BookShelfViewController?
    let refreshStatus: BehaviorRelay<BookShelfHeaderRefreshStatus> = .init(value: BookShelfHeaderRefreshStatus.idle)
    @IBOutlet weak var scrlolBottom: NSLayoutConstraint!
    fileprivate lazy var backTopBtn: DismissBtn = {
        let btn = DismissBtn()
        return btn
    }()
    
    fileprivate func configui() {
        scrollView.parallaxHeader.height = headerHeight
        scrollView.parallaxHeader.minimumHeight = heaerNavHeight + headerTop + UIApplication.shared.statusBarFrame.height
        scrollView.parallaxHeader.view = headerView
        scrollView.parallaxHeader.delegate = self
        scrollView.parallaxHeader.mode = MXParallaxHeaderMode.topFill
        scrollView.delegate = self
        scrollView.backgroundColor = .white
        if #available(iOS 11.0, *) {
              scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        
        view.addSubview(backTopBtn)
        backTopBtn.snp.makeConstraints { (maker) in
            maker.size.equalTo(CGSize(width: 70, height: 70 ))
            maker.right.equalTo(0)
            maker.bottom.equalTo(-49)
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configui()
        configViewModel()
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var frame = view.bounds
        scrollView.frame = frame
        scrollView.contentSize = frame.size
        scrollView.backgroundColor = .white
        frame.size.height -= scrollView.parallaxHeader.minimumHeight
        shlefVC!.view.frame = frame
        
    }
    
    private func configViewModel() {
        let viewModel = BookShelfViewModel()
        shlefVC = BookShelfViewController(viewModel)
        shlefVC!.didScroll = { [weak self] sv in
            guard let weakSelf = self else {
                return
            }
            if sv.panGestureRecognizer.velocity(in: weakSelf.scrollView).y > 0 {
                let height = -(sv.contentInset.top + sv.contentOffset.y )
                let isHidden = abs(Int(height)) < Int(weakSelf.view.bounds.height * 2 - weakSelf.scrollView.parallaxHeader.height)
                weakSelf.backTopBtn.hidden(isHidden)
            } else if  sv.panGestureRecognizer.velocity(in: weakSelf.scrollView).y < 0 {
                 weakSelf.backTopBtn.hidden(true)
            }
        }
        
        shlefVC!.didEndDrag = { [weak self] sv in
            guard let weakSelf = self else {
                return
            }
             weakSelf.backTopBtn.fireTimer()
        }
        
        backTopBtn.btnAction = { [weak self] in
            guard let weakSelf = self else {
                return
            }
            weakSelf.shlefVC?.collectionView.scrollToItem(at: IndexPath(item: 0, section: 0), at: UICollectionView.ScrollPosition.top, animated: true)
            weakSelf.scrollView.setContentOffset(CGPoint(x: 0, y: -weakSelf.scrollView.parallaxHeader.height), animated: true)
            weakSelf.backTopBtn.hidden(true)
        }
        addChild(shlefVC!)
        scrollView.addSubview(shlefVC!.view)
        backTopBtn.hidden(true)
        view.bringSubviewToFront(backTopBtn)
        
        self.headerView
            .recentBtn
            .rx
            .tap
            .bind(to: viewModel.recentlyMore)
            .disposed(by: bag)
        
        self.headerView
            .continueBtn
            .rx
            .tap
            .bind(to: viewModel.recentlyBook)
            .disposed(by: bag)
        
        self.headerView
            .searchBtn
            .rx
            .tap
            .bind(to: viewModel.searchAction)
            .disposed(by: bag)
        
        self.headerView
            .msgBtn
            .rx
            .tap
            .bind(to: viewModel.msgAction)
            .disposed(by: bag)
        
        self.headerView
            .adBtn
            .rx
            .tap
            .bind(to: viewModel.adAction)
            .disposed(by: bag)
        
        viewModel
            .recently
            .debug()
            .asDriver(onErrorJustReturn: nil)
            .drive(self.headerView.rx.info)
            .disposed(by: bag)
        
        
        viewModel
            .recentlyViewModel
            .subscribe(onNext: {
                let vc = RecentHomeViewController($0)
                navigator.push(vc)
            })
            .disposed(by: bag)
        
    
        
        viewModel.activityOutput
            .debug()
            .map { $0 == true ? BookShelfHeaderRefreshStatus.refreshing: BookShelfHeaderRefreshStatus.idle}
            .drive(refreshStatus)
            .disposed(by: bag)
        
        refreshStatus.asObservable()
            .bind(to: headerView.rx.refreshStatus)
            .disposed(by: bag)
        
        viewModel
            .endRefresh
            .map { BookShelfHeaderRefreshStatus.idle }
            .drive(refreshStatus)
            .disposed(by: bag)
        
        
        refreshStatus.asObservable()
            .debug()
            .filter { $0.rawValue == BookShelfHeaderRefreshStatus.release.rawValue }
            .mapToVoid()
            .bind(to: viewModel.headerRefresh)
            .disposed(by: bag)

        
        viewModel.activityOutput
            .debug()
            .drive(self.rx.loading)
            .disposed(by: bag)
        
        viewModel.exceptionOuptputDriver
            .drive(self.rx.exception)
            .disposed(by: bag)
        
        self.exception.asObservable()
            .mapToVoid()
            .bind(to: viewModel.exceptionInput)
            .disposed(by: bag)
        
        viewModel.messageCount
            .asObservable()
            .bind(to: self.headerView.rx.unReadmessageCount)
            .disposed(by: bag)
        
        viewModel.recently
            .debug()
            .observeOn(MainScheduler.instance)
            .asDriver(onErrorJustReturn: nil)
            .filter { $0 == nil }
            .drive(onNext: {[weak self] (_) in
                guard let weakSelf = self else {
                    return
                }
                 weakSelf.headerHeight = UISize.headerNoRecordHeight
                UIView.animate(withDuration: 0.25, animations: {
                    weakSelf.scrollView.parallaxHeader.height = UISize.headerNoRecordHeight
                })
            })
            .disposed(by: bag)
        
        
        viewModel.recently
            .filter { $0 != nil }
            .asObservable()
            .share(replay: 1)
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (_) in
                guard let weakSelf = self,  weakSelf.scrollView.parallaxHeader.height !=  UISize.headerHeight else {
                    return
                }
                weakSelf.headerHeight = UISize.headerHeight
                UIView.animate(withDuration: 0.25, animations: {
                    weakSelf.scrollView.parallaxHeader.height = UISize.headerHeight
                    weakSelf.scrollView.setContentOffset(CGPoint(x: 0, y: -UISize.headerHeight), animated: true)
                })
            })
            .disposed(by: bag)
 
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
 
    

}

extension BookShelfHomeViewController: MXScrollViewDelegate, MXParallaxHeaderDelegate {
    func scrollView(_ scrollView: MXScrollView, shouldScrollWithSubView subView: UIScrollView) -> Bool {
        return true
    }
    
    func parallaxHeaderDidScroll(_ parallaxHeader: MXParallaxHeader) {
        print("parallaxHeader - progress:\(parallaxHeader.progress) - velocity: \(scrollView.panGestureRecognizer.velocity(in: view).y) - offsetY:\(scrollView.contentOffset.y)")
        let headerProgress = parallaxHeader.progress
        let velocityY = scrollView.panGestureRecognizer.velocity(in: view).y
        if headerProgress > 1 { // 下拉
            if velocityY > 0 {
                if refreshStatus.value.rawValue != BookShelfHeaderRefreshStatus.refreshing.rawValue {
                    refreshStatus.accept(.downPulling)
                }
            } else if velocityY < 0 {
                if refreshStatus.value.rawValue != BookShelfHeaderRefreshStatus.refreshing.rawValue {
                    refreshStatus.accept(.idle)
                }
            } else {
                if refreshStatus.value.rawValue == BookShelfHeaderRefreshStatus.downPulling.rawValue {
                    refreshStatus.accept(.release)
                }
            }
        }
        
        let dis = headerHeight - headerView.navigationHeight.constant
        let height =  headerTop + headerView.navigationHeight.constant + dis * parallaxHeader.progress
        headerView.frame.size.height = height > headerHeight ? headerHeight: height
        headerView.lastView.alpha = parallaxHeader.progress
        let normalColor: (CGFloat, CGFloat, CGFloat) = (255, 255, 255)
        let selectColor: (CGFloat, CGFloat, CGFloat) = (59, 64, 67)
        let progress =  parallaxHeader.progress > 1 ? 1:  parallaxHeader.progress
        let colorDelta = (selectColor.0 - normalColor.0, selectColor.1 - normalColor.1, selectColor.2 - normalColor.2)
        headerView.backgroundColor = UIColor(red: (normalColor.0 + colorDelta.0 * CGFloat(progress)) / 255.0, green: (normalColor.1 + colorDelta.1 * CGFloat(progress)) / 255.0, blue: (normalColor.2 + colorDelta.2 * CGFloat(progress)) / 255.0, alpha: 1)
        
        let timeLabelNormalColor: (CGFloat, CGFloat, CGFloat) = (0, 0, 0)
        let timeLabelSelectColor: (CGFloat, CGFloat, CGFloat) = (255, 255, 255)
        let timeLabelColorDelta = (timeLabelSelectColor.0 - timeLabelNormalColor.0, timeLabelSelectColor.1 - timeLabelNormalColor.1, timeLabelSelectColor.2 - timeLabelNormalColor.2)
        headerView.timeLabel.textColor = UIColor(red: (timeLabelNormalColor.0 + timeLabelColorDelta.0 * CGFloat(progress)) / 255.0, green: (timeLabelNormalColor.1 + timeLabelColorDelta.1 * CGFloat(progress)) / 255.0, blue: (timeLabelNormalColor.2 + timeLabelColorDelta.2 * CGFloat(progress)) / 255.0, alpha: 1)
        
        
        if progress == 0  {
            UIView.animate(withDuration: Double(progress), animations: {
                self.headerView.msgBtn.setImage(UIImage(named: "xiaoxi2"), for: .normal)
                self.headerView.searchBtn.setImage(UIImage(named: "seach2"), for: .normal)
                self.headerView.adBtn.setImage(UIImage(named: "no_Ad2"), for: .normal)
                self.headerView.recentBtn.setImage(UIImage(named: "recent_1"), for: .normal)
                self.headerView.searchLabel.isHidden = true
                self.headerView.msgLabel.isHidden = true
                self.headerView.adLabel.isHidden = true
                self.headerView.recentLabel.isHidden = true
                self.headerView.sreadTimeDesc0.isHidden = false
                self.headerView.sreadTimeDesc1.isHidden = false
                self.headerView.readTimeDesc.isHidden = true
                self.headerView.timeLabelCenter.constant = 20
            })
        } else if progress > 0  {
            UIView.animate(withDuration: Double(progress), animations: {
                self.headerView.msgBtn.setImage(UIImage(named: "xiaoxi"), for: .normal)
                self.headerView.searchBtn.setImage(UIImage(named: "seach"), for: .normal)
                self.headerView.adBtn.setImage(UIImage(named: "no_ad"), for: .normal)
                self.headerView.recentBtn.setImage(UIImage(named: "recent"), for: .normal)
                self.headerView.searchLabel.isHidden = false
                self.headerView.msgLabel.isHidden = false
                self.headerView.adLabel.isHidden = false
                self.headerView.recentLabel.isHidden = false
                self.headerView.sreadTimeDesc0.isHidden = true
                self.headerView.sreadTimeDesc1.isHidden = true
                self.headerView.readTimeDesc.isHidden = false
                self.headerView.timeLabelCenter.constant = 0
            })
        }
    }
}



