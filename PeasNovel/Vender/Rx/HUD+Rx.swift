//
//  HUD+Rx.swift
//  Arab
//
//  Created by lieon on 2018/9/13.
//  Copyright © 2018年lieon. All rights reserved.
//

import PKHUD
import RxSwift
import RxCocoa

struct HUDValue {
    let type: HUDContentType
    let delay: TimeInterval
    
    init(_ type: HUDContentType, delay: TimeInterval = 2.0) {
        self.type = type
        self.delay = delay
    }
}

extension HUD {
    
    static var flash: Binder<HUDValue> {
        return PKHUD.sharedHUD.rx.flash
    }
    
    static var loading: Binder<Bool> {
        return PKHUD.sharedHUD.rx.loading
    }
    
    static var justLoading: Binder<Bool> {
        return PKHUD.sharedHUD.rx.justLoading
    }
}

extension Reactive where Base: PKHUD {
    var flash: Binder<HUDValue> {
        UIApplication.shared.keyWindow?.endEditing(true)
        return Binder<HUDValue>(base, scheduler: MainScheduler.instance, binding: { (control, value) in
            if control.isVisible { control.hide(false) }
            DispatchQueue.main.asyncAfter(deadline: .now() +  0.25, execute: {
                control.contentView = Base.contentView(value.type)
                control.show()
                control.hide(afterDelay: value.delay) { isSuccess in
                    
                }
            })
        })
    }
    
    var loading: Binder<Bool> {
        return Binder<Bool>(base, scheduler: MainScheduler.instance, binding: { (control, value) in
            let queue = DispatchQueue.main
            queue.asyncAfter(deadline: DispatchTime.now() + 0.2, execute: {
                value ? control.loading() : control.dismiss()
            })
        })
    }
    
    var justLoading: Binder<Bool> {
        return Binder<Bool>(base, scheduler: MainScheduler.instance, binding: { (control, value) in
            let queue = DispatchQueue.main
            queue.async(execute: {
                value ? control.loading() : control.dismiss()
            })
        })
    }
}

extension PKHUD {
    
    func loading() {
        self.contentView = PKHUD.contentView(.rotatingImage(nil))
        self.show(onView: UIApplication.shared.keyWindow)
    }
    
    func dismiss() {
        self.hide(false)
    }
    
    fileprivate static func contentView(_ type: HUDContentType) -> UIView {
        switch type {
        case .success: return PKHUDSuccessView()
        case .error: return PKHUDErrorView()
        case .progress: return PKHUDProgressView()
        case .image(let image): return PKHUDSquareBaseView(image: image)
        case .rotatingImage(let image):
            return PKHUDRotatingImageView(image: image, title: nil, subtitle: nil)
        case let .labeledSuccess(title, subtitle):
            return PKHUDSuccessView(title: title, subtitle: subtitle)
        case let .labeledError(title, subtitle):
            return PKHUDErrorView(title: title, subtitle: subtitle)
        case let .labeledProgress(title, subtitle):
            return PKHUDProgressView(title: title, subtitle: subtitle)
        case let .labeledImage(image, title, subtitle):
            return PKHUDSquareBaseView(image: image, title: title, subtitle: subtitle)
        case let .labeledRotatingImage(image, title, subtitle):
            return PKHUDRotatingImageView(image: image, title: title, subtitle: subtitle)
            
        case .label(let text): return PKHUDTextView(text: text)
        case .systemActivity: return PKHUDSystemActivityIndicatorView()
        case .errorTip(let text): return PKHUDErrorTipView(text)
        }
    }
}
