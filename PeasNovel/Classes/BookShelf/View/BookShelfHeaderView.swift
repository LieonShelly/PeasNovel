//
//  BookShelfHeaderView.swift
//  PeasNovel
//
//  Created by lieon on 2019/3/29.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RealmSwift

class BookShelfHeaderView: UIView {
    @IBOutlet weak var timeLabelCenter: NSLayoutConstraint!
    @IBOutlet weak var cover: UIImageView!
    @IBOutlet weak var subReadLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var adBtn: UIButton!
    @IBOutlet weak var searchBtn: UIButton!
    @IBOutlet weak var msgBtn: UIButton!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var badgeLabel: UILabel!
    @IBOutlet weak var recentBtn: UIButton!
    @IBOutlet weak var navigationTop: NSLayoutConstraint!
    @IBOutlet weak var activity: UIActivityIndicatorView!
    @IBOutlet weak var navigationHeight: NSLayoutConstraint!
    @IBOutlet weak var msgLabel: UILabel!
    @IBOutlet weak var searchLabel: UILabel!
    @IBOutlet weak var adLabel: UILabel!
    @IBOutlet weak var recentLabel: UILabel!
    @IBOutlet weak var lastView: UIView!
    @IBOutlet weak var navigationBar: UIView!
    @IBOutlet weak var readingName: UILabel!
    @IBOutlet weak var sreadTimeDesc0: UILabel!
    @IBOutlet weak var sreadTimeDesc1: UILabel!
    @IBOutlet weak var readTimeDesc: UILabel!
    
    @IBOutlet weak var statusLabel: UILabel!
    
    var bag = DisposeBag()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        /// 获取阅读时间
          timeLabel.text = "\(me.day_minute ?? 0)"
        /// 获取监听阅读时间
        NotificationCenter.default.rx.notification(Notification.Name.Account.update)
            .map { _ in me.day_minute}
            .unwrap()
            .subscribe(onNext: { [weak self] (record) in
               self?.timeLabel.text = "\(record)"
            })
            .disposed(by: bag)
        adBtn.layer.cornerRadius = 3
        adBtn.layer.masksToBounds = true
        
    }
    
    static func loadView() -> BookShelfHeaderView {
        guard let view = Bundle.main.loadNibNamed("BookShelfHeaderView", owner: nil, options: nil)?.first as? BookShelfHeaderView else {
            return BookShelfHeaderView()
        }
        view.badgeLabel.layer.cornerRadius = 9
        view.badgeLabel.layer.masksToBounds = true
        return view
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        navigationTop.constant = UIApplication.shared.statusBarFrame.height
    }
    
}

extension Reactive where Base: BookShelfHeaderView {
    var info: Binder<BookInfo?> {
            return Binder<BookInfo?>(base, scheduler: MainScheduler.instance, binding: { (control, value) in
                if let value = value {
                    let url = URL(string: value.cover_url ?? "")
                    control.cover.kf.setImage(with: url, placeholder: UIImage())
                    control.lastView.isHidden = false
                    control.readingName.text = "正在阅读《\(value.book_title ?? "")》)"
                    var readingtext: String = ""
                    if let order = DZMReadRecordModel.readRecordModel(bookID: value.book_id).readChapterModel?.order {
                        readingtext = "读至\(order == 0 ? 1: order)章"
                    } else if let c_order = value.c_order {
                        readingtext = "读至\(c_order)章"
                    } else {
                        readingtext = "未读"
                    }
                    let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
                    if let object = realm.objects(LocalBookLatestCateLog.self).filter(NSPredicate(format: "id = %@", value.book_id )).first {
                        control.subReadLabel.text = readingtext + "  |  " + "更新至\(object.order)章"
                    } else {
                        control.subReadLabel.text = readingtext
                    }
                    control.statusLabel.text = value.writing_process.desc
                } else {
                    control.lastView.isHidden = true
                }
            })
    }
    
    var refreshStatus: Binder<BookShelfHeaderRefreshStatus> {
        return Binder<BookShelfHeaderRefreshStatus>(base, scheduler: MainScheduler.instance, binding: { (control, value) in
            control.activity.isHidden = value.rawValue != BookShelfHeaderRefreshStatus.refreshing.rawValue
            if BookShelfHeaderRefreshStatus.refreshing.rawValue == value.rawValue {
                control.activity.startAnimating()
            } else {
                control.activity.stopAnimating()
            }
        })
    }
    
    var unReadmessageCount: Binder<Int> {
        return Binder<Int>(base, scheduler: MainScheduler.instance, binding: { (control, value) in
            control.badgeLabel.text = "\(value)"
            control.badgeLabel.isHidden = value == 0
        })
    }
}
