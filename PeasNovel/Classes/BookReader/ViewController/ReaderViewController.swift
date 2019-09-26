//
//  ReaderViewController.swift
//  ReaderKit
//
//  Created by lieon on 2017/5/12.
//  Copyright © 2018年lieon. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RealmSwift
import YYText
import Alamofire
import PKHUD

class ReaderViewController: BaseViewController {
    
    fileprivate lazy var viewModel: ReaderViewViewModel = ReaderViewViewModel()
    var adView: UIView?
    var readRecordModel: DZMReadRecordModel!
    weak var readController: ReaderController!
    private(set) lazy var statusBar: StatusBar = {
        let statusBar = StatusBar()
        statusBar.readRecordModel = readRecordModel
        return statusBar
    }()
    private(set) lazy var progressLabel: UILabel = {
        let label = UILabel()
        label.text = "本章进度20%"
        label.font = UIFont.size_12
        label.textColor = UIColor(0x333333, alpha: 1)
        return label
    }()
    private(set) var tableView: ReadTableView!


    override func loadView() {
        super.loadView()
        self.rx.viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
        
        self.rx.viewWillAppear
            .bind(to: viewModel.viewWillAppear)
            .disposed(by: bag)
        
        self.rx.viewWillDisappear
            .bind(to: viewModel.viewWillDisappear)
            .disposed(by: bag)
        
        self.rx.viewDidDisappear
            .bind(to: viewModel.viewDidDisappear)
            .disposed(by: bag)
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if readRecordModel.readChapterModel?.pageModels.isEmpty ?? false {
            readRecordModel.readChapterModel?.sepearatePage()
            readController.readRecordUpdate(readRecordModel: readRecordModel)
        }
        addSubviews()
        configureBGColor()
        configureReadEffect()
        addConstraint()
        tableView.allowsSelection = true
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        UIApplication.shared.setStatusBarStyle(.default, animated: true)
        UIApplication.shared.setStatusBarHidden(true, with: UIStatusBarAnimation.fade)
        
    }

    func addSubviews() {
        view.addSubview(statusBar)
        tableView = ReadTableView()
        tableView.backgroundColor = UIColor.clear
        tableView.showsVerticalScrollIndicator = false
        tableView.separatorStyle = .none
        tableView.delegate = self
        tableView.dataSource = self
        tableView.bounces = false
        tableView.estimatedRowHeight = 0
        tableView.estimatedSectionFooterHeight = 0
        tableView.estimatedSectionHeaderHeight = 0
        tableView.frame = GetReadTableViewFrame()
        view.addSubview(tableView)
        tableView.registerClassWithCell(UITableViewCell.self)
        tableView.registerClassWithCell(ReadViewTableViewCell.self)
        tableView.registerNibWithCell(ReaderInfoTableViewCell.self)
        tableView.registerNibWithCell(ReaderFullPicTableViewCell.self)
    }
    
    func addConstraint() {
        statusBar.snp.makeConstraints {
            $0.leading.equalToSuperview()
            $0.trailing.equalToSuperview()
            $0.top.equalTo(StatusBarHeight - 10)
            $0.height.equalTo(20)
        }
    }
    
    func configureBGColor() {
        view.backgroundColor = DZMReadConfigure.shared().readColor()
        tableView.reloadData()
    }
    
    func reload() {
        tableView.reloadData()
    }
    
    func configureReadEffect() {
        tableView.isScrollEnabled = true
        tableView.clipsToBounds = true
    }

}

extension ReaderViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        
        return GetReadTableViewFrame().height
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.01
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        readController.readMenu?.menuSH()
    }
    
}

extension ReaderViewController: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
         return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
          return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let chapterModel = readRecordModel.readChapterModel
        let page = readRecordModel.page
        if readRecordModel.isLastPage {
            NotificationCenter.default.post(name: NSNotification.Name.Book.chapaterIsLastpage, object: nil)
        }
        if (chapterModel?.id ?? "") == ReaderSpecialChapterValue.firstPageValue, let copyInfo = chapterModel?.cp_info {
            let cell = tableView.dequeueCell(ReaderInfoTableViewCell.self, for: indexPath)
            cell.config(copyInfo)
            return cell
        } else {
            guard let pageModel = chapterModel?.pageModel(page: page) else {
                return tableView.dequeueCell(UITableViewCell.self, for: indexPath)
            }
            switch pageModel.type {
            case .text:
                 let attchModel = chapterModel?.attachModel(with: page)
                 let cell = tableView.dequeueCell(ReadViewTableViewCell.self, for: indexPath)
                cell.config(pageModel, attchModel: attchModel, appendAttchViewHandler:{ [weak self] () -> (UIView?) in
                    guard let weakSelf = self else {
                        return nil
                    }
                    if weakSelf.readRecordModel.isLastPage {
                        let record = AdvertiseService.loadAdvertiseConfig(.readerChapterPageEndAd)
                        if let config = record.0,
                            !config.is_close,
                            !ReaderFiveChapterNoAd.isReadFiveAd() {
                            let infoView = ReaderPageAdView(ReaderPageAdViewModel(config))
                            if let weakSelf = self {
                                weakSelf.adView = infoView
                            }
                            return infoView
                        } else if let end_ad_num = CommomData.share.switcherConfig.value?.read_page_chapter_end_ad_num, end_ad_num != 0 {
                            let a0 = 0 + end_ad_num - 1
                            let d = end_ad_num
                            //                            let pageIndex = a0 + x * d
                            if (weakSelf.readController.currenntReadChapterCount.value - a0) % d == 0 { /// 能够被整除，说明已读章节数满足条件
                                let vm = ChapterTailBookViewModel(weakSelf.readRecordModel.bookID)
                                let bookView = ChaterTailBookCardView.loadView(vm)
                                let viewWidth = UIScreen.main.bounds.width - 16 * 2
                                let viewHeight = viewWidth / 2.0
                                bookView.frame = CGRect(x: 0, y: 0, width: viewWidth, height: viewHeight)
                                weakSelf.adView = bookView
                                bookView.tapButton
                                    .rx.tap
                                    .withLatestFrom(vm.bookInfo)
                                    .observeOn(MainScheduler.instance)
                                    .subscribe(onNext: {
                                        let vcc = SmallRederHomeViewController($0)
                                        weakSelf.parent!.parent!.addChild(vcc)
                                        vcc.view.frame = weakSelf.parent!.view.bounds
                                        weakSelf.parent!.parent!.view.addSubview(vcc.view)
                                        weakSelf.parent!.parent!.view.bringSubviewToFront(vcc.view)
                                    })
                                    .disposed(by: bookView.bag)
                                return bookView
                            }
                        }
                    }
                    return nil
                })
                return cell
            case .fullScreenAd(let viewModel):
                let cell = tableView.dequeueCell(ReaderFullPicTableViewCell.self, for: indexPath)
                cell.selectionStyle = .none
                var adUI = ReaderFullScreenAdUIConfig()
                adUI.holderVC = self
                cell.config(viewModel, adUIConfig: adUI)
                return cell
            }
           
        }
    }
    
}
