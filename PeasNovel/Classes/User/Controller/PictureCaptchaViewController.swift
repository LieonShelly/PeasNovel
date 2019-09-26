//
//  PictureCaptchaViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/21.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources


class PictureCaptchaViewController: BaseViewController {
    @IBOutlet weak var containerView: UIView!
    
    @IBOutlet weak var bigPic: UIImageView!
    @IBOutlet weak var slider: UISlider!
    @IBOutlet weak var smallPic: UIImageView!
    @IBOutlet weak var maxTrackLabel: UILabel!
    @IBOutlet weak var minTrackLabel: UILabel!
    let sliderEndInput: PublishSubject<Float> = .init()
    @IBOutlet weak var minTrackW: NSLayoutConstraint!
    
    convenience init(_ viewModel: PictureCaptchaViewModel) {
        self.init(nibName: "PictureCaptchaViewController", bundle: nil)
        
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
    
    private func config(_ viewModel: PictureCaptchaViewModel) {
        slider.setThumbImage(UIImage(named: "logoin_thumb"), for: .normal)
            slider.setThumbImage(UIImage(named: "logoin_thumb"), for: .highlighted)
        minTrackW.constant = 0
        containerView.layer.cornerRadius = 20
        containerView.layer.masksToBounds = true
        let width = UIScreen.main.bounds.width - 40 * 2
        viewModel.imageDataOutput
            .drive(onNext: { [weak self] data in
                guard let weakSelf = self  else {
                    return
                }
                weakSelf.bigPic.kf.setImage(with: URL(string: data.b))
                weakSelf.smallPic.kf.setImage(with: URL(string: data.s), completionHandler: { (result) in
                    switch result {
                    case .failure(_):
                        break
                    case .success(let imageResult):
                       weakSelf.smallPic.frame.size = imageResult.image.size
                       weakSelf.smallPic.frame.origin.y = data.h
                       weakSelf.smallPic.frame.origin.x = 0
                       let smallImageW: CGFloat = imageResult.image.size.width
                       weakSelf.slider.minimumValue = Float(smallImageW * 0.5)
                       weakSelf.slider.maximumValue = Float(width) - Float(smallImageW * 0.5) 
                    }
                })
               
            })
            .disposed(by: bag)
        
        slider.rx.value
            .map { $0 }
            .subscribe(onNext: { [weak self] data in
                guard let weakSelf = self  else {
                    return
                }
                weakSelf.smallPic.center.x = CGFloat(data)
                weakSelf.minTrackW.constant = CGFloat(data)
                weakSelf.maxTrackLabel.isHidden = data > 0
            })
            .disposed(by: bag)
        
        sliderEndInput.asObservable()
            .bind(to: viewModel.sliderXInput)
            .disposed(by: bag)
        
        slider.addTarget(self, action: #selector(self.silderEnd), for: UIControl.Event.touchUpInside)
        

    }
    
    @objc private  func silderEnd() {
        sliderEndInput.onNext(Float(smallPic.frame.origin.x))
        dismiss(animated: true, completion: nil)
    }
}
