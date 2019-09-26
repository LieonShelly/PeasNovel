//
//  SmallRederHomeViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/8.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import MXParallaxHeader
import RxSwift
import RxCocoa

class SmallRederHomeViewController: BaseViewController {
    @IBOutlet weak var contineBtn: UIButton!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var scrollView: MXScrollView!
    struct UISize {
        static let headerHeight: CGFloat = 150
    }
    var headerHeight: CGFloat = UISize.headerHeight
    lazy var headerView: UIButton = {
        let headerView = UIButton(type: .custom)
        headerView.backgroundColor = UIColor.black.withAlphaComponent(0.2)
        return headerView
    }()
    var bookInfo: BookInfo!
    var smallVC: SmallReaderViewController!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configui()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if #available(iOS 11.0, *) {
            scrollView.parallaxHeader.minimumHeight = view.safeAreaInsets.top
        } else {
             scrollView.parallaxHeader.minimumHeight = 20
        }
    }
    
    convenience init( _ bookInfo: BookInfo) {
        self.init(nibName: "SmallRederHomeViewController", bundle: nil)
        self.bookInfo = bookInfo
    }
    

    fileprivate func configui() {
        contineBtn.isHidden = true
        scrollView.parallaxHeader.height = headerHeight
        scrollView.contentSize = CGSize(width: view.bounds.width, height: UIScreen.main.bounds.size.height)
        scrollView.parallaxHeader.view = headerView
        scrollView.parallaxHeader.delegate = self
        scrollView.parallaxHeader.mode = MXParallaxHeaderMode.topFill
        scrollView.delegate = self
        scrollView.backgroundColor = .clear
        if #available(iOS 11.0, *) {
            scrollView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        contineBtn.layer.cornerRadius = 3
        contineBtn.layer.masksToBounds = true
        let vm = SmallReaderVewModel(bookInfo)
        smallVC = SmallReaderViewController(vm)
        scrollView.addSubview(smallVC.view)
        addChild(smallVC)
        Observable.merge(closeBtn.rx.tap.mapToVoid(),
                          headerView.rx.tap.mapToVoid())
            .subscribe(onNext: {[weak self] (_) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.view.removeFromSuperview()
                weakSelf.removeFromParent()
            })
            .disposed(by: bag)
        
        smallVC.didScroll
            .asObservable()
            .subscribe(onNext: { [weak self](scrollView) in
                guard let weakSelf = self else {
                    return
                }
               let velocityY = scrollView.panGestureRecognizer.velocity(in: weakSelf.scrollView).y
                if velocityY < 0 {
                    weakSelf.scrollView.setContentOffset(.zero, animated: true)
                    if weakSelf.smallVC.titleLabelHeight.constant != 40 {
                        UIView.animate(withDuration: 0.25, animations: {
                            weakSelf.smallVC.titleLabelHeight.constant = 40
                            weakSelf.smallVC.cateLabel.isHidden = true
                            weakSelf.smallVC.authorLabel.isHidden = true
                            weakSelf.smallVC.topHeight.constant = 100
                        })
                    }
                } else {
                    if weakSelf.smallVC.titleLabelHeight.constant != 30, abs(weakSelf.scrollView.contentOffset.y) == weakSelf.headerHeight {
                        UIView.animate(withDuration: 0.25, animations: {
                            weakSelf.smallVC.titleLabelHeight.constant = 30
                            weakSelf.smallVC.cateLabel.isHidden = false
                            weakSelf.smallVC.authorLabel.isHidden = false
                            weakSelf.smallVC.topHeight.constant = 130
                        })
                    }
                }
                let svHeight = Float(scrollView.frame.height)
                let offsetY = fabsf(Float(scrollView.contentOffset.y))
                if svHeight + offsetY >= Float(scrollView.contentSize.height) {
                      weakSelf.contineBtn.isHidden = false
                } else {
                    weakSelf.contineBtn.isHidden = true
                }
                
            })
            .disposed(by: bag)
        
        contineBtn
            .rx.tap
            .asObservable()
            .withLatestFrom(vm.content)
            .unwrap()
            .subscribe(onNext: {
                BookReaderHandler.jump($0.book_id, contentId: $0.next_chapter?.content_id ?? "", toReader: true)
            })
            .disposed(by: bag)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        var frame = view.bounds
        scrollView.frame = frame
        scrollView.contentSize = frame.size
        
        frame.size.height -= scrollView.parallaxHeader.minimumHeight
        smallVC.view.frame = frame
        
    }
}
extension SmallRederHomeViewController: MXScrollViewDelegate, MXParallaxHeaderDelegate {
    func scrollView(_ scrollView: MXScrollView, shouldScrollWithSubView subView: UIScrollView) -> Bool {
        return true
    }
    
    func parallaxHeaderDidScroll(_ parallaxHeader: MXParallaxHeader) {
        let weakSelf = self
        if weakSelf.smallVC.titleLabelHeight.constant != 30, abs(weakSelf.scrollView.contentOffset.y) == weakSelf.headerHeight {
            UIView.animate(withDuration: 0.25) {
                weakSelf.smallVC.titleLabelHeight.constant = 30
                weakSelf.smallVC.cateLabel.isHidden = false
                weakSelf.smallVC.authorLabel.isHidden = false
                weakSelf.smallVC.topHeight.constant = 130
            }
        }
    }
}







