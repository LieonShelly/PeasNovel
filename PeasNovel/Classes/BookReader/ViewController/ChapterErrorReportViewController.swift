//
//  ChapterErrorReportViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/8.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxCocoa
import RxSwift
import RxDataSources
import PKHUD
import IQKeyboardManagerSwift

class ChapterErrorReportViewController: BaseViewController {
    
    @IBOutlet weak var tableView: UITableView!
    let submitBtnInput: PublishSubject<Void> = .init()
    let contentInput: BehaviorRelay<String> = .init(value: "")
    let enterBtnValid: BehaviorRelay<Bool> = .init(value: false)
    let outterDescInput: BehaviorRelay<String> = BehaviorRelay<String>.init(value: "")
    
    fileprivate lazy var dataSource = RxTableViewSectionedReloadDataSource<SectionModel<ChapterReportViewSectionType, ChapterReportOption>>(configureCell: {[weak self] (dataSoure, tableView, indexPath, item) -> UITableViewCell in
        let sectionType = dataSoure.sectionModels[indexPath.section].model
        switch sectionType {
        case .desc:
            let cell = tableView.dequeueCell(ReportDescTableViewCell.self, for: indexPath)
            cell.selectionStyle = .none
            return cell
        case .items:
            let cell = tableView.dequeueCell(DescOptionTableViewCell.self, for: indexPath)
             cell.selectionStyle = .none
            cell.config(item)
            return cell
        case .textView:
            let cell = tableView.dequeueCell(TextViewTableViewCell.self, for: indexPath)
            if let weakSelf = self {
                weakSelf.outterDescInput.bind(to:  cell.textView.rx.text).disposed(by: cell.bag)
                cell.textView.rx.text.orEmpty.bind(to: weakSelf.contentInput).disposed(by: cell.bag)
                cell.placeholderLabel.attributedText = "有其他问题、我要补充。请输入200字以内".withlineSpacing(8)
                cell.textView.rx.text.orEmpty
                    .map { (text) -> String in
                        if text.count >= 200 {
                            return String(text[text.startIndex ... text.index(text.startIndex, offsetBy: 199)])
                        }
                        return text
                    }
                    .bind(to: cell.textView!.rx.text)
                    .disposed(by: cell.bag)
            }
             cell.selectionStyle = .none
            return cell
        case .commitBtn:
            let cell = tableView.dequeueCell(CenterBtnTableViewCell.self, for: indexPath)
            if let weakSelf = self {
                cell.btn.rx.tap
                    .mapToVoid()
                    .debug()
                    .bind(to: weakSelf.submitBtnInput)
                    .disposed(by: cell.bag)
                
                cell.btn.setTitle("提交反馈", for: .normal)
                Observable.just(0)
                    .mapToVoid()
                    .withLatestFrom(weakSelf.enterBtnValid)
                    .subscribe(onNext: { (isValid) in
                        let btn = cell.btn
                        btn?.isEnabled = isValid
                        if isValid {
                            btn?.backgroundColor = UIColor.theme
                        } else {
                            btn?.backgroundColor = UIColor.gray
                        }
                    })
                    .disposed(by: cell.bag)
                
                weakSelf.enterBtnValid.asObservable()
                    .subscribe(onNext: { (isValid) in
                        let btn = cell.btn
                        btn?.isEnabled = isValid
                        if isValid {
                            btn?.backgroundColor = UIColor.theme
                        } else {
                            btn?.backgroundColor = UIColor.gray
                        }
                    })
                    .disposed(by: cell.bag)
            }
             cell.selectionStyle = .none
            return cell
        }
    })
    
    convenience init( _ viewModel: ChapterReportViewModel) {
        self.init(nibName: "ChapterErrorReportViewController", bundle: nil)
        self.rx.viewDidLoad
            .subscribe(onNext: { [weak self](_) in
                self?.configUI()
                self?.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx.viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
         IQKeyboardManager.shared.enable = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
         IQKeyboardManager.shared.enable = false
    }
    
    private func configUI() {
        title = "章节报错反馈"
        tableView.delegate = self
        tableView.separatorStyle = .none
        tableView.registerNibWithCell(ReportDescTableViewCell.self)
        tableView.registerNibWithCell(DescOptionTableViewCell.self)
        tableView.registerNibWithCell(TextViewTableViewCell.self)
        tableView.registerNibWithCell(CenterBtnTableViewCell.self)
        tableView.registerNibWithHeaderFooterView(FeedbackSectionHeaderView.self)
    }
    
    private func config(_ viewModel: ChapterReportViewModel) {
        viewModel.sections
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: bag)
        
        
        tableView.rx.modelSelected(ChapterReportOption.self)
            .asObservable()
            .filter { $0.feedback_type != -1}
            .bind(to: viewModel.itemSelectInput)
            .disposed(by: bag)
        
        
        submitBtnInput
            .asObservable()
            .debug()
            .withLatestFrom(contentInput)
            .bind(to: viewModel.commitBtnInput)
            .disposed(by: bag)
        
        viewModel.messageOutput
            .drive(HUD.flash)
            .disposed(by: bag)
        
        contentInput.asObservable()
            .filter { _ in (viewModel.selectedItemOutput.value?.feedback_type ?? 0) == 5 }
            .map { !$0.isEmpty }
            .bind(to: enterBtnValid)
            .disposed(by: bag)
        
        viewModel.selectedItemOutput
            .asObservable()
            .unwrap()
            .map { $0.feedback_type != 5 }
            .bind(to: enterBtnValid)
            .disposed(by: bag)
        
        viewModel.commitResult
            .asObservable()
            .map { $0.status?.code }
            .unwrap()
            .filter { $0 == 0 }
            .mapToVoid()
            .subscribe(onNext: { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.navigationController?.popViewController(animated: true)
            })
            .disposed(by: bag)
   
        viewModel.outterDescInput
            .bind(to: outterDescInput)
            .disposed(by: bag)
        
    }
}


extension ChapterErrorReportViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let sectionType = dataSource.sectionModels[indexPath.section].model
        switch sectionType {
        case .desc:
            return UITableView.automaticDimension
        case .items:
            return 50
        case .textView:
            return 147
        case .commitBtn:
            return 90
        }
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let sectionType = dataSource.sectionModels[section].model
        switch sectionType {
        case .desc:
            return 0
        case .items:
            return 35
        case .textView:
            return 0
        case .commitBtn:
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return UIView()
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 0.001
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let sectionType = dataSource.sectionModels[section].model
        switch sectionType {
        case .items:
            let view = tableView.dequeueHeaderFooterView(FeedbackSectionHeaderView.self)
            view.contentView.backgroundColor = .white
            let sectionType = dataSource.sectionModels[section].model
            view.label.text = sectionType.title
            return view
        default:
            return nil
        }
    }
}

