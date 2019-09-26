//
//  FeedbackViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/8.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import PKHUD

class FeedbackViewController: BaseViewController {
    let submitBtnInput: PublishSubject<Void> = .init()
    let contentInput: BehaviorRelay<String> = .init(value: "")
    let contactInput: BehaviorRelay<String> = .init(value: "")
    let questTypeInput: BehaviorRelay<FeedbackQuestion> = .init(value: FeedbackQuestion())
    let servviceBtnInput: PublishSubject<Void> = .init()
    
    @IBOutlet weak var tableView: UITableView!
   fileprivate lazy var dataSource = RxTableViewSectionedReloadDataSource<SectionModel<FeedbackUIType, FeedbackQuestion>>(configureCell: {[weak self] (dataSoure, tableView, indexPath, _) -> UITableViewCell in
        let sectionType = dataSoure.sectionModels[indexPath.section].model
        switch sectionType {
        case .normalQuesttion(let questions):
            let cell = tableView.dequeueCell(CollectionTableViewCell.self, for: indexPath)
            if let weakSelf = self {
                cell.questionOutput.asObservable().bind(to: weakSelf.questTypeInput).disposed(by: cell.bag)
            }
            cell.config(questions)
            return cell
        case .opitionFeedback:
            if indexPath.row == 0 {
                let cell = tableView.dequeueCell(TextViewTableViewCell.self, for: indexPath)
                if let weakSelf = self {
                     cell.textView.rx.text.map { $0 }.unwrap().filter { !$0.isEmpty}.bind(to: weakSelf.contentInput).disposed(by: cell.bag)
                }
                return cell
            }
            if indexPath.row == 1 {
                let cell = tableView.dequeueCell(FeedbackTextInputTableViewCell.self, for: indexPath)
                if let weakSelf = self {
                    cell.textField.rx.text.map { $0 }.unwrap().filter { !$0.isEmpty}.bind(to: weakSelf.contactInput).disposed(by: cell.bag)
                }
                return cell
            }
            if indexPath.row == 2 {
                let cell = tableView.dequeueCell(CenterBtnTableViewCell.self, for: indexPath)
                if let weakSelf = self {
                    cell.btn.rx.tap.mapToVoid().bind(to: weakSelf.submitBtnInput).disposed(by: cell.bag)
                    cell.btn.setTitle("提交反馈", for: .normal)
                }
                return cell
            }
        case .onlineService(let switcher):
            let cell = tableView.dequeueCell(FeedbackDescTableViewCell.self, for: indexPath)
            cell.config(switcher)
            if let weakSelf = self {
                cell.btn.rx.tap.mapToVoid().bind(to: weakSelf.servviceBtnInput).disposed(by: cell.bag)
            }
            return cell
        }
        return tableView.dequeueCell(UITableViewCell.self, for: indexPath)
    })
    convenience init(_ viewModel: FeedbackViewModel) {
        self.init(nibName: "FeedbackViewController", bundle: nil)
        
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
    
    
    func config(_ viewModel: FeedbackViewModel) {
        title = "帮助与反馈"
        tableView.keyboardDismissMode = .onDrag
        tableView.registerNibWithCell(FeedbackTextInputTableViewCell.self)
        tableView.registerNibWithCell(FeedbackDescTableViewCell.self)
        tableView.registerNibWithCell(TextViewTableViewCell.self)
        tableView.registerNibWithCell(CollectionTableViewCell.self)
        tableView.registerNibWithCell(CenterBtnTableViewCell.self)
        tableView.registerClassWithCell(UITableViewCell.self)
        tableView.registerNibWithHeaderFooterView(FeedbackSectionHeaderView.self)
        tableView
            .rx
            .setDelegate(self)
            .disposed(by: bag)
        
        viewModel
            .sections
            .drive(self.tableView.rx.items(dataSource: self.dataSource))
            .disposed(by: bag)

        questTypeInput.asObservable()
            .bind(to: viewModel.questTypeInput)
            .disposed(by: bag)
        
        contactInput.asObservable()
            .bind(to: viewModel.contactInput)
            .disposed(by: bag)
        
        contentInput.asObservable()
            .bind(to: viewModel.contentInput)
            .disposed(by: bag)
        
        submitBtnInput.asObservable()
            .bind(to: viewModel.submitBtnInput)
            .disposed(by: bag)
        
        viewModel.messageOutput
            .asObservable()
            .bind(to: HUD.flash)
            .disposed(by: bag)
        
        viewModel.popAction
            .asObservable()
            .subscribe(onNext: {[weak self] (_) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.navigationController?.popViewController(animated: true)
            })
            .disposed(by: bag)
        
        viewModel.questDetailOutput
            .drive(onNext: { [weak self](vm) in
                let vcc = QuestionListViewController(vm)
                
                self?.navigationController?.pushViewController(vcc, animated: true)
            })
            .disposed(by: bag)
        
        servviceBtnInput.asObservable()
            .subscribe(onNext: { (_) in
                let vcc = ContactServiceAlertViewController()
                vcc.modalPresentationStyle = .custom
                vcc.modalTransitionStyle = .crossDissolve
                navigator.present(vcc)
            })
            .disposed(by: bag)
        
        let rightItem = UIBarButtonItem(title: "我的反馈", style: UIBarButtonItem.Style.plain, target: nil, action: nil)
        navigationItem.rightBarButtonItem = rightItem
        
        rightItem.rx.tap
            .mapToVoid()
            .subscribe(onNext: { [weak self](_) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.navigationController?.pushViewController(MyFeedbackViewController(MyFeedbackViewModel()), animated: true)
            })
            .disposed(by: bag)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
}

extension FeedbackViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionType = dataSource.sectionModels[indexPath.section].model
        switch sectionType {
        case .normalQuesttion:
            return 150
        case .opitionFeedback:
            if indexPath.row == 0 {
                return 120
            }
            if indexPath.row == 1 {
                return 120
            }
            if indexPath.row == 2 {
                 return 120
            }
        case .onlineService:
              return 150
    }
        return 0
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 35
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueHeaderFooterView(FeedbackSectionHeaderView.self)
        let sectionType = dataSource.sectionModels[section].model
        view.label.text = sectionType.title
        return view
    }
}
