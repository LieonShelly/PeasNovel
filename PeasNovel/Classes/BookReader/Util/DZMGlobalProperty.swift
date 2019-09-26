//
//  DZMGlobalProperty.swift
//  ReaderKit
//
//  Created by lieon on 2017/5/11.
//  Copyright © 2018年lieon. All rights reserved.
//

import UIKit

// MARK: -- 屏幕属性

/// 屏幕宽度
let ScreenWidth:CGFloat = UIScreen.main.bounds.size.width

/// 屏幕高度
let ScreenHeight:CGFloat = UIScreen.main.bounds.size.height

/// iPhone X
let isX:Bool = UIDevice.current.isiPhoneXSeries

/// 导航栏高度
let NavgationBarHeight:CGFloat = isX ? 88 : 64

/// TabBar高度
let TabBarHeight:CGFloat = 49

/// iPhone X 顶部刘海高度
let TopLiuHeight:CGFloat = 30

/// StatusBar高度
let StatusBarHeight:CGFloat = isX ? 44 : 20

// MARK: -- 全局属性

/// 段落头部双圆角空格
let DZMParagraphHeaderSpace:String = "　　"

// MARK: -- 颜色支持

/// 灰色 || 阅读背景颜色支持
let DZMColor_51_51_51:UIColor = UIColor(red: 51/255.0, green: 51/255.0, blue: 51/255.0, alpha: 1)

/// 粉红色
let DZMColor_253_85_103:UIColor = UIColor(red: 253/255.0, green: 85/255.0, blue: 103/255.0, alpha: 1)

/// 阅读上下状态栏颜色 || 小说阅读上下状态栏字体颜色
let DZMColor_127_136_138:UIColor = UIColor(red: 127/255.0, green: 136/255.0, blue: 138/255.0, alpha: 1)

/// 小说阅读颜色
let DZMColor_145_145_145:UIColor = UIColor(red: 145/255.0, green: 145/255.0, blue: 145/255.0, alpha: 1)

/// LeftView文字颜色
let DZMColor_200_200_200:UIColor = UIColor(red: 200/255.0, green: 200/255.0, blue: 200/255.0, alpha: 1)

/// 阅读背景颜色支持
let DZMColor_238_224_202:UIColor = UIColor(red: 238/255.0, green: 224/255.0, blue: 202/255.0, alpha: 1)
let DZMColor_205_239_205:UIColor = UIColor(red: 205/255.0, green: 239/255.0, blue: 205/255.0, alpha: 1)
let DZMColor_206_233_241:UIColor = UIColor(red: 206/255.0, green: 233/255.0, blue: 241/255.0, alpha: 1)
let DZMColor_251_237_199:UIColor = UIColor(red: 251/255.0, green: 237/255.0, blue: 199/255.0, alpha: 1)  // 牛皮黄

// MARK: -- 间距支持
let DZMSpace_1:CGFloat = 1
let DZMSpace_5:CGFloat = 5
let DZMSpace_10:CGFloat = 10
let DZMSpace_15:CGFloat = 15
let DZMSpace_20:CGFloat = 20
let DZMSpace_25:CGFloat = 25

// MARK: 拖拽触发光标范围
let DZMCursorOffset:CGFloat = -DZMSpace_20


// MARK: -- Key

/// 是夜间还是日间模式   true:夜间 false:日间
let DZMKey_IsNighOrtDay:String = "isNightOrDay"

/// ReadView 手势开启状态
let DZMKey_ReadView_Ges_isOpen:String = "isOpen"

// MARK: 通知名称

/// ReadView 手势通知
let DZMNotificationName_ReadView_Ges = "ReadView_Ges"

let ReaderBrightnessKey = "ReaderBrightnessKey"

let ReaderBrightnessBtnKey = "ReaderBrightnessBtnKey"
