//
//  QuestionListViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/26.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources

class QuestionListViewController: BaseViewController {
    let questions = BehaviorRelay<[FeedbackQuestionDetail]>.init(value: [])
    @IBOutlet weak var tableView: UITableView!
    let itemsSelted: PublishSubject<IndexPath> = .init()
    
    convenience init(_ viewModel: QuestionListViewModel) {
        self.init(nibName: "QuestionListViewController", bundle: nil)
        self.rx.viewDidLoad
            .subscribe(onNext: {[weak self] (_) in
                self?.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx.viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
        
    }
    
    private func config(_ viewModel: QuestionListViewModel) {
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        viewModel.title
            .subscribe(onNext: {[weak self] (title) in
                self?.title = title
            })
            .disposed(by: bag)
        
        tableView.registerNibWithCell(TextImageFolderTableViewCell.self)
        tableView.registerNibWithCell(TextFolderTableViewCell.self)
        tableView.estimatedRowHeight = 50
        tableView.rx.modelSelected(FeedbackQuestionDetail.self)
            .bind(to: viewModel.itemSelectInput)
            .disposed(by: bag)
        
       let dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, FeedbackQuestionDetail>>(configureCell: { (dataSource, tableView, indexPath, item) -> UITableViewCell in
            if item.img_url.isEmpty {
                let cell = tableView.dequeueCell(TextFolderTableViewCell.self, for: indexPath)
                cell.config(item, isFold: item.isSelected)
                return cell
            } else {
                let cell = tableView.dequeueCell(TextImageFolderTableViewCell.self, for: indexPath)
                cell.config(item, isFold: item.isSelected)
                return cell
            }
        })
        
        viewModel.items
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: bag)
        
        tableView.rx.setDelegate(self).disposed(by: bag)
        
        viewModel.questions.asObservable()
            .bind(to: questions)
            .disposed(by: bag)
        
        itemsSelted.asObservable()
            .bind(to: viewModel.itemsSelted)
            .disposed(by: bag)
        
        questions.asObservable()
            .map { $0.isEmpty }
            .bind(to: tableView.rx.isHidden)
            .disposed(by: bag)
    }
}



extension QuestionListViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
         itemsSelted.onNext(indexPath)
         tableView.reloadRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
    }
   
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let metaRowHeight: CGFloat  = 44
        if indexPath.row < questions.value.count {
            let model = questions.value[indexPath.row]
            if model.isSelected {
                return UITableView.automaticDimension
            } else {
                return metaRowHeight
            }
        }
        return metaRowHeight
    }
    
}
