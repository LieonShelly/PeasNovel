//
//  AppDelegate.swift
//  PeasNovel
//
//  Created by lieon on 2019/1/7.
//  Copyright © 2019O NotBroken. All rights reserved.
//

import UIKit
import Moya
import MJRefresh
import Realm
import RealmSwift
import RxSwift
import Alamofire
import AVKit
import InMobiSDK
let navigator = Navigator()
import HandyJSON
import PKHUD
import ToastSwiftFramework


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    let netManater = NetworkReachabilityManager()
    var window: UIWindow?
    var gdtSplash: GDTSplashAd?
    let bag = DisposeBag()
    let gdtFiveDelegator = FiveMinuteGDTFlashDelegator()
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        User.shared.readFromDisk()
        setupNetwork()
        configInMobi()
        configBU()
        configRealm()
        configBugly()
        configRouter()
        configShare()
        setupAnalytic()
        configRemoteEvents(application)
        configNotification()
        chooseRootVc(launchOptions)
        configGE()
        configFlash()
        // 屏蔽控制台autolayout约束内容的输出
        UserDefaults.standard.setValue(false, forKey: "_UIConstraintBasedLayoutLogUnsatisfiable")
        StatisticHandler.initialize()
        setupAudioSession()
        return true
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        UIApplication.shared.applicationIconBadgeNumber = 0
        SplashService.recordAppLeaveTime()
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        SplashService.displayFullScreenAd(application) 
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        debugPrint("application-URL:\(url.absoluteString)")
        if navigator.push(url) != nil {
            print("[Navigator] present: \(url)")
            return true
        }

        if navigator.open(url) == true {
            print("[Navigator] open: \(url)")
            return true
        }
        
        return false
    }


    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        GeTuiSdk.registerDeviceTokenData(deviceToken)
    }
    
    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        guard let webpageURL = userActivity.webpageURL else {
            return true
        }
       
        NSLog("webpageURL: \(webpageURL) - queryToParams:\(webpageURL.queryParameters)")
        let query = webpageURL.queryParameters
        guard let jump_url = query["jump_url"] else {
            return true
        }
        if let url = URL(string: jump_url) {
            navigator.push(url)
        }
        return true
    }
    
    override func remoteControlReceived(with event: UIEvent?) {
        guard let event = event else {
            return
        }
        if case event.type = UIEvent.EventType.remoteControl {
            NotificationCenter.default.post(name: NSNotification.Name.Event.appDelegateRemoteEvent, object: event)
        }
    }
    
    fileprivate func configBugly() {
        let config = BuglyConfig()
        config.reportLogLevel = .warn
        Bugly.start(withAppId: Constant.Bugly.appId, config:config)
    }

    fileprivate func configRouter() {
        URLNavigationMap.initialize(navigator: navigator)
    }
    
    fileprivate func setupAnalytic() {
        MobClick.setScenarioType(eScenarioType.E_UM_NORMAL)
        UMConfigure.setLogEnabled(false)
        UMConfigure.initWithAppkey(Constant.Umeng.appKey, channel: "App Store")
    }
    
    
    fileprivate func setupNetwork() {
        let manager = Alamofire.SessionManager.default
        manager.session.configuration.timeoutIntervalForRequest = 5
        manager.session.configuration.timeoutIntervalForResource = 5
        
        netManater?.listener =  { status in
            switch status {
            case .unknown:
              print("未知网络")
            case .notReachable:
                print("不可用的网络(未连接")
            case .reachable(let type):
                switch type {
                case .ethernetOrWiFi:
                    print("WIFI")
                case .wwan:
                    print("移动网络")
                }
            }
            NotificationCenter.default.post(name: Notification.Name.Network.networkChange, object: status)
        }
        
        netManater?.startListening()
    }
    
    
    fileprivate func configRealm() {
        let buildStr = (Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1")
        let buildNum = UInt64(buildStr) ?? 1
        let config = Realm.Configuration(schemaVersion: UInt64(buildNum),
                                         migrationBlock: { (migration, oldSchemaVersion) in
                                            if oldSchemaVersion == 1 {
                                                migration.deleteData(forType: "MessageModel")
                                            }
                                            if oldSchemaVersion == 66 { /// 线上的build号
                                                migration.deleteData(forType: "LocalSwitcherConfig")
                                                migration.enumerateObjects(ofType: ReadRecord.className(), { (oldObject, newObject) in
                                                    newObject?["writing_process"] = -1
                                                })
                                                migration.enumerateObjects(ofType: ReaderFiveChapterNoAd.className(), { (oldObject, newObject) in
                                                    newObject?["show_alert_count"] = 0
                                                    newObject?["chapter_title"] = ""
                                                })
                                            }
        })
        print("Realm Path:\n",Realm.Configuration.defaultConfiguration.fileURL?.absoluteString ?? "")
        Realm.Configuration.defaultConfiguration = config
    }
    
    fileprivate func configShare() {
        ShareSDK.registPlatforms { (register) in
            register?.setupQQ(withAppId:Constant.QQ.appId, appkey: Constant.QQ.appkey)
            register?.setupWeChat(withAppId: Constant.Wechat.appId, appSecret: Constant.Wechat.appSecret)
        }
    }
    
    fileprivate func configRemoteEvents(_ application: UIApplication) {
        let session = AVAudioSession.sharedInstance()
        try?  session.setActive(true, options: AVAudioSession.SetActiveOptions.init(rawValue: 0))
        try?  session.setCategory(AVAudioSession.Category.playback, mode: .default, options: AVAudioSession.CategoryOptions.init(rawValue: 0))
        application.beginReceivingRemoteControlEvents()
    }
    
    fileprivate func configInMobi() {
        IMSdk.initWithAccountID(Constant.InMobi.accountID)
        IMSdk.setAgeGroup(.between25And29)
    }
    
    fileprivate func chooseRootVc(_ launchOption: [UIApplication.LaunchOptionsKey: Any]?) {
     
         window = UIWindow(frame: UIScreen.main.bounds)
        if let _ = launchOption?[.url] as? URL {
             window?.rootViewController = TabBarController()
             window?.makeKeyAndVisible()
        } else  if let _ = launchOption?[UIApplication.LaunchOptionsKey.remoteNotification] {
            window?.rootViewController = TabBarController()
            window?.makeKeyAndVisible()
        } else if let _ = launchOption?[UIApplication.LaunchOptionsKey.userActivityDictionary] {
             window?.rootViewController = TabBarController()
             window?.makeKeyAndVisible()
        } else {
            let build = Int(Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1") ?? 1
            if let appConfig = CommonDataService.appConnfig(), appConfig.app_version == build {
                if  let config = AdvertiseService.advertiseConfig(AdPosition.splash), !config.is_close {
                    if let adVcc = SplashService.chooseSplashVC(config) {
                        window?.rootViewController = adVcc
                        window?.makeKeyAndVisible()
                    }
                } else {
                    window?.rootViewController = TabBarController()
                    window?.makeKeyAndVisible()
                }
            } else {
                window?.rootViewController = NavigationViewController(rootViewController: ReadFavorViewController(ReadFavorViewModel(), isFirstLaunch: true))
                let config = AppConfig()
                config.app_version = build
                CommonDataService.updateAppConfig(config)
            }
            window?.makeKeyAndVisible()
        }
    }
    
    fileprivate func configNotification() {
        NotificationCenter.default.rx.notification(Notification.Name.Advertise.splashNeedDismiss)
            .subscribe(onNext: { (_) in
                if self.window?.rootViewController is TabBarController {
                    return
                }
                for subview in  UIApplication.shared.keyWindow?.subviews ?? [] {
                    subview.removeFromSuperview()
                }
                let tabBarController = TabBarController()
                let transtition = CATransition()
                transtition.duration = 0.5
                transtition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeOut)
                UIApplication.shared.keyWindow?.layer.add(transtition, forKey: "animation")
                UIApplication.shared.keyWindow?.rootViewController = tabBarController
            })
            .disposed(by: bag)
        
        
        NotificationCenter.default.rx.notification(Notification.Name.Event.reloadApp)
            .map { $0.object as? BaseViewController }
            .unwrap()
            .subscribe(onNext: { [weak self] vc in
                let rootVC = TabBarController()
                guard let weakSelf = self else { return }
                UIView.transition(with: vc.view, duration: 0.25, options: .curveEaseInOut, animations: {
                    vc.view.removeFromSuperview()
                    for sub in UIApplication.shared.keyWindow?.subviews ?? [] {
                        sub.removeFromSuperview()
                    }
                     weakSelf.window?.rootViewController?.view = nil
                    weakSelf.window?.rootViewController = nil
                    weakSelf.window?.addSubview(rootVC.view)
                }, completion: { _ in
                    weakSelf.window?.rootViewController = rootVC
                })
            })
            .disposed(by: bag)
        
         NotificationCenter.default.rx.notification(Notification.Name.Advertise.loadFail)
            .mapToVoid()
            .flatMap {
                 DefaultWireframe.shared.promptFor(title: "", message: "广告加载失败", cancelAction: "确认", actions: [])
            }
            .subscribe()
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(NSNotification.Name.Account.flashLoginSuccess)
            .mapToVoid()
            .subscribe(onNext: { (record) in
                let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
                var record: FlashLoginTime!
                if let existedRecord = realm.objects(FlashLoginTime.self).first {
                    record = existedRecord
                } else {
                    record = FlashLoginTime()
                }
                let newRecord = FlashLoginTime(record)
                newRecord.loginNum += 1
                if newRecord.loginTime < Date().todayStartTime.timeIntervalSince1970 {
                    newRecord.loginNum = 1
                }
                newRecord.loginTime = Date().timeIntervalSince1970
                try? realm.write {
                    realm.add(newRecord, update: .all)
                }
            })
            .disposed(by: bag)

        NotificationCenter.default
            .rx.notification(UIApplication.willEnterForegroundNotification)
            .subscribe(onNext: { (_) in
                UIApplication.shared.endReceivingRemoteControlEvents()
            })
            .disposed(by: bag)
        
        NotificationCenter.default
            .rx.notification(Notification.Name.Event.appDelegateRemoteEvent)
            .map {$0.object as? UIEvent}
            .unwrap()
            .subscribe(onNext: { (event) in
                switch event.subtype {
                case .remoteControlPlay:
                    SpeechManager.share.resume()
                case .remoteControlPause:
                     SpeechManager.share.pause()
                case .remoteControlNextTrack:
                    break
                case .remoteControlPreviousTrack:
                    break
                default:
                    break
                }
            })
            .disposed(by: bag)
       
    }
    
    fileprivate func configGE() {
        GeTuiSdk.start(withAppId: Constant.GEPush.appID, appKey: Constant.GEPush.appKey, appSecret: Constant.GEPush.appSecret, delegate: self)
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.badge, .sound, .alert, .carPlay]) { (granted, error) in
            if error == nil {
                NSLog("UNUserNotificationCenter - request authorization succeeded!")
            }
        }
        UIApplication.shared.registerForRemoteNotifications()
        GTCountSDK.start(withAppId: Constant.GEShu.appID, withChannelId: "appstore")
        GInsightSDK.start( Constant.GEInsight.appID, channel: "appstore", onSuccess: { (guid) in
            if let guid = guid {
                me.getui_giuid = guid
                me.update()
            }
        }) { (errorCode) in
        }
    }
    
    fileprivate func configFlash() {
        CLShanYanSDKManager.initWithAppId(Constant.flash.appID, appKey: Constant.flash.appKey, timeOut: 5) { (result) in
            if result.error != nil {
                NSLog("Flash SDK 初始化失败:\(result.error?.localizedDescription ?? "")")
            } else {
                NSLog("Flash SDK 初始化成功")
            }
        }
    }
    
    fileprivate func configBU() {
        BUAdSDKManager.setLoglevel(BUAdSDKLogLevel.debug)
        BUAdSDKManager.setAppID(Constant.BUAd.appID)
    }
    
    fileprivate func configTeaLog() {
        let config = BDAutoTrackConfig()
        config.serviceVendor = .CN
        config.appID = Constant.TeaLog.appID
        config.appName = Constant.TeaLog.appName
        config.channel = Constant.TeaLog.channel
        config.showDebugLog = false
        config.logNeedEncrypt = true
        BDAutoTrack.start(with: config)
    }
    
    fileprivate func setupAudioSession() {
        let sesion = AVAudioSession.sharedInstance()
        do {
            try sesion.setActive(true)
        }
        catch {
            print("AVAudioSession:", error.localizedDescription)
        }
        do {
            try  sesion.setCategory(AVAudioSession.Category.playback, mode: AVAudioSession.Mode.default)
        }
        catch {
            print("AVAudioSession:", error.localizedDescription)
        }
    }
}

extension AppDelegate: GeTuiSdkDelegate {
    
    func geTuiSdkDidReceivePayloadData(_ payloadData: Data!, andTaskId taskId: String!, andMsgId msgId: String!, andOffLine offLine: Bool, fromGtAppId appId: String!) {
        /// 收到自定义消息
        Observable.just(String.init(data: payloadData, encoding: String.Encoding.utf8)!)
            .debug()
            .unwrap()
            .debug()
            .debug()
            .map { JSONDeserializer<ServerMessage>.deserializeFrom(json: $0)}
            .debug()
            .unwrap()
            .subscribe(onNext: { serverMessage in
                if serverMessage.show_type.rawValue == MessageShowType.inner.rawValue {
                    guard let realm = try? Realm(configuration: Realm.Configuration.defaultConfiguration) else {
                        return
                    }
                    let msg = GEPushMessage(serverMessage)
                    try? realm.write {
                        realm.add(msg, update: .all)
                        NotificationCenter.default.post(name: NSNotification.Name.Message.didUpdate, object: nil)
                    }
                } else {
                    self.window?.makeToast(serverMessage.content, duration: 5, position: ToastPosition.top, title: serverMessage.title, image: nil, style: ToastStyle.init(), completion: { (didTap) in
                        if didTap {
                            if let jumpURL = URL(string: serverMessage.jump_url) {
                                navigator.push(jumpURL)
                            }
                        } else {
                            print("completion without tap")
                        }
                    })
                }
               
            })
            .disposed(by: bag)
    }
    
    func geTuiSdkDidRegisterClient(_ clientId: String!) {
        NSLog("\n>>>[GeTuiSdk RegisterClient]:%@\n\n", clientId);
        if me.push_giuid != clientId {
             me.push_giuid = clientId
             me.update()
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    /// iOS 10: App在前台获取到通知
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.badge, .sound, .alert])
    }
    
    /// iOS 10: 点击通知进入App时触发
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        handleGEPush(userInfo)
        GeTuiSdk.handleRemoteNotification(userInfo)
        completionHandler()
    }
    
    
    fileprivate func handleGEPush(_ userInfo: [AnyHashable: Any]?) {
        guard let payload = userInfo?["payload"] as? String else {
                return
        }
        let message = JSONDeserializer<ServerMessage>.deserializeFrom(json: payload)
        guard let url = URL(string: message?.jump_url ?? "") else {
            return
        }
        if UIApplication.shared.canOpenURL(url) {
            _ = navigator.push(url)
        }
    }
}
