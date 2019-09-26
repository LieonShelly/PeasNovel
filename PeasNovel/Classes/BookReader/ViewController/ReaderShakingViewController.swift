//
//  ReaderShakingViewController.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/22.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxDataSources
import RxSwift
import RxCocoa
import RxSwiftExt
import AVKit

class ReaderShakingViewController: BaseViewController {
    @IBOutlet weak var container: UIView!
    @IBOutlet weak var tableView: UITableView!
    fileprivate var cacheHeights: [String: CGFloat] = [:]
    fileprivate lazy var dataSource = RxTableViewSectionedReloadDataSource<SectionModel<String, ReaderLastPageGuessBook>>(configureCell: {[weak self]_, tv, ip, model in
        if let adConfig = model.locaAdTemConfig {
            let cell = TableViewCellInfoService.chooseCell(adConfig, tableView: tv, indexPath: ip)
            if let weakSelf = self {
                let height = cell.systemLayoutSizeFitting(CGSize(width: tv.frame.size.width, height: 0), withHorizontalFittingPriority: UILayoutPriority.required, verticalFittingPriority: .fittingSizeLevel).height
                debugPrint("cell-height:\(height)")
                weakSelf.cacheHeights[ReaderShakingViewController.cellHeightKey(ip)] = height
            }
            return cell
        } else {
            let cell = tv.dequeueCell(ShakingBookTableViewCell.self, for: ip)
            cell.config(model.cover_url, title: model.book_title, dec: model.book_intro, tag: model.category_id_1?.name ?? "")
            return cell
        }
    })
    
    fileprivate lazy var audioPlayer: AVPlayer = {
        let audioPlayer = AVPlayer()
        return audioPlayer
    }()
    var shakingStartAudio: AVPlayerItem {
        if let path = Bundle.main.path(forResource: "shake_sound_male", ofType: "mp3") {
            let audioItem = AVPlayerItem(url: URL(fileURLWithPath: path, isDirectory: false))
            return audioItem
        }
        return AVPlayerItem(asset: AVAsset())
    }
    
    var shakingMatchAudio: AVPlayerItem {
        if let path = Bundle.main.path(forResource: "shake_match", ofType: "mp3") {
            let audioItem = AVPlayerItem(url: URL(fileURLWithPath: path, isDirectory: false))
            return audioItem
        }
        return AVPlayerItem(asset: AVAsset())
    }
    
    var shakingUnMatchAudio: AVPlayerItem {
        if let path = Bundle.main.path(forResource: "shake_nomatch", ofType: "mp3") {
            let audioItem = AVPlayerItem(url: URL(fileURLWithPath: path, isDirectory: false))
            return audioItem
        }
        return AVPlayerItem(asset: AVAsset())
    }

    let shakingResult: BehaviorRelay<[ReaderLastPageGuessBook]> = .init(value: [])
    fileprivate var animaTime: Int = 0
    let shackingInput: PublishSubject<String> = .init()
    
    convenience init(_ viewModel: ReaderShakingViewModel) {
        self.init(nibName: "ReaderShakingViewController", bundle: nil)
        self.rx.viewDidLoad
            .subscribe(onNext: {[weak self] (_) in
                self?.config(viewModel)
            })
            .disposed(by: bag)
        
        self.rx.viewDidLoad
            .bind(to: viewModel.viewDidLoad)
            .disposed(by: bag)
        
    }
    
    private func config(_ viewModel: ReaderShakingViewModel) {
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        } else {
            automaticallyAdjustsScrollViewInsets = false
        }
        title = "摇一摇"
        let btn = UIButton(type: .custom)
        btn.setImage(UIImage(named: "shaking_again"), for: .normal)
        btn.frame = CGRect(x: 0, y: 0, width: UIScreen.main.bounds.width, height: 93)
        tableView.tableHeaderView = btn
        tableView.registerNibWithCell(ShakingBookTableViewCell.self)
        tableView.registerNibWithCell(IMInfoTableViewCell.self)
        tableView.registerClassWithCell(UITableViewCell.self)
        tableView.registerNibWithCell(GDTExpressAdTableViewCell.self)
        tableView.registerNibWithCell(BUNativeFeedTableViewCell.self)
        tableView.estimatedRowHeight = 100

        viewModel.dataDriver
            .drive(tableView.rx.items(dataSource: dataSource))
            .disposed(by: bag)
        
        tableView.rx.setDelegate(self).disposed(by: bag)
        
        btn.rx.tap
            .asObservable()
            .subscribe(onNext: { [weak self](_) in
                self?.shankinng()
            })
            .disposed(by: bag)
        
        shackingInput
            .asObservable()
            .mapToVoid()
            .debug()
            .bind(to: viewModel.shackingInput)
            .disposed(by: bag)
        
        tableView.rx.modelSelected(ReaderLastPageGuessBook.self)
            .map { $0.book_id}
            .unwrap()
            .subscribe(onNext: {
                BookReaderHandler.jump($0)
            })
            .disposed(by: bag)
        
    }
    
    fileprivate func startLeftAnimation() {
        let baseAnimation = CABasicAnimation()
        baseAnimation.keyPath = "transform.rotation.z"
        baseAnimation.duration = 0.25;
        baseAnimation.fromValue = 0
        baseAnimation.toValue = Float.pi / 8
        baseAnimation.timingFunction =  CAMediaTimingFunction(name: .easeOut)
        baseAnimation.autoreverses = true
        baseAnimation.delegate = self
        baseAnimation.fillMode = .removed;
        baseAnimation.setValue("left", forKey: "name")
        container.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        container.layer.add(baseAnimation, forKey: "left")
    }
    
    fileprivate func startRightAnimation() {
        let baseAnimation = CABasicAnimation()
        baseAnimation.keyPath = "transform.rotation.z"
        baseAnimation.duration = 0.25;
        baseAnimation.fromValue = 0
        baseAnimation.toValue = -Float.pi / 8
        baseAnimation.timingFunction =  CAMediaTimingFunction(name: .easeOut)
        baseAnimation.autoreverses = true
        baseAnimation.delegate = self
        baseAnimation.fillMode = .removed;
        baseAnimation.setValue("right", forKey: "name")
        container.layer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        container.layer.add(baseAnimation, forKey: "right")
        
    }
    
    fileprivate static func cellHeightKey(_ indexPath: IndexPath) -> String {
        return "\(indexPath.section)" + "-" + "\(indexPath.row)"
    }
    
}
extension ReaderShakingViewController: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard let aniName = anim.value(forKey: "name") as? String else {
            return
        }
        if flag {
            if aniName == "left" {
                startRightAnimation()
            } else if aniName  == "right" {
                startLeftAnimation()
            }
            animaTime += 1
            if animaTime >= 4 {
                animaTime = 0
                /// 动画结束后加载数据
                shackingInput.onNext("")
                container.layer.removeAllAnimations()
            }
        }
    }
}

extension ReaderShakingViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section >= dataSource.sectionModels.count {
            return 0
        }
        let sectionModel = dataSource.sectionModels[indexPath.section]
        let model = sectionModel.items[indexPath.row]
        if let config = model.locaAdTemConfig {
            return config.uiConfig?.infoAdLoadedRealSize(config.adType).height ?? 156
        }
        return 156
    }
    
    fileprivate func shankinng() {
        startLeftAnimation()
    }
}




extension ReaderShakingViewController: AVAudioPlayerDelegate {
    override func motionBegan(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            print("Motion-BEGIN")
            audioPlayer.replaceCurrentItem(with:shakingStartAudio)
            audioPlayer.play()
            shankinng()
        }
    }
    
    override func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if shakingResult.value.isEmpty {
            audioPlayer.replaceCurrentItem(with: shakingMatchAudio)
        } else {
            audioPlayer.replaceCurrentItem(with: shakingUnMatchAudio)
        }
        audioPlayer.play()
    }
    
    override func motionCancelled(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        
    }
}
