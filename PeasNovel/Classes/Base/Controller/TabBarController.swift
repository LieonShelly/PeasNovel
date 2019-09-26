//
//  TabBarController.swift
//  PeasNovel
//
//  Created by lieon on 2019/1/7.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RxMoya
import Moya

class TabBarController: UITabBarController {
    lazy var viewModel: RootViewModel = RootViewModel()
    var bag = DisposeBag()
  
    override func viewDidLoad() {
        super.viewDidLoad()
        configRx()
        configUI()
        setTabBarItems()
    }
    
    fileprivate func configRx() {
        viewModel.viewDidLoad.onNext(())
        viewModel.launchImageVM
            .asObservable()
            .debug()
            .subscribeOn(MainScheduler.instance)
            .map { LaunchAlertViewController($0)}
            .delay(RxTimeInterval.seconds(5), scheduler: MainScheduler.instance)
            .debug()
            .subscribe(onNext: {[weak self] vcc in
                vcc.modalPresentationStyle = .overCurrentContext
                self?.present(vcc, animated: true, completion: nil)
            })
            .disposed(by: bag)
        
        NotificationCenter.default.rx.notification(Notification.Name.Event.lancunAlertJump)
            .map { $0.object as? URL }
            .unwrap()
            .subscribe(onNext: {
                StatisticHandler.userReadActionParam["from_type"] = "101"
                navigator.push($0)
            })
            .disposed(by: bag)
    }
    
    func configUI() {
        tabBar.isTranslucent = false
        tabBar.backgroundColor = UIColor.white
        tabBar.layer.shadowOffset = CGSize(width: 0, height: -2)
        tabBar.layer.shadowRadius = 2
        tabBar.layer.shadowColor = UIColor(0xbebebe).cgColor
        tabBar.layer.shadowOpacity = 0.5
        tabBar.backgroundImage = UIImage()
        tabBar.shadowImage = UIImage()
        delegate = self
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor(0x8A8E9D)],
                                                         for: UIControl.State.normal)
        UITabBarItem.appearance().setTitleTextAttributes([NSAttributedString.Key.foregroundColor: UIColor.theme],
                                                         for: UIControl.State.selected)
        
    
        
    }
    
    fileprivate func setTabBarItemAndImage(_ recommnedNav: NavigationViewController,
                                           title: String,
                                           normalImageName: String,
                                           selectedImageName: String) {
        let tabBookshelf = UIImage(named: normalImageName)
        let tabBookshelfGray = UIImage(named: selectedImageName)
        recommnedNav.tabBarItem = UITabBarItem(title: title,
                                               image: tabBookshelf,
                                               selectedImage: tabBookshelfGray)
        recommnedNav.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor.theme, NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13)], for: UIControl.State.selected)
        recommnedNav.tabBarItem.setTitleTextAttributes([NSAttributedString.Key.foregroundColor : UIColor(0x666666), NSAttributedString.Key.font: UIFont.systemFont(ofSize: 13)], for: UIControl.State.normal)
    }
    
    func setTabBarItems() {
        let bookMallVc = BookMallViewController(BookMallViewModel())
        let bookMallVcNav = NavigationViewController(rootViewController: bookMallVc)
        setTabBarItemAndImage(bookMallVcNav,
                              title: "书城",
                              normalImageName: "book_mall_normal",
                              selectedImageName:"book_mall_selected")

        let bookShelfVc = BookShelfHomeViewController() // BookShelfViewController(BookShelfViewModel())
        let bookShelfVcNav = NavigationViewController(rootViewController: bookShelfVc)
        setTabBarItemAndImage(bookShelfVcNav,
                              title: "书架",
                              normalImageName: "book_shelf_normal",
                              selectedImageName:"book_shelf_selected")

        
        
        let boutiqueVM = BoutiqueViewModel()
        let recommendVc = BoutiqueViewController(boutiqueVM)
        let recommendVcNav = NavigationViewController(rootViewController: recommendVc)
        setTabBarItemAndImage(recommendVcNav,
                              title: "精品",
                              normalImageName: "recommend_normal",
                              selectedImageName:"recommend_selected")
        
        let userVc = UserViewController(UserViewModel())
        let userVcNav = NavigationViewController(rootViewController: userVc)
        setTabBarItemAndImage(userVcNav,
                              title: "我的",
                              normalImageName: "user_normal",
                              selectedImageName:"user_selected")

        viewControllers = [bookShelfVcNav, bookMallVcNav, recommendVcNav, userVcNav]
        selectedIndex = 0
        
      
    }
  
    
}

extension TabBarController: UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController, didSelect viewController: UIViewController) {
        NotificationCenter.default.post(name: NSNotification.Name.Statistic.clickEvent, object: "DIBU_POSITION\(self.selectedIndex + 1)_DD")
    }
}
