//
//  DownloadCenterTableViewCell.swift
//  PeasNovel
//
//  Created by lieon on 2019/4/8.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa

class DownloadCenterTableViewCell: UITableViewCell {
    var bag = DisposeBag()
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var desclabel: UILabel!
    @IBOutlet weak var deletebtn: UIButton!
    @IBOutlet weak var cover: UIImageView!
    @IBOutlet weak var reloadBtn: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        configRx()
        reloadBtn.isHidden = true
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        configRx()
    }
    
    func configRx() {
        bag = DisposeBag()
    }
    
    func config(_ title: String?, name: String?, desc: String?, imageURLStr: String?) {
        titleLabel.text = title
        authorLabel.text = name
        desclabel.text = desc
        if let imageURL = URL(string: imageURLStr ?? "") {
            cover.kf.setImage(with: imageURL)
        } else {
            cover.image = nil
        }
        
    }
    
    func config(_ model: DownloadLocalBook) {
        titleLabel.text = model.book_title
        authorLabel.text = "作者: " + model.author
        if let imageURL = URL(string: model.cover_img) {
            cover.kf.setImage(with: imageURL)
        } else {
            cover.image = nil
        }
        reloadBtn.isHidden = true
        let dowloadStatus = DownloadStatus(rawValue: model.dowloadStatus) ??  DownloadStatus.none
        switch dowloadStatus {
        case .success:
            desclabel.text = dowloadStatus.desc + "\(model.download_chapter_count)" + "章节" + " 共" + FileService.fileSizeDesc(Float(model.download_size))
        case .fail:
            reloadBtn.isHidden = false
            desclabel.text = dowloadStatus.desc
        case .none:
            reloadBtn.isHidden = false
            desclabel.text = dowloadStatus.desc
        default:
            desclabel.text = dowloadStatus.desc
        }
    }
    
}
