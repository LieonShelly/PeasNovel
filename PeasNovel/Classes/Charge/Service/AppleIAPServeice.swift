//
//  AppleIAPServeice.swift
//  Arab
//
//  Created by lieon on 2018/9/12.
//  Copyright © 2018年lieon. All rights reserved.
//

import Foundation
import StoreKit
import RxSwift
import RxCocoa
import Moya
import PKHUD

class AppleIAPServeice: NSObject {
    static let shared: AppleIAPServeice = AppleIAPServeice()
    let param: BehaviorRelay<[String: Any]> = BehaviorRelay(value: [:])
    fileprivate var disposebag = DisposeBag()
    let error = ErrorTracker()
    let activity = ActivityIndicator()

    override private init() {
        super.init()
        SKPaymentQueue.default().add(self)
        
        error.asDriver()
            .debug()
            .drive(HUD.flash)
            .disposed(by: disposebag)
        
        activity.asDriver()
            .debug()
            .drive(HUD.loading)
            .disposed(by: disposebag)
        
        param.asObservable().subscribe(onNext: { (parma) in
            if SKPaymentQueue .canMakePayments() {
                var  products = Set<String>()
                if let productId = parma["product_dentifier"] as? String {
                    products.insert(productId)
                    let request = SKProductsRequest(productIdentifiers: products)
                    request.delegate = self
                    request.start()
                    HUD.show(.progress)
                }
                
            } else {
                HUD.show(.errorTip(ErrorCode.unsupportIAP.message))
                HUD.hide(afterDelay: 2.0)
            }
        })
        .disposed(by: disposebag)
    }
    
    deinit {
        SKPaymentQueue.default().remove(self)
    }
}

extension AppleIAPServeice: SKPaymentTransactionObserver {
    func paymentQueue(_ queue: SKPaymentQueue, updatedTransactions transactions: [SKPaymentTransaction]) {
        transactions.forEach { (transation) in
            switch transation.transactionState {
            case .purchased:
                HUD.hide(animated:false)
                guard let reciepURL = Bundle.main.appStoreReceiptURL, let reciepData = try? Data(contentsOf: reciepURL, options: Data.ReadingOptions.alwaysMapped)  else {
                    HUD.show(.errorTip(ErrorCode.unsupportIAP.message))
                    HUD.hide(afterDelay: 2.0)
                    return
                }
                let reciepString = reciepData.base64EncodedString(options: .endLineWithLineFeed)
                var param = self.param.value
                param["receipt_data"] = reciepString
                if let transactionIdentifier = transation.transactionIdentifier {
                      param["transaction_id"] =  transactionIdentifier
                }
                let provider = MoyaProvider<Payservice>()
                provider
                    .rx
                    .request(Payservice.applePay(param))
                    .trackError(error)
                    .trackActivity(activity)
                    .model(NullResponse.self)
                    .debug()
                    .asObservable()
                    .subscribe(onNext: { (_) in
                        HUD.show(.label(NSLocalizedString("chargeSuccess", comment: "")))
                        NotificationCenter.default.post(name: NSNotification.Name.AppleIAP.chargeSuccess, object: nil)
                        /// 更新用户信息
                        NotificationCenter.default.post(name: NSNotification.Name.Account.expired, object: nil)
                    })
                    .disposed(by: disposebag)
                
                SKPaymentQueue.default().finishTransaction(transation)
                break
            case .failed:
                 SKPaymentQueue.default().finishTransaction(transation)
                HUD.show(.errorTip("交易失败"))
                HUD.hide(afterDelay: 2.0)
                break
            case .restored:
                 HUD.hide()
                  SKPaymentQueue.default().finishTransaction(transation)
                break
            case .purchasing:
                break
            case .deferred:
                break
            }
        }
    }

}

extension AppleIAPServeice: SKProductsRequestDelegate{
    func productsRequest(_ request: SKProductsRequest, didReceive response: SKProductsResponse) {
        if !response.products.isEmpty, let product = response.products.first  {
            let payment = SKPayment(product: product)
            SKPaymentQueue.default().add(payment)
        } else {
            HUD.show(.errorTip(ErrorCode.requestAppleProductFaile.message))
            HUD.hide(afterDelay: 2.0)
        }
    }
    
    func request(_ request: SKRequest, didFailWithError error: Error) {
        HUD.show(.errorTip(ErrorCode.requestAppleProductFaile.message))
        HUD.hide(afterDelay: 2.0)
    }
    
}

