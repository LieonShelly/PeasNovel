//
//  NotificationExtensiion.swift
//  Arab
//
//  Created by lieon on 2018/9/5.
//  Copyright © 2018年lieon. All rights reserved.
//

import UIKit

extension Notification.Name {
    
    /// 账户信息动态通知
    struct Account {
        /// facebook
        static let facebook = Notification.Name("com.notbroken.noti.account.update")
        ///
        static let update = Notification.Name("com.notbroken.noti.account.update")
        static let needUpdate = Notification.Name("com.notbroken.noti.account.needUpdate")
        static let clear = Notification.Name("com.notbroken.noti.account.clear")
        /// 登陆成功
        static let signIn = Notification.Name("com.notbroken.noti.account.signin")
        /// 登出成功
        static let signOut = Notification.Name("com.notbroken.noti.account.signout")
        
         static let deviceLogin = Notification.Name("com.notbroken.noti.account.deviceLogin")
        /// token过期
        static let expired = Notification.Name("com.notbroken.noti.account.expired")
        ///
        static let synchronize = Notification.Name("com.notbroken.noti.account.synchronize")
        static let flashLoginFailed = Notification.Name("com.notbroken.noti.account.flashLoginFailed")
        static let flashLoginSuccess = Notification.Name("com.notbroken.noti.account.flashLoginSuccess")
    }
    
    struct AppleIAP {
        static let chargeSuccess = Notification.Name("com.notbroken.noti.AppleIAP.chargeSuccess")
    }
    
    struct UIUpdate {
        static let playing = Notification.Name("com.notbroken.noti.UIUpdate.playing")
        static let pause = Notification.Name("com.notbroken.noti.UIUpdate.pause")
        static let getVerifyCodeSuccess =  Notification.Name("com.notbroken.noti.UIUpdate.getVerifyCodeSuccess")
        static let categoryExchangeStart = Notification.Name("com.notbroken.noti.UIUpdate.categoryExchangeStart")
        static let categoryExchangePause = Notification.Name("com.notbroken.noti.UIUpdate.categoryExchangePause")
        static let bookMallColorChange = Notification.Name("com.notbroken.noti.UIUpdate.bookMallColorChange")
        static let bookMallScrollChange = Notification.Name("com.notbroken.noti.UIUpdate.bookMallScrollChange")
        static let bookMallBackTop = Notification.Name("com.notbroken.noti.UIUpdate.bookMallBackTop")
        static let bookMallHeaderViewChange = Notification.Name("com.notbroken.noti.UIUpdate.bookMallHeaderViewChange")
        static let readFavorDidChange = Notification.Name("com.notbroken.noti.UIUpdate.readFavorDidChange")
        static let adjustReadFavorAction = Notification.Name("com.notbroken.noti.UIUpdate.adjustReadFavorAction")
        static let shareSuccess = Notification.Name("com.notbroken.noti.UIUpdate.shareSuccess")
        static let shared = Notification.Name("com.notbroken.noti.UIUpdate.shared")
        static let readingTime = Notification.Name("com.notbroken.noti.UIUpdate.readingTime")
        static let readerCloseAd = Notification.Name("com.notbroken.noti.UIUpdate.readerCloseAd")
        static let readerChangeColor = Notification.Name("com.notbroken.noti.UIUpdate.readerChangeColor")
        static let readerIntroPagedidTap = Notification.Name("com.notbroken.noti.UIUpdate.readerIntroPagedidTap")
        static let loginSuccessPopBack = Notification.Name("com.notbroken.noti.UIUpdate.loginSuccessPopBack")
    }
    
    struct Statistic {
        static let bookShareSuccess = Notification.Name("com.notbroken.notiStatistic.bookShareSuccess")
        static let buyVIP = Notification.Name("com.notbroken.noti.Statistic.buyVIP")
        static let readerFiveChapterNoAd = Notification.Name("com.notbroken.noti.Statistic.readerFiveChapterNoAd")
        static let goodBookRecommend = Notification.Name("com.notbroken.noti.Statistic.goodBookRecommend")
        static let search = Notification.Name("com.notbroken.noti.Statistic.search")
        static let advertise = Notification.Name("com.notbroken.noti.Statistic.advertise")
        static let pageExposure = Notification.Name("com.notbroken.noti.Statistic.pageExposure")
        static let clickEvent = Notification.Name("com.notbroken.noti.Statistic.clickEvent")
        static let readingTime = Notification.Name("com.notbroken.noti.Statistic.readingTime")
        static let messageClick = Notification.Name("com.notbroken.noti.Statistic.messageClick")
        static let userReadAction = Notification.Name("com.notbroken.noti.Statistic.userReadAction")
        static let didClickCharge = Notification.Name("com.notbroken.noti.Statistic.didClickCharge")
    }
    
    struct Event {
        static let appDelegateRemoteEvent = Notification.Name("com.notbroken.noti.Event.appDelegateRemoteEvent")
        static let dismissAdChapter = Notification.Name("com.notbroken.noti.Event.dismissAdChapter")
        static let didDismissAdChapter = Notification.Name("com.notbroken.noti.Event.didDismissAdChapter")
        static let reloadApp = Notification.Name("com.notbroken.noti.account.reloadApp")
        static let lancunAlertJump = Notification.Name("com.notbroken.noti.account.lancunAlertJump")
        static let readerIsWorking = Notification.Name("com.notbroken.noti.account.readerIsWorking")
        static let reloadReader = Notification.Name("com.notbroken.noti.account.reloadReader")
        static let readerScrollinng = Notification.Name("com.notbroken.noti.Statistic.readerScrollinng")
    }
    
    
    struct Book {
        /// 书架更新
        static let addbookshelf  = Notification.Name("com.notbroken.noti.book.addbookshelf")
        static let bookshelf = Notification.Name("com.notbroken.noti.book.bookshelf")
        static let recently = Notification.Name("com.notbroken.noti.book.recently")
        static let deletes = Notification.Name("com.notbroken.noti.book.deletes")
//         static let didAddBookShelf = Notification.Name("com.notbroken.noti.book.addBookShelf")
        static let subscribe = Notification.Name("com.notbroken.noti.book.subscribe")
        static let addHistory = Notification.Name("AddHistory")
        static let addClick = Notification.Name("com.notbroken.noti.book.click")
        static let chapterSaveFileSuccess = Notification.Name("com.notbroken.noti.book.chapterSaveFileSuccess")
        static let downloadInfo = Notification.Name("com.notbroken.noti.book.downloadInfo")
        static let existReader = Notification.Name("com.notbroken.noti.book.existReader")
        static let didChangeChapter = Notification.Name("com.notbroken.noti.book.didChapter")
        static let chapaterIsLastpage = Notification.Name("com.notbroken.noti.book.chapaterIsLastpage")
        static let smallReaderAddCollect  = Notification.Name("com.notbroken.noti.book.smallReaderAddCollect")
        struct ListenBook {
            static let goToPage = Notification.Name("com.notbroken.noti.book.goToPage")
            static let showErrorAlert = Notification.Name("com.notbroken.noti.book.showErrorAlert")
            static let didStopAllTask = Notification.Name("com.notbroken.noti.book.didStopAllTask")
            static let statusCallback = Notification.Name("com.notbroken.noti.book.statusCallback")
            static let onePageListenEnd = Notification.Name("com.notbroken.noti.book.onePageListenEnd")
            static let oneChapterListenEnd = Notification.Name("com.notbroken.noti.book.oneChapterListenEnd")
            static let didStartAllTask = Notification.Name("com.notbroken.noti.book.didStartAllTask")
        }
        static let readerViewHandling =  Notification.Name("com.notbroken.noti.book.readerViewHandling")
        static let readerViewClickReportError =  Notification.Name("com.notbroken.noti.book.readerViewClickReportError")
        static let readerViewDidClick =  Notification.Name("com.notbroken.noti.book.readerViewDidClick")
        static let didLoadBookIntroPage = Notification.Name("com.notbroken.noti.book.didLoadBookIntroPage")
        static let didDisappearBookIntroPage = Notification.Name("com.notbroken.noti.book.didDisappearBookIntroPage")
        static let didChangeReaderEffect = Notification.Name("com.notbroken.noti.book.didChangeReaderEffect")
        static let bottomBannerHeightDidChange = Notification.Name("com.notbroken.noti.book.bottomBannerHeightDidChange")
        
        static let didLoadReaderLastPage = Notification.Name("com.notbroken.noti.book.didLoadReaderLastPage")
    }
    
    struct Advertise {
        static let show = Notification.Name("com.notbroken.noti.account.show")
        static let configDidUpdate = Notification.Name("com.notbroken.noti.account.configUpdate")
        static let configNeedUpdate = Notification.Name("com.notbroken.noti.account.configNeedUpdate")
        static let splashNeedDismiss = Notification.Name("com.notbroken.noti.account.splashNeedDismiss")
        static let rewardVideoAdWillDismiss = Notification.Name("com.notbroken.noti.account.rewardVideoAdWillDismiss")
          static let inVideoViewModelWillDismiss = Notification.Name("com.notbroken.noti.account.inVideoViewModelWillDismiss")
        static let loadFail = Notification.Name("com.notbroken.noti.account.loadFail")
        static let rewardVideoLoadSuccess = Notification.Name("com.notbroken.noti.account.rewardVideoLoadSuccess")
        /// 广告加载失败
        static let fisrtTypeLoadFail = Notification.Name("com.notbroken.noti.account.fisrtTypeLoadFail")
        /// 保底广告1加载失败
        static let secondTypeLoadFail = Notification.Name("com.notbroken.noti.account.secondTypeLoadFail")
        /// 所有类型的广告都加载失败了
        static let allTypeLoadFail = Notification.Name("com.notbroken.noti.account.allTypeLoadFail")
        static let loadSuccess = Notification.Name("com.notbroken.noti.account.loadSuccess")
        static let presentRewardVideoAd = Notification.Name("com.notbroken.noti.account.presentRewardVideoAd")
        static let presentChapterConnectAd = Notification.Name("com.notbroken.noti.account.presentChapterConnectAd")
        static let bookMallCategoryLoadFail = Notification.Name("com.notbroken.noti.account.bookMallCatehoryLoadFail")
        static let clickClose = Notification.Name("com.notbroken.noti.account.clickClose")
        static let bannerNeedRefresh = Notification.Name("com.notbroken.noti.account.bannerNeedRefresh")
    }
    
    struct Network {
        static let networkChange = Notification.Name("com.notbroken.noti.account.networkChage")
    }
    struct Message {
        static let didUpdate = Notification.Name("com.notbroken.noti.account.messageDidUpdate")
    }
}
