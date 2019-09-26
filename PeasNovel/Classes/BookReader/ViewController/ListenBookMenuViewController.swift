//
//  ListenBookMenuViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/12.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import Alamofire

class ListenBookMenuViewController: BaseViewController {
    @IBOutlet var tioneBtns: [UIButton]!
    @IBOutlet var speechRateBtns: [UIButton]!
    @IBOutlet var timingBtns: [UIButton]!
    @IBOutlet var cornorContainerViews: [UIView]!
    @IBOutlet var existBtn: UIButton!
    @IBOutlet weak var menuView: UIView!
    @IBOutlet weak var coverbtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        cornorContainerViews.forEach { (view) in
            view.layer.cornerRadius = 3
            view.layer.borderColor = UIColor(0xADADAD).cgColor
            view.layer.borderWidth = 0.5
        }

    }


    convenience init(_ viewModel: ListenBookMenuViewModel) {
        self.init(nibName: "ListenBookMenuViewController", bundle: nil)
        
          self.rx.viewDidLoad
            .asObservable()
            .subscribe(onNext: { [weak self](_) in
                self?.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx.viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
        
        
    }
    
    private func config(_ viewModel: ListenBookMenuViewModel) {
        existBtn.rx.tap.mapToVoid()
            .subscribe(onNext: { (_) in
                SpeechManager.share.stopAllTask()
            })
            .disposed(by: bag)
        
        coverbtn.rx.tap.mapToVoid()
            .subscribe(onNext: {[weak self] (_) in
                guard let weakSelf = self else {
                    return
                }
                UIView.animate(withDuration: 0.25, animations: {
                    weakSelf.menuView.alpha =  weakSelf.menuView.alpha == 1 ? 0 : 1
                })
            })
            .disposed(by: bag)
        
        Observable.merge(existBtn.rx.tap.mapToVoid())
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (_) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.dismiss(animated: true, completion: nil)
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.Book.ListenBook.statusCallback)
            .map { $0.object as? SpeechManager.Stattus}
            .unwrap()
            .subscribe(onNext: {[weak self] (status) in
                guard let weakSelf = self else {
                    return
                }
                switch status {
                case .systhesizeFinish(result: let result, data: nil):
                    let manager = NetworkReachabilityManager()
                    if let err_code = result?.err_code,
                        err_code != "0",
                        let err_msg = result?.err_msg,
                        !err_msg.isEmpty,
                        let isReachable = manager?.isReachable, !isReachable {
                        DispatchQueue.main.async {
                             weakSelf.dismiss(animated: true, completion: {
                                NotificationCenter.default.post(name: NSNotification.Name.Book.ListenBook.showErrorAlert, object: nil)
                             })
                        }
                    }
                case .stop:
                    weakSelf.dismiss(animated: true, completion: {})
                default:
                    break
                }
            })
            .disposed(by: bag)
        
//        NotificationCenter.default.rx.notification(Notification.Name.Network.networkChange)
//            .map { $0.object as? Alamofire.NetworkReachabilityManager.NetworkReachabilityStatus}
//            .asObservable()
//            .unwrap()
//            .subscribe(onNext: {[weak self] (status) in
//                guard let weakSelf = self else {
//                    return
//                }
//                switch status {
//                case .unknown,
//                     .notReachable:
//                    DispatchQueue.main.async {
//                        weakSelf.dismiss(animated: true, completion: {
//                            NotificationCenter.default.post(name: NSNotification.Name.Book.ListenBook.showErrorAlert, object: nil)
//                        })
//                    }
//                default:
//                    break
//                }
//            })
//            .disposed(by: bag)
//
        
        viewModel.menuConfig
            .unwrap()
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: {[weak self] (config) in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.tioneBtns.forEach { $0.isSelected = $0.tag == config.tone}
                weakSelf.speechRateBtns.forEach { $0.isSelected = $0.tag == config.speech_rate}
                weakSelf.timingBtns.forEach { $0.isSelected = $0.tag == config.timing}
            })
            .disposed(by: bag)
    
        
        tioneBtns[0]
            .rx.tap
            .map { ToneType.female }
            .bind(to: viewModel.toneBtnInput)
            .disposed(by: bag)
        
        tioneBtns[1]
            .rx.tap
            .map { ToneType.male }
            .bind(to: viewModel.toneBtnInput)
             .disposed(by: bag)
        
        speechRateBtns[0]
            .rx.tap
            .map { SpeechType.moreSlow}
            .bind(to: viewModel.speechRateBtnInput)
            .disposed(by: bag)
        
        speechRateBtns[1]
            .rx.tap
            .map { SpeechType.slow}
            .bind(to: viewModel.speechRateBtnInput)
            .disposed(by: bag)
        
        speechRateBtns[2]
            .rx.tap
            .map { SpeechType.normal}
            .bind(to: viewModel.speechRateBtnInput)
            .disposed(by: bag)
        
        speechRateBtns[3]
            .rx.tap
            .map { SpeechType.quick}
            .bind(to: viewModel.speechRateBtnInput)
            .disposed(by: bag)
        
        speechRateBtns[4]
            .rx.tap
            .map { SpeechType.moreQuick}
            .bind(to: viewModel.speechRateBtnInput)
            .disposed(by: bag)
        
        
        timingBtns[0]
            .rx.tap
            .map { TimingType.none }
            .bind(to: viewModel.timingBtnInput)
            .disposed(by: bag)
        
        timingBtns[1]
            .rx.tap
            .map { TimingType.fifteen }
            .bind(to: viewModel.timingBtnInput)
            .disposed(by: bag)
        
        timingBtns[2]
            .rx.tap
            .map { TimingType.thirty }
            .bind(to: viewModel.timingBtnInput)
            .disposed(by: bag)
        
        timingBtns[3]
            .rx.tap
            .map { TimingType.sixity }
            .bind(to: viewModel.timingBtnInput)
            .disposed(by: bag)
        
        timingBtns[4]
            .rx.tap
            .map { TimingType.ninety }
            .bind(to: viewModel.timingBtnInput)
            .disposed(by: bag)
        
        btnTaps(tioneBtns)
        btnTaps(speechRateBtns)
        btnTaps(timingBtns)
        
    }
    
    private func btnTaps(_ btns: [UIButton]) {
        for index in 0 ..< btns.count {
            btns[index].rx.tap
                .subscribe(onNext: { (_) in
                    btns.forEach { $0.isSelected = false}
                    btns[index].isSelected = true
                })
                .disposed(by: bag)
        }
    }
    

}
