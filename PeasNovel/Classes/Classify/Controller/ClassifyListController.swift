//
//  ClassifyListController.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/21.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxDataSources
import PKHUD

class ClassifyListController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
    }
    
    convenience init(_ viewModel: ClassifyListViewModel) {
        self.init()
        self.rx
            .viewDidLoad
            .subscribe(onNext: { [unowned self] in
                self.configUI(viewModel.identify)
                self.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx
            .viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
    }
    
    func config(_ viewModel: ClassifyListViewModel) {
        
        viewModel.activityDriver
            .drive(self.rx.loading)
            .disposed(by: bag)
        
        viewModel.dataEmpty
            .drive(contentView.rx.isHidden)
            .disposed(by: bag)
        
        viewModel.exceptionOuptputDriver
            .drive(self.rx.exception)
            .disposed(by: bag)

        
        viewModel
            .subViewModels
            .subscribe(onNext: { [unowned self] in
                let children = $0.map{ vm in ClassifyListChildController(vm) }
                let titles = $0.map{ vm in vm.identify ?? "" }
                self.titleView.setTitles(titles)
                self.contentView.reset(children)
            })
            .disposed(by: bag)
        
        
        
    }
    
    func configUI(_ title: String?) {
        
        self.title = title
        
        self.view.addSubview(contentView)
        self.view.addSubview(titleView)
        
        self.titleView.titleTapAction = { [weak self] index in
            self?.contentView.selected(index: index)
        }
        contentView.tapAction = {[weak self] progress, sourceIndex, targetIndex in
            self?.titleView.setTitle(progress: progress, sourceIndex: sourceIndex, targetIndex: targetIndex)
        }
        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        contentView.snp.makeConstraints {
            $0.left.right.bottom.equalTo(0)
            $0.top.equalTo(50)
        }
    }
    
    /// subviews
    lazy var titleView: PageTitleView = {
        let titleView = PageTitleView(frame: CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 40))
        titleView.resize(3)
        titleView.titleSpace = 40
        titleView.tintColor = UIColor.theme
        titleView.textColor = UIColor(0x999999)
        titleView.didSelected = {sourceLabel, targetLabel in
            sourceLabel.font = UIFont.systemFont(ofSize: 18)
            targetLabel.font = UIFont.boldSystemFont(ofSize: 18)
        }
        return titleView
    }()
    
    lazy var contentView: PageContentView = {
        let  contentView = PageContentView([], parentVC: self)
        view.addSubview(contentView)
        return contentView
    }()

}
