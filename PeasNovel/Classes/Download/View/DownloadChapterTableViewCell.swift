//
//  DownloadChapterTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/23.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import HandyJSON
import RxCocoa

class DownloadChapterTableViewCell: UITableViewCell {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var progressView: UIProgressView!
    @IBOutlet weak var retryView: UIStackView!
    @IBOutlet weak var retryBtn: UIButton!
    @IBOutlet weak var waitBtn: UIButton!
    @IBOutlet weak var downloadBtn: UIButton!
    @IBOutlet weak var unlockBtn: UIButton!
    @IBOutlet weak var doneBtn: UIButton!

    var bag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        unlockBtn.layer.cornerRadius = 2
        unlockBtn.layer.borderColor = UIColor(0xDFDFDF).cgColor
        unlockBtn.layer.borderWidth = 1
        
        downloadBtn.layer.cornerRadius = 2
        downloadBtn.layer.borderColor = UIColor(0xFF6700).cgColor
        downloadBtn.layer.borderWidth = 1
        
        progressView.isHidden = true
        waitBtn.isHidden = true
        retryView.isHidden = true
        unlockBtn.isHidden = true
        doneBtn.isHidden = true
    
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        configRx()
    }

    func config( _ data: DownloadChapterGroup) {
//        print("DownloadChapterTableViewCell: status--\(data.status)---progress--\(data.progress)")
         titleLabel.text = data.title
         updateUI(data.status, progress: data.progress)
        let currentGroupId = data.id
        NotificationCenter.default.rx.notification(Notification.Name.Book.downloadInfo)
            .map { $0.userInfo as? [String: Any] }
            .map { JSONDeserializer<CurrentDonwloadChapterInfo>.deserializeFrom(dict: $0) }
            .unwrap()
            .filter { $0.id == currentGroupId}
            .bind(to: self.rx.refreshUI)
            .disposed(by: bag)
    }
    
    func updateUI(_ status: DownloadStatus, progress: Double) {
        let control = self
        switch status {
        case .downloading:
            control.progressView.isHidden = false
            control.waitBtn.isHidden = true
            control.retryView.isHidden = true
            control.unlockBtn.isHidden = true
            control.doneBtn.isHidden = true
            control.downloadBtn.isHidden = true
            control.progressView.setProgress(Float(progress), animated: true)
        case .fail:
            control.progressView.isHidden = true
            control.waitBtn.isHidden = true
            control.retryView.isHidden = false
            control.unlockBtn.isHidden = true
            control.doneBtn.isHidden = true
            control.downloadBtn.isHidden = true
            control.progressView.setProgress(Float(progress), animated: true)
            break
        case .success:
            control.progressView.isHidden = true
            control.waitBtn.isHidden = true
            control.retryView.isHidden = true
            control.unlockBtn.isHidden = true
            control.doneBtn.isHidden = false
            control.downloadBtn.isHidden = true
            control.progressView.setProgress(Float(progress), animated: true)
        case .waiting:
            control.progressView.isHidden = true
            control.waitBtn.isHidden = false
            control.retryView.isHidden = true
            control.unlockBtn.isHidden = true
            control.doneBtn.isHidden = true
            control.downloadBtn.isHidden = true
            control.progressView.setProgress(Float(progress), animated: true)
            break
        case .none:
            control.progressView.isHidden = true
            control.waitBtn.isHidden = true
            control.retryView.isHidden = true
            control.unlockBtn.isHidden = false
            control.doneBtn.isHidden = true
            control.downloadBtn.isHidden = true
            control.progressView.setProgress(Float(progress), animated: true)
        case .unlock:
            control.progressView.isHidden = true
            control.waitBtn.isHidden = true
            control.retryView.isHidden = true
            control.unlockBtn.isHidden = true
            control.doneBtn.isHidden = true
            control.downloadBtn.isHidden = false
            control.progressView.setProgress(Float(progress), animated: true)
        case .willDownload:
            control.progressView.isHidden = true
            control.waitBtn.isHidden = true
            control.retryView.isHidden = true
            control.unlockBtn.isHidden = true
            control.doneBtn.isHidden = true
            control.downloadBtn.isHidden = false
            control.progressView.setProgress(Float(progress), animated: true)
            break
        }
    }
    
    func downloadMode() {
        progressView.isHidden = true
        waitBtn.isHidden = true
        retryView.isHidden = true
        unlockBtn.isHidden = true
        doneBtn.isHidden = true
        downloadBtn.isHidden = false
    }
    
    func configRx() {
        bag = DisposeBag()
    }
    
}

extension Reactive where Base: DownloadChapterTableViewCell {
    var refreshUI: Binder<CurrentDonwloadChapterInfo> {
        return Binder<CurrentDonwloadChapterInfo>(base, scheduler: MainScheduler.instance, binding: { (control, value) in
            control.updateUI(value.status, progress: value.progress)
        })
    }
}
