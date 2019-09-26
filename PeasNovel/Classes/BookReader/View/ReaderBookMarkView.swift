//
//  ReaderBookMarkView.swift
//  PeasNovel
//
//  Created by lieon on 2019/5/26.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit

class ReaderBookMarkView: UIView {
    @IBOutlet weak var clearBtn: UIButton!
    @IBOutlet weak var addBtn: UIButton!
    @IBOutlet weak var tableView: UITableView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        tableView.registerNibWithCell(BookMarkTableViewCell.self)
    }
    
    static func loadView() -> ReaderBookMarkView {
        guard let view = Bundle.main.loadNibNamed("ReaderBookMarkView", owner: nil, options: nil)?.first as? ReaderBookMarkView else {
            return ReaderBookMarkView()
        }
        return view
    }
}
