//
//  RankSubViewController.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/19.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxDataSources
import RxSwift
import PKHUD

class RankSubViewController: BaseViewController {

    @IBOutlet weak var tableView: UITableView!
    
    let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, RankModel>>(configureCell: {ds, tv, ip, model in
        let cell = tv.dequeueCell(RankTableViewCell.self, for: ip)
        let identify = ds[ip.section].model
        if identify == "click" {
            cell.set(model,
                     intro: model.author_name,
                     tip: "\(Double(model.week_click_num).tenK) 人在追",
                     rank: ip.row)
        }else if identify == "collect" {
            cell.set(model,
                     intro: model.author_name,
                     tip: "\(Double(model.week_collect_num).tenK) 人收藏",
                     rank: ip.row+ip.section)
            cell.isBottomShow = (ip.row < 3)
        }else if identify == "wanben" {
            cell.set(model,
                     intro: model.book_intro,
                     tip: "\(model.last_chapter_date ?? "") 完结",
                     rank: ip.row)
        }
        cell.isStatusShow = (identify != "wanben")
        return cell
    })
    
    convenience init(_ viewModel: RankSubViewModel) {
        self.init()
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
    
    func config(_ viewModel: RankSubViewModel) {
        if UIDevice.current.isiPhoneXSeries {
            tableView.contentInset = UIEdgeInsets(top: 20, left: 0, bottom: 0, right: 0 )
        }
        viewModel.activityDriver
            .drive(self.rx.loading)
            .disposed(by: bag)
        
        viewModel.activityDriver
            .drive(HUD.loading)
            .disposed(by: bag)
        
        viewModel.dataEmpty
            .drive(tableView.rx.isHidden)
            .disposed(by: bag)
        
        viewModel.exceptionOuptputDriver
            .drive(self.rx.exception)
            .disposed(by: bag)
        
        /// 开关
        if let parent = self.parent as? RankViewController {
            parent
                .genderSwitch
                .rx
                .isOn
                .map{ $0 ? .male: .female }
                .bind(to: viewModel.genderSwitch)
                .disposed(by: bag)
        }
        
        tableView
            .rx
            .modelSelected(RankModel.self)
            .bind(to: viewModel.itemDidSelected)
            .disposed(by: bag)
        
        tableView
            .mj_footer
            .rx
            .start
            .bind(to: viewModel.footerRefresh)
            .disposed(by: bag)
        
       viewModel
            .section
            .drive(self.tableView.rx.items(dataSource: self.dataSource))
            .disposed(by: bag)
        
        viewModel
            .endMoreDaraRefresh
            .drive(tableView.mj_footer.rx.endNoMoreData)
            .disposed(by: bag)
        
        viewModel
            .gotoReader
            .subscribe(onNext: {
                 BookReaderHandler.jump($0.book_id, contentId: $0.content_id)
            })
            .disposed(by: bag)
    }
    
    func configUI() {
        
        tableView.registerNibWithCell(RankTableViewCell.self)
        tableView.delegate = self
        tableView.mj_footer = RefreshFooter()
        
    }
}

extension RankSubViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let view = UIView()
        view.backgroundColor = UIColor(0xF4F6F9)
        return view
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
}
