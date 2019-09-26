//
//  BookDetailViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/2.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import SnapKit
import PKHUD

class BookDetailViewController: BaseViewController {
    @IBOutlet weak var navContainer: UIView!
    @IBOutlet weak var bottomHeight: NSLayoutConstraint!
    
    @IBOutlet weak var blackGraientView: GradientView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var backgroundImageView: UIImageView!
    @IBOutlet weak var gradientImageView: UIImageView!
    /// nav
    @IBOutlet weak var popButton: UIButton!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var navigationView: UIView!
    /// bottom
    @IBOutlet weak var addButton: UIButton!
    @IBOutlet weak var freeReadButton: UIButton!
    @IBOutlet weak var downloadButton: UIButton!
    /// constraint
    @IBOutlet weak var bgImageBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var statusBarConstraint: NSLayoutConstraint!
    
    /// rx
    let introCellAction = PublishSubject<Bool>.init()
    
    fileprivate var currentOffsetY: CGFloat = 0
    
    lazy var dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, Any>>(configureCell: {[unowned self] _ ,tv, ip, model in
        
        if let item = model as? LocalTempAdConfig {
            let cell = TableViewCellBannerService.chooseCell(item, tableView: tv, indexPath: ip)
            return cell
        }
        if let item = model as? BookInfo {
            let cell = tv .dequeueCell(BookDetailIntroTableViewCell.self, for: ip)
            cell.set(item)
            cell.openAction
                .bind(to: self.introCellAction)
                .disposed(by: cell.bag)
            return cell
        }
        if let item = model as? BookChapterInfo {
            let cell = tv .dequeueCell(BookDetailDirectoyTableViewCell.self, for: ip)
            cell.set(item)
            return cell
        }
        if let item = model as? BookInfoSimple {
            let cell = tv .dequeueCell(BookDetailCoverRightCell.self, for: ip)
            cell.set(simple: item)
            return cell
        }
        if let item = model as? BookSheetModel {
            let cell = tv .dequeueCell(BookDetailRightTableViewCell.self, for: ip)
            cell.set(item)
            return cell
        }
        if let item = model as? BookLicense {
            let cell = tv .dequeueCell(BookDetailMoreInfoTableViewCell.self, for: ip)
            cell.set(item)
            return cell
        }
        return UITableViewCell()
    })
    
    
    convenience init(_ viewModel: BookDetailViewModel) {
        self.init(nibName: "BookDetailViewController", bundle: nil)
        
        self.rx
            .viewDidLoad
            .subscribe(onNext: { [unowned self] in
                self.configUI()
                self.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx
            .viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
    }

    private func config(_ viewModel: BookDetailViewModel) {
        
        self.introCellAction
            .bind(to: viewModel.openIntroAction)
            .disposed(by: bag)
        
        self.introCellAction
            .mapToVoid()
            .subscribe(onNext: { (_) in
                self.tableView.reloadRows(at: [IndexPath(row: 0, section: 0)], with: UITableView.RowAnimation.fade)
            })
            .disposed(by: bag)
        
        popButton
            .rx
            .tap
            .asObservable()
            .subscribe(onNext: { [unowned self] in
                self.navigationController?.popViewController(animated: true)
            })
            .disposed(by: bag)
        
        tableView
            .rx
            .modelSelected(Any.self)
            .bind(to: viewModel.itemSelected)
            .disposed(by: bag)
        
        addButton
            .rx
            .tap
            .bind(to: viewModel.addBookshelfAction)
            .disposed(by: bag)
        
        freeReadButton
            .rx
            .tap
            .bind(to: viewModel.freeReadAction)
            .disposed(by: bag)
        
        downloadButton
            .rx
            .tap
            .bind(to: viewModel.downloadAction)
            .disposed(by: bag)
        
        viewModel
            .section
            .bind(to:self.tableView.rx.items(dataSource: self.dataSource))
            .disposed(by: bag)
        
        
        viewModel
            .coverImage
            .drive(self.backgroundImageView.rx.image)
            .disposed(by: bag)
        
        viewModel
            .isAddedStatus
            .not()
            .drive(self.addButton.rx.isEnabled)
            .disposed(by: bag)
        
        viewModel
            .isDownloadedStatus
            .drive(self.downloadButton.rx.isEnabled)
            .disposed(by: bag)
        
        viewModel
            .downloadOutput
            .drive(onNext: { [weak self] in
                self?.navigationController?.pushViewController(ChooseChapterViewController($0), animated: true)
            })
            .disposed(by: bag)
        
        viewModel
            .lastestChapter
            .subscribe(onNext: {
                BookReaderHandler.jump($0.book_id ?? "", contentId: $0.content_id, toReader: true)
            })
            .disposed(by: bag)
        
        viewModel
            .bookSheetDetail
            .subscribe(onNext: {
                navigator.push($0.router, context: $0)
            })
            .disposed(by: bag)
        
        viewModel
            .bookReader
            .subscribe(onNext: {
                 BookReaderHandler.jump($0.0.book_id, contentId: $0.0.content_id, toReader: true)
            })
            .disposed(by: bag)
        
        /// hud
        viewModel
            .activityDriver
            .drive(HUD.loading)
            .disposed(by: bag)
        
        viewModel
            .errorDriver
            .drive(HUD.flash)
            .disposed(by: bag)
        
        viewModel.bannerConfigoutput
            .asObservable()
            .unwrap()
            .filter { $0.ad_type == AdvertiseType.GDT.rawValue}
            .subscribe(onNext: {[weak self] (config) in
                guard let weakSelf = self else {
                    return
                }
                let gdtViewModel = GDTBannerViewModel(config, viewController: weakSelf)
                gdtViewModel.nativeAdOutput
                    .subscribe(onNext: { (gdtView) in
                        viewModel.bannerOutput.onNext(LocalTempAdConfig(config, adType: .GDT(gdtView)))
                    }, onError: { (error) in
                        viewModel.bannerOutput.onNext(nil)
                    })
                    .disposed(by: weakSelf.bag)
                 viewModel.bannenrViewModel = gdtViewModel
            })
            .disposed(by: bag)
        
        viewModel.bannerConfigoutput
            .asObservable()
            .unwrap()
            .filter { $0.ad_type == AdvertiseType.todayHeadeline.rawValue}
            .subscribe(onNext: {[weak self] (config) in
                guard let weakSelf = self else {
                    return
                }
                let buViewModel = BUNativeBannerViewModel(config, isAutoRefresh: false, viewController: weakSelf)
                buViewModel.nativeAdOutput
                    .subscribe(onNext: { (gdtView) in
                        viewModel.bannerOutput.onNext(LocalTempAdConfig(config, adType: .todayHeadeline(gdtView)))
                    }, onError: { (error) in
                        viewModel.bannerOutput.onNext(nil)
                    })
                    .disposed(by: weakSelf.bag)
                 viewModel.bannenrViewModel = buViewModel
            })
            .disposed(by: bag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if #available(iOS 11.0, *) {
            statusBarConstraint.constant = view.safeAreaInsets.top
        }
        
    }
    
    private func configUI() {
        tableView.registerNibWithCell(BookDetailRightTableViewCell.self)
        tableView.registerNibWithCell(BookDetailIntroTableViewCell.self)
        tableView.registerNibWithCell(BookDetailDirectoyTableViewCell.self)
        tableView.registerNibWithCell(IMBannerTableViewCell.self)
        tableView.registerNibWithCell(BookDetailMoreInfoTableViewCell.self)
        tableView.registerNibWithCell(BookDetailCoverRightCell.self)
        tableView.registerNibWithHeaderFooterView(TextTableViewSectionHeader.self)
        tableView.registerNibWithCell(GDTBannerTableViewCell.self)
        tableView.registerNibWithCell(BUBannerTableViewCell.self)
        
        tableView.rx.setDelegate(self).disposed(by: bag)
        bottomHeight.constant = 55
        tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: UIDevice.current.safeAreaInsets.bottom + 65, right: 0)
        tableView.tableHeaderView = UIView(frame: CGRect(origin: CGPoint.zero,
                                                         size: CGSize(width: 0, height: 0.1)))
        tableView.tableFooterView = UIView(frame: CGRect(origin: CGPoint.zero,
                                                         size: CGSize(width: 0, height: 0.1)))
        
        
        blackGraientView.colors = [UIColor.black.withAlphaComponent(0.5), UIColor(0xffffff)]
        blackGraientView.locations = [0.8, 1.0]
        blackGraientView.direction = .horizontal
        blackGraientView.topBorderColor = UIColor.black.withAlphaComponent(0.5)
        blackGraientView.bottomBorderColor = .white
        
    }
}

extension BookDetailViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 0, indexPath.row == 0 {
            return 164 + 14 + 60
        } else if indexPath.section == 0, indexPath.row == 1 {
            return 55
        } else {
            let sectionModel = dataSource.sectionModels[indexPath.section]
            if sectionModel.model == "广告" {
                return 75
            }
            return 144
        }
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if dataSource.sectionModels.count <= indexPath.section {
            return 0.001
        }
        let sectionModel = dataSource.sectionModels[indexPath.section]
        if sectionModel.model == "广告" {
            return 75
        }
        return UITableView.automaticDimension
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if dataSource.sectionModels.count <= section {
            return 0.001
        }
        let sectionModel = dataSource.sectionModels[section]
        if sectionModel.model == "广告" {
            return 0.001
        }
     
        if sectionModel.model.length > 0 {
            return 70
        }else {
            return 0.001
        }
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if section >= 1 {
            if dataSource.sectionModels.count <= section {
                return 0.001
            }
            let sectionModel = dataSource.sectionModels[section]
            if sectionModel.model == "图书更多信息" {
                return 0.001
            }
            return 10
        }
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueHeaderFooterView(TextTableViewSectionHeader.self)
        header.backgroundView?.backgroundColor = UIColor.white
        if dataSource.sectionModels.count <= section {
            return header
        }else if dataSource.sectionModels[section].model != "广告" {
            let sectionModel = dataSource.sectionModels[section]
            header.titleLabel.text = sectionModel.model
            return header
        }
        return nil
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = UIView()
        footer.backgroundColor = UIColor(0xF4F6F9)
        return footer
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offsetY = scrollView.contentOffset.y
        debugPrint("scrollViewDidScroll:\(offsetY)")
        currentOffsetY = offsetY
        bgImageBottomConstraint.constant = (offsetY <= 150) ? (offsetY - 150) : 0
        titleLabel.isHidden = offsetY <= 44

        if  titleLabel.isHidden {
            navigationView.backgroundColor = UIColor.clear
            navContainer.backgroundColor = UIColor.clear
        } else {
             navigationView.backgroundColor = UIColor.white
            navContainer.backgroundColor = UIColor.white
        }
    }
}
