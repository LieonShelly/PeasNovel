//
//  ReaderLastPageViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/13.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxDataSources
import RxSwift
import RxCocoa
import RxSwiftExt
import PKHUD
import AVFoundation

class ReaderLastPageViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    let shackingInput: PublishSubject<String> = .init()
    let motionInput: PublishSubject<String> = .init()
    let returnbookShelfInput: PublishSubject<Void> = .init()
    let updateBtnOutput: PublishSubject<Bool> = .init()
    
   lazy fileprivate var dataSource = RxTableViewSectionedReloadDataSource<SectionModel<RaderLastPageSectionType, ReaderLastPageGuessBook>>(configureCell: { [weak self](dataSource, tableView, indexPath, item) -> UITableViewCell in
        let sectionType = dataSource.sectionModels[indexPath.section].model
        switch sectionType {
        case .bookDetail(let detailModel):
            if let bookInfo = detailModel.book_info {
                switch bookInfo.writing_process {
                case .serializing:
                    let cell = tableView.dequeueCell(ReaderLastPageUnfinishTableViewCell.self, for: indexPath)
                    cell.contentView.backgroundColor = UIColor(0xE6DBBF)
                    cell.updateBtn.isSelected = detailModel.isAddBookNoti
                    if let weakSelf = self {
                        cell.backBookShelfOutput
                            .asObservable()
                            .bind(to: weakSelf.returnbookShelfInput)
                            .disposed(by: cell.bag)
                        
                        cell.updateBtnOutput
                            .asObservable()
                            .bind(to: weakSelf.updateBtnOutput)
                            .disposed(by: cell.bag)
                    }
                    cell.selectionStyle = .none
                    return cell
                case .completion:
                    let cell = tableView.dequeueCell(ReaderLastPageFinishTableViewCell.self, for: indexPath)
                    cell.contentView.backgroundColor = UIColor(0xE6DBBF)
                    if let weakSelf = self {
                        cell.btns[0].rx.tap.mapToVoid()
                            .bind(to: weakSelf.returnbookShelfInput)
                            .disposed(by: cell.bag)
                    }
                     cell.selectionStyle = .none
                    return cell
                }
            }
        case .shaking(let status):
            let cell = tableView.dequeueCell(RaderLastPageShakeTableViewCell.self, for: indexPath)
            cell.configStatus(status)
            if let weakSelf = self {
                cell.btn.rx.tap.map {""}
                    .bind(to: weakSelf.shackingInput)
                    .disposed(by: cell.bag)
                 cell.selectionStyle = .none
            }
            return cell
        case .guessLike(let books):
            let cell = tableView.dequeueCell(ReaderLastPageCollectionTableViewCell.self, for: indexPath)
            cell.contentView.backgroundColor = UIColor(0xE6DBBF)
            cell.config(books)
            cell.selectionStyle = .none
            return cell
        }
        return tableView.dequeueCell(UITableViewCell.self, for: indexPath)
    })
    
    fileprivate lazy var audioPlayer: AVPlayer = {
        let audioPlayer = AVPlayer()
        return audioPlayer
    }()
    
    var shakingStartAudio: AVPlayerItem {
        if let path = Bundle.main.path(forResource: "shake_sound_male", ofType: "mp3") {
            let audioItem = AVPlayerItem(url: URL(fileURLWithPath: path, isDirectory: false))
            return audioItem
        }
        return AVPlayerItem(asset: AVAsset())
    }
    
    var shakingMatchAudio: AVPlayerItem {
        if let path = Bundle.main.path(forResource: "shake_match", ofType: "mp3") {
            let audioItem = AVPlayerItem(url: URL(fileURLWithPath: path, isDirectory: false))
            return audioItem
        }
        return AVPlayerItem(asset: AVAsset())
    }
    
    var shakingUnMatchAudio: AVPlayerItem {
        if let path = Bundle.main.path(forResource: "shake_nomatch", ofType: "mp3") {
            let audioItem = AVPlayerItem(url: URL(fileURLWithPath: path, isDirectory: false))
            return audioItem
        }
        return AVPlayerItem(asset: AVAsset())
    }
    
    let shakingResult: BehaviorRelay<[ReaderLastPageGuessBook]> = .init(value: [])
    let shakingStatus = BehaviorRelay<ShakingStatus>(value: .normal)
    var bottomBanner: UIView?
    

    convenience init(_ viewModel: ReaderLastPageViewModel) {
        self.init(nibName: "ReaderLastPageViewController", bundle: nil)
        self.rx.viewDidLoad
            .subscribe(onNext: {[weak self] (_) in
                self?.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx.viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
        
    }
    
    private func config(_ viewModel: ReaderLastPageViewModel) {
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 100, right: 0)
         tableView.backgroundColor = UIColor(0xE6DBBF)
        tableView.registerNibWithCell(ReaderLastPageUnfinishTableViewCell.self)
        tableView.registerNibWithCell(RaderLastPageShakeTableViewCell.self)
        tableView.registerNibWithHeaderFooterView(ReaderlastPageSectionHeader.self)
        tableView.registerNibWithCell(ReaderLastPageCollectionTableViewCell.self)
        tableView.registerClassWithCell(UITableViewCell.self)
        tableView.registerNibWithCell(ReaderLastPageFinishTableViewCell.self)
        
        viewModel.dataDriver
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: bag)
        
        tableView.rx.setDelegate(self).disposed(by: bag)
       
        /// 点击按钮请求数据
        shackingInput.asObservable()
            .mapToVoid()
            .bind(to: viewModel.shackingInput)
            .disposed(by: bag)
        
        /// 点击按钮摇一摇动画
        shackingInput.asObservable()
             .mapToVoid()
            .subscribe(onNext: {[weak self] (_) in
                self?.shankinng()
            })
            .disposed(by: bag)
        
        updateBtnOutput.asObservable()
            .bind(to: viewModel.updateBtnOutput)
            .disposed(by: bag)
        
        /// 摇动手机
        motionInput.asObservable()
            .mapToVoid()
            .bind(to: viewModel.shackingInput)
            .disposed(by: bag)

        returnbookShelfInput.asObservable()
            .map { TabBarController()}
            .subscribe(onNext: {[weak self] rootVC in
                guard let weakSelf = self, let rootVC = UIApplication.shared.keyWindow?.rootViewController as? TabBarController else { return }
                rootVC.selectedIndex = 0
               let vccs = weakSelf.navigationController?.popToRootViewController(animated: true)
                for vcc in vccs ?? [] {
                    if let vc = vcc as? BaseViewController {
                        vc.bag = DisposeBag()
                    }
                }
            })
            .disposed(by: bag)
        
        viewModel.messageOutput
            .asObservable()
            .bind(to: HUD.flash)
            .disposed(by: bag)
        
        viewModel.shakingOutput
            .asObservable()
            .bind(to: shakingResult)
            .disposed(by: bag)
        
        shakingStatus.asObservable()
            .bind(to: viewModel.shakingStatus)
            .disposed(by: bag)
        
        viewModel.bannerOutput
            .asObservable()
            .unwrap()
            .subscribe(onNext: { [weak self](config) in
                guard let weakSelf = self else {
                    return
                }
                let isFiveNoAd: Bool = ReaderFiveChapterNoAd.isReadFiveAd()
                if !isFiveNoAd {
                    let bannerView = weakSelf.setupBottombannr(config.localConfig)
                    ViewBannerSerVice.configData(config, bannerView: bannerView)
                }
            })
            .disposed(by: bag)
        
        viewModel.bannerConfigOutput
            .asObservable()
            .unwrap()
            .filter { $0.ad_type == AdvertiseType.GDT.rawValue }
            .subscribe(onNext: { [weak self](config) in
                guard let weakSelf = self else {
                    return
                }
                let gdtViewModel = GDTBannerViewModel(config, viewController: weakSelf)
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
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
      
    }
    
    fileprivate func setupBottombannr(_ config: LocalAdvertise) -> UIView? {
        
        guard let  bottomBanner =  ViewBannerSerVice.chooseBanner(config, bannerFrame: CGRect(x: 0, y: UIScreen.main.bounds.height - 75 - UIDevice.current.safeAreaInsets.bottom, width: UIScreen.main.bounds.width , height: 75 +  UIDevice.current.safeAreaInsets.bottom)) else {
            return nil
        }
        if  self.bottomBanner != nil {
           self.bottomBanner?.removeFromSuperview()
        }
        self.bottomBanner = bottomBanner
        bottomBanner.backgroundColor = DZMReadConfigure.shared().readColor()
        if let bottom = bottomBanner as? IMBannerView {
            bottom.isDefaultCloseAction.accept(false)
            bottom.closeBtn.rx.tap.mapToVoid()
                .subscribe(onNext: { (_) in
                    NotificationCenter.default.post(name: Notification.Name.UIUpdate.readerCloseAd, object: nil)
                })
                .disposed(by: bag)
        }
        if let bottom = bottomBanner as? BUNativeBannerView {
            bottom.isDefaultCloseAction.accept(false)
            bottom.closeBtn.rx.tap.mapToVoid()
                .subscribe(onNext: { (_) in
                    NotificationCenter.default.post(name: Notification.Name.UIUpdate.readerCloseAd, object: nil)
                })
                .disposed(by: bag)
        }
        view.addSubview(bottomBanner)
        bottomBanner.snp.makeConstraints {
            $0.left.right.equalTo(0)
            $0.height.equalTo(75)
            $0.bottom.equalTo(-UIDevice.current.safeAreaInsets.bottom)
        }
        return bottomBanner
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
        UIApplication.shared.applicationSupportsShakeToEdit = true
        becomeFirstResponder()
    }
    

    fileprivate func shankinng() {
        let idx = IndexPath(row: 0, section: 1)
        guard let cell = tableView.cellForRow(at: idx) as? RaderLastPageShakeTableViewCell else {
            return
        }
        cell.startAnima(upCompletion: {
            
        }) {
            cell.configStatus(ShakingStatus.shakingDone(!self.shakingResult.value.isEmpty))
            self.shakingStatus.accept(ShakingStatus.shakingDone(!self.shakingResult.value.isEmpty))
            if !self.shakingResult.value.isEmpty {
                let vm = ReaderShakingViewModel()
                self.shakingResult.asObservable()
                    .bind(to: vm.outterBookList)
                    .disposed(by:self.bag)
                let vcc = ReaderShakingViewController(vm)
                self.navigationController?.pushViewController(vcc, animated: true)
            }
        }
        
    }

}

extension ReaderLastPageViewController: AVAudioPlayerDelegate {
    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            print("Motion-BEGIN")
            audioPlayer.replaceCurrentItem(with:shakingStartAudio)
            audioPlayer.play()
            motionInput.onNext("")
            shankinng()
            
        }
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if shakingResult.value.isEmpty {
             audioPlayer.replaceCurrentItem(with: shakingMatchAudio)
        } else {
            audioPlayer.replaceCurrentItem(with: shakingUnMatchAudio)
        }
        audioPlayer.play()
    }
    
    override func motionCancelled(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        
    }
}
extension ReaderLastPageViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionType = dataSource.sectionModels[indexPath.section].model
        switch sectionType {
        case .bookDetail(let detailModel):
            if let bookInfo = detailModel.book_info {
                switch bookInfo.writing_process {
                case .serializing:
                    return 190
                case .completion:
                    return 180
                }
            }
        case .shaking:
            return 180
        case .guessLike:
            let minInterSpace: CGFloat = 16
            let inset: CGFloat = 16
            let labelheight: CGFloat = 35
            let width: CGFloat = 88
            let rowHeight: CGFloat = width * 116 / 88.0 + minInterSpace + inset + labelheight
            return rowHeight
        }
        return 0
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueHeaderFooterView(ReaderlastPageSectionHeader.self)
        let sectionType = dataSource.sectionModels[section].model
        switch sectionType {
        case .guessLike:
            headerView.contentView.backgroundColor = UIColor(0xE6DBBF)
             return headerView
        default:
            return nil
        }
       
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let sectionType = dataSource.sectionModels[section].model
        switch sectionType {
        case .guessLike:
            return 44
        default:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: CGRect(x: 0, y: 00, width: UIScreen.main.bounds.width, height: 0.001))
    }
}
