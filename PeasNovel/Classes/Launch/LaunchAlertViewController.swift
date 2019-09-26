//
//  LaunchAlertViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/6/3.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class LaunchAlertViewController: BaseViewController {
   
    @IBOutlet weak var imageCover: UIImageView!
    
    @IBOutlet weak var imageHeight: NSLayoutConstraint!
    @IBOutlet weak var imageWidth: NSLayoutConstraint!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var imageBtn: UIButton!
    
    convenience init(_ viewModel: LaunchAlertViewModel) {
        self.init(nibName: "LaunchAlertViewController", bundle: nil)
        self.rx.viewDidLoad
            .subscribe(onNext: {[weak self] (_) in
                self?.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx.viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
        
        self.rx.viewWillDisappear
            .bind(to: viewModel.viewWillDisappear)
            .disposed(by: bag)
    }
    
    
    
    private func config(_ viewModel: LaunchAlertViewModel) {
        viewModel.dataOutput
            .asObservable()
            .skip(1)
            .subscribe(onNext: {[weak self] in
                self?.imageCover.kf.setImage(with: URL(string: $0.img_url ?? ""), placeholder: UIImage.placeholder, options:[                                                .transition(.fade(1)),
                                                                                                                                                                                                        .cacheOriginalImage], completionHandler: { (result) in
                    switch result {
                    case .failure(let error):
                        debugPrint("LaunchAlertViewController:\(error.localizedDescription)")
                    case .success(let value):
                        self?.imageCover.image = value.image
                        debugPrint(value.image)
                    }
                })
            })
            .disposed(by: bag)
        
        imageBtn.rx.tap
            .mapToVoid()
            .debug()
            .bind(to: viewModel.imageTapInput)
            .disposed(by: bag)
        
        viewModel.imageTapOutput
            .subscribe(onNext: { [weak self] url in
                 self?.dismiss(animated: true, completion: {
                    NotificationCenter.default.post(name: NSNotification.Name.Event.lancunAlertJump, object: url)
                })
            })
            .disposed(by: bag)
        
        closeBtn.rx.tap
            .mapToVoid()
            .subscribe(onNext: { [weak self](_) in
                self?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: bag)
        
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
    
}
