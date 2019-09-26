//
//  FinalViewController.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/18.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxDataSources
import RxSwift
import PKHUD

class FinalViewController: BaseViewController {
    
    @IBOutlet weak var collectionView: UICollectionView!
    let exchangeAction: PublishSubject<Int> = .init()
    
    lazy var dataSource = RxCollectionViewSectionedReloadDataSource<SectionModel<String, BookInfo>>(configureCell: {_, cv, ip, model in
        if ip.section == 0 {
            let cell = cv.dequeueCell(FinalCollectionViewCell.self, for: ip)
            cell.set(model)
            return cell
        }else if ip.section == 1 && ip.item < 3{
            let cell = cv.dequeueCell(FinalCollectionViewCell.self, for: ip)
            cell.set(model)
            return cell
        }else{
            let cell = cv.dequeueCell(BookLeftCoverRightTextCell.self, for: ip)
            cell.config(model.cover_url, title: model.book_title, desc: model.book_intro, name: model.author_name, categoryText: model.category_id_1?.short_name, processText:  model.writing_process.desc)
            return cell
        }
    }, configureSupplementaryView: { [unowned self] (ds, cv, kind, ip) in
        
        if kind == UICollectionView.elementKindSectionHeader {
            let header = cv.dequeueReusableView(BookMallSectionView.self, ofKind: UICollectionView.elementKindSectionHeader, for: ip)
            header.refreshMode()
            header.label.text = ds[ip.section].model
            header
                .btn
                .rx
                .tap
                .map{ ip.section }
                .bind(to: self.exchangeAction)
                .disposed(by: header.bag)
            return header
        }else {
            let reuseView = cv.dequeueReusableView(UICollectionReusableView.self, ofKind: kind, for: ip)
            reuseView.backgroundColor = UIColor(0xF4F6F9)
            return reuseView
        }
    })
    
    convenience init(_ viewModel: FinalViewModel) {
        self.init(nibName: "FinalViewController", bundle: nil)
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
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }
    
    func config(_ viewModel: FinalViewModel) {
        
        viewModel.activityDriver
            .drive(self.rx.loading)
            .disposed(by: bag)
        
        viewModel.activityDriver
            .drive(HUD.loading)
            .disposed(by: bag)
        
        viewModel.dataEmpty
            .drive(collectionView.rx.isHidden)
            .disposed(by: bag)
        
        viewModel.exceptionOuptputDriver
            .drive(self.rx.exception)
            .disposed(by: bag)
        
        self.exception
            .mapToVoid()
            .bind(to: viewModel.exceptionInput)
            .disposed(by: bag)
        
        genderSwitch
            .rx
            .isOn
            .map{ $0 ? .male: .female }
            .bind(to: viewModel.genderAction)
            .disposed(by: bag)
        
        exchangeAction
            .bind(to: viewModel.exchangeAction)
            .disposed(by: bag)
        
        collectionView
            .mj_footer
            .rx
            .start
            .bind(to: viewModel.footerRefresh)
            .disposed(by: bag)
        
        collectionView
            .rx
            .modelSelected(BookInfo.self)
            .bind(to: viewModel.itemDidSelected)
            .disposed(by: bag)
        
        viewModel
            .section
            .drive(self.collectionView.rx.items(dataSource: self.dataSource))
            .disposed(by: bag)
        
        viewModel
            .toReader
            .subscribe(onNext: {
                BookReaderHandler.jump($0.book_id, contentId: $0.content_id)
            })
            .disposed(by: bag)
        // 默认加载是用户性别
        viewModel
            .genderAction
            .on(.next(me.sex))
        
        viewModel
            .endMoreDaraRefresh
            .drive(collectionView.mj_footer.rx.endNoMoreData)
            .disposed(by: bag)
    }
    
    func configUI() {
        
        title = "完本"
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        collectionView.registerNibWithCell(FinalCollectionViewCell.self)
        collectionView.registerNibWithCell(BookLeftCoverRightTextCell.self)
        collectionView.registerNibWithReusableView(BookMallSectionView.self,
                                                   forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader)
        
        collectionView.registerClassWithReusableView(UICollectionReusableView.self,
                                                     forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter)
        collectionView.mj_footer = RefreshFooter()
        collectionView.delegate = self
        
        // Do any additional setup after loading the view.
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(customView: genderSwitch)
        genderSwitch.addTarget(self, action: #selector(genderSwitchAction(_:)), for: .valueChanged)
        genderSwitch.on = (me.sex == .male)
        genderSwitchAction(genderSwitch)

    }
    
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
    
    deinit {
        print("FinalViewController deinit")
    }

}

extension FinalViewController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 57)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForFooterInSection section: Int) -> CGSize {
        return CGSize(width: UIScreen.main.bounds.width, height: 10)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        return UIEdgeInsets(top: 0, left: 16, bottom: 16, right: 16)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if indexPath.section == 0 {
            return CGSize(width: (UIScreen.main.bounds.width - 2 * 16 - 2 * 10) / 3.0001, height: 210)
        }
        
        if indexPath.section == 1 && indexPath.item < 3{
            return CGSize(width: (UIScreen.main.bounds.width - 2 * 16 - 2 * 10) / 3.0001, height: 210)
        }
        return CGSize(width: UIScreen.main.bounds.width - 2 * 16, height: 140)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 16
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
}
