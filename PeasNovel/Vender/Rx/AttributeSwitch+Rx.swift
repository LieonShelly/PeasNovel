//
//  AttributeSwitch+Rx.swift
//  PeasNovel
//
//  Created by xinyue on 2019/4/19.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import RxSwift
import RxCocoa

extension Reactive where Base : AttributeSwitch {
    
    /// Reactive wrapper for `ValueChanged` control event.
    public var isOn: ControlProperty<Bool> {
        return base.rx.controlProperty(editingEvents: UIControl.Event.valueChanged, getter: { control in
            control.on
        }, setter: { (control, value) in
            control.setOn(value, animated: true)
        })
    }
}
