//
//  SearchViewController.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/16.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import PKHUD

class SearchViewController: BaseViewController {
    @IBOutlet weak var fuzzyTableView: UITableView!
    
    @IBOutlet weak var tableViewTop: NSLayoutConstraint!
    @IBOutlet weak var searchField: UITextField!
    @IBOutlet weak var tableView: UITableView!
    
    let searchAction: PublishSubject<String?> = .init()
    let fuzzyInput: PublishSubject<String?> = .init()
    let beginInput: PublishSubject<Void> = .init()
    
    let hotItemSelected: PublishSubject<SearchHotModel> = .init()
    let firstItemAction: PublishSubject<Int> = .init()  // 第一个cell上按钮事件
    let netSearchAction: PublishSubject<Void> = .init()  // 第一个cell上按钮事件
    let historyClearAction: PublishSubject<Void> = .init()  // 清除历史记录
    
    lazy var dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String?, Any>>(configureCell: {[unowned self] _, tv, ip, model in
        if let model = model as? [SearchHotModel] {
            let cell = tv.dequeueCell(SearchHotTableViewCell.self, for: ip)
            cell.config(model)
            cell.itemSelected
                .bind(to: self.hotItemSelected)
                .disposed(by: cell.bag)
            
            cell.itemSelected
                .map{ $0.title }
                .bind(to: self.searchAction)
                .disposed(by: cell.bag)
            return cell
        }
        if let model = model as? BookInfo, ip.section == 0{
            let cell = tv.dequeueCell(SearchFirstResultTableViewCell.self, for: ip)
            cell.set(model)
            cell.buttonAction
                .bind(to: self.firstItemAction)
                .disposed(by: cell.bag)
            return cell
        }
        if let model = model as? BookInfo {
            let cell = tv.dequeueCell(BookDetailCoverRightCell.self, for: ip)
            cell.set(model)
            return cell
        }
        if let model = model as? SearchWebSwitchModel {
            let cell = tv.dequeueCell(SogouEnterTableViewCell.self, for: ip)
            cell.selectionStyle = .none
            cell.btm
                .rx
                .tap
                .bind(to: self.netSearchAction)
                .disposed(by: cell.bag)
            return cell
        }
        if let item = model as? LocalTempAdConfig {
            let cell = TableViewCellBannerService.chooseCell(item, tableView: tv, indexPath: ip)
            return cell
        }
        if let model = model as? [SearchKeyModel] {
            let cell = tv.dequeueCell(SearchHistoryTableViewCell.self, for: ip)
            cell.set(model)
            cell.tagTapped
                .bind(to: self.searchAction)
                .disposed(by: cell.bag)
            return cell
        }
        return UITableViewCell()
    })
    
    convenience init(_ viewModel: SearchViewModel) {
        self.init(nibName: "SearchViewController", bundle: nil)
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
        
        self.rx
            .viewWillAppear
            .bind(to: viewModel.viewWillAppear)
            .disposed(by: bag)
        
        self.rx
            .viewWillDisappear
            .bind(to: viewModel.viewWillDisappear)
            .disposed(by: bag)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    func config(_ viewModel: SearchViewModel) {
        tableViewTop.constant = UIApplication.shared.statusBarFrame.height + ( navigationController?.navigationBar.frame.height ?? 44)
        searchAction
            .bind(to: viewModel.searchAction)
            .disposed(by: bag)
        
        beginInput
            .bind(to: viewModel.textFieldActive)
            .disposed(by: bag)
        
        historyClearAction
            .bind(to: viewModel.historyClearAction)
            .disposed(by: bag)
        
        tableView
            .rx
            .modelSelected(Any.self)
            .bind(to: viewModel.itemDidSelected)
            .disposed(by: bag)
        
        tableView
            .mj_footer
            .rx
            .start
            .bind(to: viewModel.footerRefresh)
            .disposed(by: bag)
        
        firstItemAction
            .bind(to: viewModel.firstItemAction)
            .disposed(by: bag)
        
        netSearchAction
            .bind(to: viewModel.sogouSearchAction)
            .disposed(by: bag)
        
        hotItemSelected
            .bind(to: viewModel.hotItemSelected)
            .disposed(by: bag)
        
        viewModel
            .searchText
            .drive(self.searchField.rx.text)
            .disposed(by: bag)
        
        viewModel
            .defaultKeyword
            .subscribe(onNext: { [unowned self] in
                self.searchField.placeholder = $0
            })
            .disposed(by: bag)
        
        viewModel
            .sections
            .drive(self.tableView.rx.items(dataSource: self.dataSource))
            .disposed(by: bag)
        
        viewModel
            .itemOutput
            .subscribe(onNext: {
                BookReaderHandler.jump($0.book_id, contentId: $0.content_id)
            })
            .disposed(by: bag)
        
        viewModel
            .endMoreDaraRefresh
            .drive(tableView.mj_footer.rx.endNoMoreData)
            .disposed(by: bag)
        
        viewModel
            .catalogViewModel
            .subscribe(onNext: { [unowned self] in
                let vc = BookCatalogController($0)
                self.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: bag)
        
        viewModel
            .webViewModel
            .subscribe(onNext: { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                let vc = WebViewController($0)
                weakSelf.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: bag)
        
        viewModel.sogouViewModel
            .subscribe(onNext: { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                let vc = SogouWebViewController($0)
                weakSelf.navigationController?.pushViewController(vc, animated: true)
            })
            .disposed(by: bag)
        
        viewModel
            .activityDriver
            .drive(HUD.loading)
            .disposed(by: bag)
        
        viewModel
            .errorDriver
            .drive(HUD.flash)
            .disposed(by: bag)
        
        viewModel
            .tipHud
            .drive(HUD.flash)
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(UITextField.textDidChangeNotification, object: searchField)
            .subscribe(onNext: { [weak self](note) in
                if let textField = note.object as? UITextField, let text = textField.text {
                    self?.fuzzyInput.onNext(text)
                }
            })
            .disposed(by: bag)
        
        let textField = self.searchField
        viewModel.fuzzyResults
            .asObservable()
            .bind(to: fuzzyTableView.rx.items(cellIdentifier: String(describing: FuzzyTableViewCell.self), cellType: FuzzyTableViewCell.self)) { (row, element, cell) in
                cell.config(element.book_title ?? "", keyword: textField?.text ?? "")
            }
            .disposed(by: bag)
        
        fuzzyTableView.rx.modelSelected(BookInfo.self)
            .map { $0.book_title }
            .unwrap()
            .bind(to: searchAction)
            .disposed(by: bag)
        
        fuzzyInput.asObservable()
            .unwrap()
            .bind(to: viewModel.fuzzyInput)
            .disposed(by: bag)
        
        viewModel.fuzzyResults
            .asObservable()
            .map { $0.isEmpty }
            .bind(to: fuzzyTableView.rx.isHidden)
            .disposed(by: bag)
        
        viewModel.fuzzyResults
            .asObservable()
            .map { !$0.isEmpty }
            .bind(to: tableView.rx.isHidden)
            .disposed(by: bag)
        
        loadAd(viewModel)
    }
    
    
    
    func loadAd(_ viewModel: SearchViewModel) {
        viewModel.bannerOutput
            .subscribeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] (config) in
                    self?.tableView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
                    guard let weakSelf = self else {
                        return
                    }
                    let topBanner = weakSelf.setupBottombannr(config.localConfig)
                    ViewBannerSerVice.configData(config, bannerView: topBanner)
                })
            .disposed(by: bag)
        
        viewModel
            .bannerConfigoutput
            .asObservable()
            .unwrap()
            .filter { !$0.is_close}
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
        
        viewModel
            .bannerConfigoutput
            .asObservable()
            .unwrap()
            .filter { !$0.is_close}
            .filter { $0.ad_type == AdvertiseType.todayHeadeline.rawValue }
            .subscribe(onNext: { [weak self](config) in
                guard let weakSelf = self else {
                    return
                }
                let buViewModel = BUNativeBannerViewModel(config, viewController: weakSelf)
                buViewModel.nativeAdOutput
                    .asObservable()
                    .map { LocalTempAdConfig(config, adType: .todayHeadeline($0))}
                    .bind(to: viewModel.bannerOutput)
                    .disposed(by: viewModel.bag)
                viewModel.bannerViewModel = buViewModel
            })
            .disposed(by: bag)
    }
    
    
    func configUI() {
        searchField.delegate = self
        tableView.estimatedRowHeight = 100
        tableView.delegate = self
        fuzzyTableView.delegate = self
        tableView.registerNibWithCell(SearchHotTableViewCell.self)
        tableView.registerNibWithCell(SearchFirstResultTableViewCell.self)
        tableView.registerNibWithCell(SearchEmptyWithNetPageTableViewCell.self)
        tableView.registerNibWithCell(BookDetailCoverRightCell.self)
        tableView.registerNibWithCell(SearchHistoryTableViewCell.self)
        tableView.registerNibWithHeaderFooterView(SearchHeaderView.self)
        tableView.registerNibWithCell(IMBannerTableViewCell.self)
        fuzzyTableView.registerNibWithCell(FuzzyTableViewCell.self)
        tableView.registerNibWithCell(SogouEnterTableViewCell.self)
        tableView.mj_footer = RefreshFooter()
        
    }
    
    fileprivate func setupBottombannr(_ config: LocalAdvertise) -> UIView? {
        
        guard let  topBanner =  ViewBannerSerVice.chooseBanner(config, bannerFrame: CGRect(x: 0, y: UIScreen.main.bounds.height - 75 - UIDevice.current.safeAreaInsets.bottom, width: UIScreen.main.bounds.width , height: 75 +  UIDevice.current.safeAreaInsets.bottom)) else {
            return nil
        }
        for subView in tableView.tableHeaderView?.subviews ?? [] {
            subView.removeFromSuperview()
        }
        let header = UIView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 75))
         header.addSubview(topBanner)
        tableView.tableHeaderView = header
        topBanner.snp.makeConstraints {
            $0.edges.equalTo(0)
        }
        return topBanner
    }
    
    

    @IBAction func cancelAction(_ sender: Any) {
        self.navigationController?.popViewController(animated: true)
    }
    
    deinit {
        print("SearchViewController deinit!!!")
    }
    
}

extension SearchViewController: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        searchAction
            .on(.next(textField.text))
        fuzzyInput.onNext("")
        textField.resignFirstResponder()
        return true
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        beginInput.on(.next(()))
    }
}

extension SearchViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if tableView == self.tableView {
            if let _ = dataSource.sectionModels[section].model {
                return 36
            }else{
                return 0.001
            }
        }
        return 0.001
      
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if tableView == self.tableView {
           return 5
        }
        return 0.001
        
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {

        if tableView == self.tableView {
            let header = tableView.dequeueHeaderFooterView(SearchHeaderView.self)
            if let title = dataSource.sectionModels[section].model {
                header.titleLabel.isHidden = title == "网页搜索"
                header.titleLabel.text = title
                header.clearButton.isHidden = (title != "历史搜索")
                header.clearButton
                    .rx
                    .tap
                    .bind(to: historyClearAction)
                    .disposed(by: bag)
                return header
            }else{
                return nil
            }
        }
         return nil
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        if tableView == self.tableView {
            let footer = UIView()
            footer.backgroundColor = UIColor(0xF4F6F9)
            return footer
        }
        return nil
   
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if tableView == self.tableView {
            if indexPath.section >= dataSource.sectionModels.count {
                return 0
            }
            let item = dataSource.sectionModels[indexPath.section].items[indexPath.row]
            if let _ = item as? SearchWebSwitchModel {
                return 44
            }
            return UITableView.automaticDimension
        }
        return 44
    }
}
