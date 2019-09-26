//
//  ChooseChapterViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/4.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxDataSources
import RxSwift
import RxCocoa
import RxSwiftExt
import PKHUD

class ChooseChapterViewController: BaseViewController {
    @IBOutlet weak var tableView: UITableView!
    let downloadInput: PublishSubject<DownloadChapterGroup> = .init()
    let retryBtnInput: PublishSubject<DownloadChapterGroup> = .init()
    let waitBtnInput: PublishSubject<DownloadChapterGroup> = .init()
    let unlockInput: PublishSubject<DownloadChapterGroup> = .init()
    var bottomBanner: UIView?
    
   lazy fileprivate var dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, DownloadChapterGroup>>(configureCell: { [weak self](dataSource, tableView, indexPath, item) -> UITableViewCell in
        let cell = tableView.dequeueCell(DownloadChapterTableViewCell.self, for: indexPath)
        cell.config(item)
        cell.selectionStyle = .none
        if let weakSelf = self {
            cell.downloadBtn.rx.tap.map {item}.bind(to: weakSelf.downloadInput).disposed(by: cell.bag)
            cell.retryBtn.rx.tap.map {item}.bind(to: weakSelf.retryBtnInput).disposed(by: cell.bag)
            cell.waitBtn.rx.tap.map {item}.bind(to: weakSelf.waitBtnInput).disposed(by: cell.bag)
            cell.unlockBtn.rx.tap.map {item}.bind(to: weakSelf.unlockInput).disposed(by: cell.bag)
        }
        return cell
    })
    
    convenience init(_ viewModel: ChooseChapterViewModel) {
        self.init(nibName: "ChooseChapterViewController", bundle: nil)
        self.rx.viewDidLoad
            .subscribe(onNext: {[weak self] (_) in
                self?.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx.viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
        
    }
    
    private func config(_ viewModel: ChooseChapterViewModel) {
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        title = "下载中心"
        let btn = UILabel()
        btn.textColor = UIColor(0x999999)
        btn.numberOfLines = 0
        btn.font = UIFont.systemFont(ofSize: 13)
        btn.attributedText = "每看一次完整视频，可解锁一组哦~~，点击解锁即可观看视频！（24小时有效）".withlineSpacing(5)
        let containerView = UIView()
        containerView.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 66)
        containerView.addSubview(btn)
        btn.snp.makeConstraints {
            $0.left.equalTo(14)
            $0.right.equalTo(-14)
            $0.top.equalTo(14)
        }
        tableView.tableHeaderView = containerView
        tableView.registerNibWithCell(DownloadChapterTableViewCell.self)
        tableView.registerNibWithHeaderFooterView(DownloadChapterHeaderView.self)
      
        tableView.rx.modelSelected(DownloadChapterGroup.self)
            .bind(to: viewModel.itemSelectInput)
            .disposed(by: bag)
        
        viewModel.dataDriver
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: bag)
        
        tableView.rx.setDelegate(self).disposed(by: bag)
        
        downloadInput.asObservable()
            .debug()
            .bind(to: viewModel.downloadInput)
            .disposed(by: bag)
        
        retryBtnInput.asObservable()
            .debug()
            .bind(to: viewModel.retryBtnInput)
            .disposed(by: bag)
        
        waitBtnInput.asObservable()
            .debug()
            .bind(to: viewModel.waitBtnInput)
            .disposed(by: bag)
        
        
        unlockInput.asObservable()
            .bind(to: viewModel.unlockInput)
            .disposed(by: bag)
        
        viewModel.itemSelectOutput
            .drive(onNext: { [weak self](vm) in
                self?.navigationController?.pushViewController(ReaderController(vm), animated: true)
            })
            .disposed(by: bag)
        
        viewModel.unlockOutput
            .asObservable()
            .map { RewardVideoService.chooseVC($0, isForceOpen: true) }
            .unwrap()
            .subscribe(onNext: {[weak self] in
                self?.present($0, animated: true, completion: nil)
            })
            .disposed(by: bag)
        
        viewModel.message
            .asObservable()
            .bind(to: HUD.flash)
            .disposed(by: bag)
        
        viewModel.bannerOutput
            .asObservable()
            .subscribe(onNext: {[weak self] (config) in
                guard let weakSelf = self else {
                    return
                }
                let bottomBanner = weakSelf.setupBottombannr(config.localConfig)
                ViewBannerSerVice.configData(config, bannerView: bottomBanner)
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
    
    fileprivate func setupBottombannr(_ config: LocalAdvertise) -> UIView? {
        guard let  bottomBanner =  ViewBannerSerVice.chooseBanner(config, bannerFrame: CGRect(x: 0, y: UIScreen.main.bounds.height - 75 - UIDevice.current.safeAreaInsets.bottom, width: UIScreen.main.bounds.width , height: 75 +  UIDevice.current.safeAreaInsets.bottom)) else {
            return nil
        }
        if self.bottomBanner != nil {
            self.bottomBanner?.removeFromSuperview()
        }
        self.bottomBanner = bottomBanner
        view.addSubview(bottomBanner)
        bottomBanner.snp.makeConstraints {
            $0.left.right.equalTo(0)
            $0.bottom.equalTo(-UIDevice.current.safeAreaInsets.bottom)
            $0.height.equalTo(75)
        }
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 75 +  UIDevice.current.safeAreaInsets.bottom, right: 0)
        return bottomBanner
    }
    
}

extension ChooseChapterViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 66
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerView = tableView.dequeueHeaderFooterView(DownloadChapterHeaderView.self)
        let sectionType = dataSource.sectionModels[section].model
        headerView.label.text = sectionType
        return headerView
        
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 66
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView(frame: CGRect(x: 0, y: 00, width: UIScreen.main.bounds.width, height: 0.001))
    }
}


