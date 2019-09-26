//
//  RankViewController.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/19.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxDataSources

class RankViewController: BaseViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    convenience init(_ viewModel: RankViewModel) {
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
    
    func config(_ viewModel: RankViewModel) {
        
        viewModel
            .subViewModels
            .subscribe(onNext: { [unowned self] in
                let children = $0.map{ vm in RankSubViewController(vm) }
                let titles = $0.map{ vm in NSLocalizedString(vm.identify, comment: "") }
                self.titleView.setTitles(titles)
                self.contentView.reset(children)
            })
            .disposed(by: bag)
        
    }
    
    func configUI() {
        
        self.title = "排行榜"
        
        self.view.addSubview(contentView)
        self.view.addSubview(titleView)
        
        self.titleView.titleTapAction = { [weak self] index in
            self?.contentView.selected(index: index)
        }
        contentView.tapAction = {[weak self] progress, sourceIndex, targetIndex in
            self?.titleView.setTitle(progress: progress, sourceIndex: sourceIndex, targetIndex: targetIndex)
        }

        // Do any additional setup after loading the view.
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: genderSwitch)
        genderSwitch.addTarget(self, action: #selector(genderSwitchAction(_:)), for: .valueChanged)
        genderSwitch.on = (me.sex == .male)
        genderSwitchAction(genderSwitch)
        
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
            sourceLabel.font = UIFont.systemFont(ofSize: 17)
            targetLabel.font = UIFont.systemFont(ofSize: 17)
        }
        return titleView
    }()
    
    lazy var contentView: PageContentView = {
        let  contentView = PageContentView([], parentVC: self)
        view.addSubview(contentView)
        return contentView
    }()
    
    lazy var genderSwitch: AttributeSwitch = {
        let genderSwitch = AttributeSwitch(frame: CGRect(origin: .zero, size: CGSize(width: 60, height: 30)))
        let arrt = [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 12),
                    NSAttributedString.Key.foregroundColor: UIColor.white]
        genderSwitch.onLabel.attributedText = NSAttributedString(string: "男频", attributes: arrt)
        genderSwitch.offLabel.attributedText = NSAttributedString(string: "女频", attributes: arrt)
        genderSwitch.onTintColor = UIColor(0x00CF7A)
        genderSwitch.inactiveColor = UIColor(0xF3415B)
        
        return genderSwitch
    }()
    
    @objc func genderSwitchAction(_ sender: AttributeSwitch) {
        
        let tintColor = sender.on ? UIColor(0x00CF7A): UIColor(0xF3415B)
        
        let attr0 = NSAttributedString(string: sender.on ? "女" : "男",
                                       attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 10),
                                                    NSAttributedString.Key.foregroundColor: tintColor])
        let attr1 = NSMutableAttributedString(string: "频",
                                              attributes: [NSAttributedString.Key.font : UIFont.systemFont(ofSize: 6),
                                                           NSAttributedString.Key.foregroundColor: tintColor])
        attr1.insert(attr0, at: 0)
        sender.thumbLabel.attributedText = attr1
    }

}
