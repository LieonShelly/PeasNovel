//
//  Service.swift
//  PeasNovel
//
//  Created by lieon on 2019/1/9.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import UIKit
import Moya


protocol AppTargetType: TargetType {
    var publicParam: [String: Any] { get}
}

extension AppTargetType {
    var baseURL: URL {
        return URL(string: "https://open.kxxsc.com")!
    }
    
    var headers: [String : String]? {
        return nil
    }
    
    var publicParam: [String: Any] {
        var param: [String: Any] = [String: Any]()
        if let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] {
            param["version_name"] = version
            param["app_version"] = version
        }
        param["device_id"] = me.device_id ?? ""
        param["islogin"] = me.isLogin ? "1": "0"
        param["channel_id"] = "AppStore"
        param["site"] = me.sex.rawValue
        param["sex"] = me.sex.rawValue
        param["app_id"] = "82524829"
        param["app_key"] = "3158634213"
        param["req_time"] = "\(Int(Date().timeIntervalSince1970 * 100000))"
        if let userId = me.user_id, !userId.isEmpty {
             param["user_id"] = userId
        }
        if !me.registration_id.isEmpty {
            param["registration_id"] = me.registration_id
        }
        if !me.push_giuid.isEmpty {
             param["push_giuid"] = me.push_giuid
        }
        if !me.getui_giuid.isEmpty {
            param["getui_giuid"] = me.getui_giuid
        }
        if let origin = me.origin, !origin.isEmpty {
            param["origin"] = origin
        }
        return param
    }
    
    var sampleData: Data {
        return Data()
    }

    func genertateAppToken( _ param: [String: Any]) -> String {
        var currentParam = [String: String]()
        for (key, value) in param {
            if let invalue = value as? Int {
                currentParam[key] =  String(invalue)
            } else if let floatvalue = value as? Float {
                currentParam[key] =  String(floatvalue)
            } else if let doublevalue = value as? Double {
                currentParam[key] =  String(doublevalue)
            }
            currentParam[key] = "\(value)"
           
        }
        let filterKeys = ["app_key", "post_change_get", "__flush_cache", "app_token"]
        for (key, value) in param {
            if filterKeys.contains(key) {
                currentParam.removeValue(forKey: key)
            }
            if value is Array<Any> {
                currentParam.removeValue(forKey: key)
            }
        }
        currentParam["app_secret"] = Constant.AppConfig.secret
       let sortedParams = currentParam.sorted {$0.key < $1.key}
        var temArray = [String]()
        for keyValue in sortedParams {
            let key = keyValue.key
            let value = keyValue.value
            let newStr = key + "=" + value
            temArray.append(newStr)
        }
        var token = temArray.joined(separator: "&")
//        print("before=======:", token)
        token = token.md5()
//        print("after=======:", token)
        return token
    }
    
}

enum Payservice: AppTargetType {
    /// 商品列表
    case goodsList
    /// 支付校验接口
    case applePay([String: Any])
    /// 充值记录
    case record(Int)
    
    case jdExchange([String: String])
    
    var method: Moya.Method {
        switch self {
        case .goodsList, .record, .jdExchange:
            return .get
        default:
            return .post
        }
    }
    
    var path: String {
        switch self {
        case .goodsList:
            return "/app/vippayconf/applists"
        case .applePay:
            return "/yd/pay/iosappasyncv2"
        case .record:
            return "/app/userfreead/li"
        case .jdExchange:
            return "/app/doudouv4/jd/exchange"
        }
    }
    
    
    var param: [String: Any] {
        var param = publicParam
        switch self {
        case .applePay(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .jdExchange(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .record(let page):
            param["page"] = page
            param["num"] = 20
        default:
            break
        }
        let token = genertateAppToken(param)
        param["app_token"] = token
        return param
    }
    
    var task: Task {
        return .requestParameters(parameters: param, encoding: URLEncoding.default)
    }
}

enum VerifyCodeService: AppTargetType {
    case textVerifyCode([String: Any])
    /// 获取拼图认证信息
    case getPictureCaptcha([String: Any])
    /// 拼图认证+验证码发送
    case verifyPictureCaptcha([String: String])
    /// 拼图认证+语音验证码
    case audioCodePictureCaptcha([String: String])
    
    var path: String {
        switch self {
        case .textVerifyCode:
            return "/app/phone/sendmsg"
        case .getPictureCaptcha:
            return "/saf/captcha/init"
        case .verifyPictureCaptcha:
            return "/app/phone/captchacheck"
        case .audioCodePictureCaptcha:
            return "/app/phone/captchavoicecheck"
        }
    }
    
    var param: [String: Any] {
        var param = publicParam
        switch self {
        case .textVerifyCode(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .getPictureCaptcha(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .verifyPictureCaptcha(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .audioCodePictureCaptcha(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }

        }
       let token = genertateAppToken(param)
       param["app_token"] = token
      return param
    }
    
    var method: Moya.Method {
        return .post
    }
    
    var task: Task {
        return .requestParameters(parameters: param, encoding: URLEncoding.default)
    }
}


enum UserCenterService: AppTargetType {
    case defaultLogin
    case deviceLogin
    case phoneNumLogin([String: Any])
    case nicknameEdit(String)
    case avatarEdit(URL)
    case signOut
    case userInfo
    /// 获取用户风险系数
    case getUserSafeRatio([String: Any])
    case editUserInfo([String: Any])
    /// 单点登录
    case sso
    /// 闪验 - 手机号一键登录
    case flashLoing([String: String])
    
    var path: String {
        switch self {
        case .defaultLogin:
            return "/yd/user/app"
        case .nicknameEdit:
            return "/user/ucenter/nick_name"
        case .signOut:
            return "/yd/user/app"
        case .deviceLogin:
            return "/yd/user/app"
        case .phoneNumLogin:
            return "/app/user/login_register"
        case .userInfo:
            return "/app/user/baseinfo"
        case .getUserSafeRatio:
            return "/app/doudouv4/saf/usercoefficient"
        case .avatarEdit:
            return "/user/ucenter/avatar"
        case .editUserInfo:
            return "/app/user/edit"
        case .sso:
            return "/app/usersso/login"
        case .flashLoing:
            return "/app/user/shanyan_login"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .phoneNumLogin, .userInfo, .getUserSafeRatio, .sso, .flashLoing:
            return .get
        default:
            break
        }
        return .post
    }
    
    
    var param: [String: Any] {
        var param = publicParam
        switch self {
        case .phoneNumLogin(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .flashLoing(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
                param["device_id"] = me.device_id ?? ""
            }
        case .getUserSafeRatio(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .userInfo:
            param["get_master_info"] = 1
            param["get_account_info"] = 1
            param["get_phone_info"] = 1
            param["get_read_time_info"] = 1
        case .editUserInfo(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .deviceLogin:
            param = [String: Any]()
            if let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] {
                param["version_name"] = version
                param["app_version"] = version
            }
            param["device_id"] = me.device_id ?? ""
            param["islogin"] = "0"
            param["channel_id"] = "AppStore"
            param["site"] = me.sex.rawValue
            param["sex"] = me.sex.rawValue
            param["app_id"] = "82524829"//"82524829"
            param["app_key"] = "8569786663"//3158634213" //"8569786663"
            param["req_time"] = "\(Int(Date().timeIntervalSince1970 * 100000))"
            if !me.registration_id.isEmpty {
                param["registration_id"] = me.registration_id
            }
        default:
            break
        }
        let token = genertateAppToken(param)
        param["app_token"] = token
        return param
    }
    
 
    var task: Task {
        switch self {
        case .avatarEdit(let url):
            let provider = MultipartFormData.FormDataProvider.file(url)
            let data = MultipartFormData(provider: provider, name: "file")
            return .uploadCompositeMultipart([data], urlParameters: param)
        default:
            return .requestParameters(parameters: param, encoding: URLEncoding.default)
        }
       
    }
    
    
    
}

/// 阅读偏好
enum ReadFavorService: AppTargetType {
    /// 跳过
    case jumpSetting
    /// 阅读偏好-添加修改删除
    case upsertOrRemove([String: Any])
    /// 阅读偏好-获取用户设定
    case getSeetings
    /// 阅读偏好-分类信息
    case categoryList
    
    var path: String {
        switch self {
        case .jumpSetting:
            return "/app/doudouv4/readcategory/skip"
        case .upsertOrRemove:
            return "/app/doudouv4/readcategory/add"
        case .getSeetings:
            return "/app/doudouv4/readcategory/lists"
        case .categoryList:
            return "/app/doudouv4/readcategory/category"
        }
    }
    
    var method: Moya.Method {
        return .get
    }
    
    var param: [String: Any] {
        var param = publicParam
        switch self {
        case .upsertOrRemove(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        default:
            break
        }
        let token = genertateAppToken(param)
        param["app_token"] = token
        return param
    }
    
    
    var task: Task {
        return .requestParameters(parameters: param, encoding: URLEncoding.default)
    }
    
    
}



enum BookMallService: AppTargetType {
    /// 精选-轮播图+重磅推荐
    case bannerAndSpecialRecommend
    /// 精选-推荐位内容
    case recommendPostion
    /// 精选-其他分类推荐书籍
    case otherRecommendBook([String: Any])
    /// 精选-其他分类列表/万人精选
    case otherRecommendCategoryBookList([String: Any])
    /// 精选-换一换
    case changeRecommend([String: String])
    
    case recommendPostionDetail([String: String])
    
    var path: String {
        switch self {
        case .bannerAndSpecialRecommend:
            return "/app/doudouv4/bookcity/jingxuan_top"
        case .recommendPostion:
            return "/app/doudouv4/bookcity/jingxuan"
        case .otherRecommendBook:
            return "/app/doudouv4/bookcity/category"
        case .otherRecommendCategoryBookList:
            return "/app/doudouv4/bookcity/booklists"
        case .changeRecommend:
            return "/app/doudouv4/bookcity/huanyihuan"
        case .recommendPostionDetail:
            return "/app/doudouv4/bookcity/tuijianwei2"
        }
    }
    
    var method: Moya.Method {
        return .get
    }
    
    var param: [String: Any] {
        var param = publicParam
        switch self {
        case .bannerAndSpecialRecommend:
            param["page"] = 1
        case .otherRecommendBook(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .changeRecommend(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .otherRecommendCategoryBookList(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .recommendPostionDetail(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        default:
            break
        }
        let token = genertateAppToken(param)
        param["app_token"] = token
        return param
    }
    
    
    var task: Task {
        return .requestParameters(parameters: param, encoding: URLEncoding.default)
    }
    
}

enum SearchService: AppTargetType {
    case searchHot
    /// page, book_title
    case search(String, Int)
    case searchWebSwitch
    /// 搜狗链接加入收藏
    case addSogouLink([String: String])
    /// 搜狗链接-是否加入收藏
    case isAddSogouLink([String: String])
    /// 搜索-猜你喜欢
    case searchRecommend
    
    var path: String {
        switch self {
        case .searchHot:
            return "/app/appbook/huoquremenbiaoqianbypage"
        /// 搜索动作
        case .search:
            return "/app/doudouv4/book/search"
        case .searchWebSwitch:
            return "/app/switchcraft/config"
        case .addSogouLink:
            return "/app/doudouv4/linkcollect/add"
        case .isAddSogouLink:
            return "/app/doudouv4/linkcollect/join"
        case .searchRecommend:
            return "/app/doudouv4/book/searchPageRecommend"
        }
    }
    
    var method: Moya.Method {
        return .get
    }
    
    var param: [String: Any] {
        var param = publicParam
        switch self {
        case .searchHot:
            param["type_name"] = "search_remenbiaoqian"
            param["page"] = 1
            param["num"] = 6
            param["site"] = 0
            param["user_id"] = me.user_id ?? ""
        case .search(let title, let page):
            param["user_id"] = me.user_id ?? ""
            param["get_category_info"] = 1
            param["num"] = 20
            param["page"] = page
            param["book_title"] = title
        case .searchWebSwitch:
            param["user_id"] = me.user_id ?? ""
            param["channel_id"] = 0
        case .addSogouLink(let inputparam):
            for (key, value) in inputparam {
                param[key] = value
            }
        case .isAddSogouLink(let inputparam):
            for (key, value) in inputparam {
                param[key] = value
            }
        case .searchRecommend:
            break
        }
        let token = genertateAppToken(param)
        param["app_token"] = token
        return param
    }
    
    
    var task: Task {
        return Task.requestParameters(parameters: param, encoding: URLEncoding.default)
    }
    
    
}

enum BookInfoService: AppTargetType {
    /// 书架收藏
    case bookshelf(page: Int)
    /// 书架推荐书籍
    case bookshelfDefault
    /// 书籍详情 book_id
    case detail(String)
    /// 加入书架 book_id book_type: 0-书籍，2-书单
    case add(String, Int)
    /// 删除 book_ids 以因为逗号分隔，book_type 以英文逗号分隔
    case delete(String, String)
    /// 目录 book_id, page 分页, order 是否倒序
    case catalog(String,page: Int,order: Bool)
    /// 完本
    case popularFinal(Int, Gender)
    /// 经典完本
    case classicFinal(Int, Gender)
    /// 排行 @order_type click (人气榜) | collect (收藏榜) | wanben (完本榜) gender 性别 page 页码
    case ranking(String, Gender, Int)
    /// 分类
    case classify
    /// 书城 - 分类 - 子分类
    case childClassify([String: String])
    /// 分类书籍列表, category_id_1,category_id_2, page
    case classifyBookList(String,String,Int)
    /// 精选书单
    case bookSheetChoice(Int)
    /// 书单详情 书单id
    case bookSheetDetail(String)
    /// 新书抢先看
    case newBookList(Int)
    /// 最近阅读更多
    case recently(Int)
    /// 删除最近阅读
    case recentlyDel(String)
    /// 好书推荐-换一换
    case goodBookRecommend([String: String])
    /// 好书推荐-往期推荐
    case historyRecommend([String: String])
    /// 最近阅读
    case recentRead
    
    
    var path: String {
        switch self {
        case .bookshelf:
            return "/app/doudouv4/bookcase/lists"
        case .bookshelfDefault:
            return "/app/doudouv4/bookcase/liststop"
        case .detail:
            return "/app/doudouv4/book/details"
        case .add:
            return "/app/doudouv4/bookcase/add"
        case .delete:
            return "/app/doudouv4/bookcase/del"
        case .catalog:
            return "/app/chapter/lists"
        case .popularFinal:
            return "/app/appbook/huoqudanbenshujibypage"
        case .classicFinal:
            return "/app/appbook/huoqujingdianwanjiebypage"
        case .ranking:
            return "/app/book/xiaoshuopaihang"
        case .classify:
            return "/app/appbook/huoqujingxuanfenlei"
        case .classifyBookList:
            return "/app/appbook/huoqufenleiliebiao"
        case .bookSheetChoice:
            return "/app/doudouv4/boutiquebook/get_boutique_book_list"
        case .bookSheetDetail:
            return "/app/doudouv4/boutiquebook/get_boutique_book_info"
        case .childClassify:
            return "/app/appbook/huoqujingxuanfenleitab"
        case .newBookList:
            return "/app/appbook/huoqudanbenshujimore"
        case .recently:
            return "/app/userread/lists"
        case .recentlyDel:
            return "/app/userread/del"
        case .goodBookRecommend:
            return "/app/doudouv4/bookcase/hstj_huanyihuan"
        case .historyRecommend:
            return "/app/doudouv4/hstj/history"
        case .recentRead:
            return "/app/doudouv4/bookcase/liststopV3"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .recentlyDel:
            return .post
        default:
            return .get
        }
    }
    
    var param: [String: Any] {
        var param = publicParam
        switch self {
        case .bookshelf(page: let page):
            param["page"] = page
            param["num"] = 200
            param["__flush_cache"] = "1"
        case .bookshelfDefault:
            break
        case .detail(let bookId):
            param["book_id"] = bookId
        case .add(let bookId, let type):
            param["book_id"] = bookId
            param["book_type"] = type
        case .delete(let bookIds, let types):
            param["book_ids"] = bookIds
            param["book_type"] = types
        case .catalog(let bookId, page: let page, order: let order):
            param["page"] = page
            param["num"] = 50
            param["book_id"] = bookId
            param["order_by"] = order ? "order asc": "order desc"
        case .popularFinal(let page, let gender):
            param["page"] = page
            param["type_name"] = (gender == .male) ? "jingxuan_nanpinrenqiwanben" : "jingxuan_nvpinrenqiwanben"
        case .classicFinal(let page, let gender):
            param["page"] = page
            param["site"] = gender.rawValue
        case .ranking(let type, let gender, let page):
            param["order_type"] = type
            param["page"] = page
            param["site"] = gender.rawValue
        case .classify:
            param.removeValue(forKey: "sex")
            param.removeValue(forKey: "site")
        case .classifyBookList(let cid1, let cid2, let page):
            param["category_id_1"] = cid1
            param["category_id_2"] = cid2
            param["page"] = page
        case .bookSheetChoice(let page):
            param["num"] = 20
            param["page"] = page
        case .bookSheetDetail(let id):
            param["id"] = id
        case .childClassify(let inputparam):
            for (key, value) in inputparam {
                param[key] = value
            }
        case .newBookList(let page):
            param["type_name"] = "jingxuan_xinshuqiangxian"
            param["num"] = 20
            param["page"] = page
        case .recently(let page):
            param["page"] = page
            param["num"] = 30
            param["get_intro_info"] = 1
            param.removeValue(forKey: "sex")
            param.removeValue(forKey: "site")
        case .recentlyDel(let ids):
            param["book_type"] = 0
            param["book_ids"] = ids
        case .goodBookRecommend(let inputparam):
            for (key, value) in inputparam {
                param[key] = value
            }
        case .historyRecommend(let inputparam):
            for (key, value) in inputparam {
                param[key] = value
            }
        case .recentRead:
            break
        }
        param["user_id"] = me.user_id ?? ""// userId
        let token = genertateAppToken(param)
        param["app_token"] = token
        return param
    }
    
    var task: Task {
        return .requestParameters(parameters: param, encoding: URLEncoding.default)
    }
}

enum BoutiqueService: AppTargetType {
    
    case boutiqueList
    case boutiqueActive
    
    var path: String {
        switch self {
        case .boutiqueList:
            return "/app/doudouv4/boutiquebook/get_boutique_list"
        case .boutiqueActive:
            return "/app/doudouv4/boutiquebook/active"
        }
    }
    
    var method: Moya.Method {
        return .get
    }
    
    var param: [String: Any] {
        var param = publicParam
        switch self {
            
        case .boutiqueList, .boutiqueActive:
            break
        }
        let token = genertateAppToken(param)
        param["app_token"] = token
        return param
    }
    
    var task: Task {
        return .requestParameters(parameters: param, encoding: URLEncoding.default)
    }
    
    
}

enum BookReaderService: AppTargetType {
    /// 章节内容
    case chapterContent([String: String])
    /// 章节内容-分享
    case shareContent([String: String])
    /// 摇一摇
    case shaking
    /// 猜你喜欢
    case guesLike([String: String])
    /// 更新书籍通知-添加
    case addBookUpdateBNoti([String: String])
    /// 更新书籍通知-删除
    case deleteBookUpdateNoti([String: String])
    /// 更新书籍通知-查询
    case getBookUpdateBNoti([String: String])
    /// 获取书籍所有章节
    case getAllChapter([String: String])
    /// 获取每个章节的推荐书籍
    case getPerChapterRecommendBook([String: String])
    /// 章节报错
    case chapterReportError([String: String])
    /// 搜狗关键字
    case sogouKewords
    case listenBook
    var path: String {
        switch self {
        case .chapterContent:
            return "/app/doudouv4/chapter/content"
        case .shareContent:
            return "/app/chapter/shareinfo"
        case .shaking:
            return "/app/morebook/iosapplists"
        case .guesLike:
            return "/app/book/ioslike"
        case .addBookUpdateBNoti:
            return "/app/userbooknotice/add"
        case .deleteBookUpdateNoti:
            return "/app/userbooknotice/del"
        case .getAllChapter:
            return "/app/chapter/allchapters"
        case .getBookUpdateBNoti:
            return "/app/userbooknotice/one"
        case .getPerChapterRecommendBook:
            return "/app/doudouv4/chapter/recommend_in_end_of_chapter"
        case .chapterReportError:
            return "/app/doudouv4/chapterfeedback/add"
        case .sogouKewords:
            return "/app/doudouv4/keyword/readpage"
        case .listenBook:
            return "/app/user/listen_ad_info"
        }
    }
    
    var param: [String: Any] {
        var param = publicParam
        switch self {
        case .chapterContent(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
            param["auto_buy"] = 1
        case .shareContent(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .guesLike(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .deleteBookUpdateNoti(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .addBookUpdateBNoti(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .getAllChapter(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .getBookUpdateBNoti(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .getPerChapterRecommendBook(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .chapterReportError(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .shaking:
            param["type_name"] = "yaoyiyao"
        case .sogouKewords, .listenBook:
            break
        }
        let token = genertateAppToken(param)
        param["app_token"] = token
        return param
    }
    
    var method: Moya.Method {
        switch self {
        case .addBookUpdateBNoti,
             .deleteBookUpdateNoti,
             .chapterReportError:
            return .post
        default:
            break
        }
        return .get
    }
    
    
    var task: Task {
        return .requestParameters(parameters: param, encoding: URLEncoding.default)
    }
}



enum DownloadService: AppTargetType {
    /// 书籍下载-获取章节分组
    case chapterGroup([String: String]) // book_id
    /// 书籍下载-获取章节内容
    case chapterContent([String: String])
    /// 书籍下载-扣费
    case payChapter([String: String])
    /// 充值
    case charge
    /// 书籍下载-获取书籍内容
    case downloadedBooks
    
    var path: String {
        switch self {
        case .chapterGroup:
            return "/app/chapter/download_chapter"
        case .chapterContent:
            return "/app/chapter/ios_download_content"
        case .payChapter:
            return "/app/chapter/mfxsj_download_make"
        case .charge:
            return "/app/user/mfxsj_baseinfo"
        case .downloadedBooks:
            return "/app/chapter/download_book"
        }
    }
    
    var param: [String: Any] {
        var param = publicParam
        switch self {
        case .chapterGroup(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .chapterContent(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .charge:
            param["get_account_info"] = 1
        case .payChapter(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .downloadedBooks:
            break
        }
        let token = genertateAppToken(param)
        param["app_token"] = token
        return param
    }
    
    var method: Moya.Method {
        switch self {
        case .payChapter:
            return .post
        default:
            break
        }
        return .get
    }
    
    
    var task: Task {
        return .requestParameters(parameters: param, encoding: URLEncoding.default)
    } 
}

enum FeedbackService: AppTargetType {
    /// 帮助与反馈 - 常见问题分类
    case questionsList
    ///  常见问题分类 - 分类详情
    case questionDetailList([String: String])
    /// 意见与反馈
    case feedback([String: String])
    /// 客服QQ
    case serviceQQ([String: String])
    /// 我的反馈
    case myFeedback
    
    var path: String {
        switch self {
        case .questionDetailList:
            return "/app/question/lists"
        case .questionsList:
            return "/app/questioncategory/lists"
        case .feedback:
            return "/app/suggest/add"
        case .serviceQQ:
            return "/app/customerqq/lists"
        case .myFeedback:
            return "/app/suggest/lists"
        }
    }
    
    var param: [String: Any] {
        var param = publicParam
        switch self {
        case .feedback(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .serviceQQ(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .questionDetailList(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        default:
            break
        }
        let token = genertateAppToken(param)
        param["app_token"] = token
        return param
    }
    
    var method: Moya.Method {
        switch self {
        case  .feedback:
            return .post
        default:
            break
        }
        return .get
    }
    
    
    var task: Task {
        return .requestParameters(parameters: param, encoding: URLEncoding.default)
    }
}


enum AdvertiseConfigService: AppTargetType {
    case configList
    
    var path: String {
        switch self {
        case .configList:
            return "/app/appadnewconfig/adlistv4"
        }
    }
    
    var param: [String: Any] {
        var param = publicParam
        param["flush_cache"] = "1"
        if !me.isLogin && me.origin != "deeplink" {
            param.removeValue(forKey: "user_id")
        }
        let token = genertateAppToken(param)
        param["app_token"] = token
        return param
    }
    
    var method: Moya.Method {
        return .get
    }
    
    
    var task: Task {
        return .requestParameters(parameters: param, encoding: URLEncoding.default)
    }
    
}

/// 数据统计上报相关
enum StatisticService: AppTargetType {
    /// 用户搜索上报
    case search(String)
    /// 阅读行为统计上报 阅读行为统计上报（用户翻阅到一个章节的最后一页上报）） 默认 from_type 等于 0， 100 好书推荐， 101 启动弹窗
    case userReadAction([String: String])
    /// 广告统计
    case advertise([String: Any])
    /// 看广告免5章
    case reader5ChapterNoAd
    /// 启动次数（用户启动app上报）
    case lanunchTime
    /// 分享书籍
    case shareBook([String: Any])
    /// 购买vip，购买VIP数据
    case buyVip([String: Any])
    /// 充值数据
    case charge
    /// 数据统计上报-好书推荐/弹窗数据
    case goodBookRecommend([String: Any])
    /// 页面曝光
    case pageExposure(String)
    /// 点击事件
    case click(String)
    /// 阅读器上报阅读时长
    case readTime(Int)
    /// 发送消息点击统计
    case messageClick([String: String])

    
    var path: String {
        switch self {
        case .search:
            return "/app/usersearch/add"
        case .userReadAction:
            return "/app/userreadaction/add"
        case .reader5ChapterNoAd:
            return "/app/doudouv4/viewad/add"
        case .lanunchTime:
            return "/app/userstart/add"
        case .advertise:
            return "/yd/pvuv/appad"
        case .shareBook:
            return "/app/statisticssharedetail/add"
        case .buyVip:
            return "/yd/pvuv/apponepagepv"
        case .charge:
            return "/yd/pvuv/apponepagepv"
        case.goodBookRecommend:
            return "/yd/pvuv/appbookchapter"
        case .pageExposure, .click:
            return "/yd/pvuv/apponepagepv"
        case .readTime:
            return "/app/mfxsjtask/readTime"
        case .messageClick:
            return "/yd/jpushmessage/click"
        }
    }
    
    var param: [String: Any] {
        var param = publicParam
        switch self {
        case .search(let keyword):
            param["keyword"] = keyword
        case .userReadAction(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .pageExposure(let pv_uv_page_type):
            param["pv_uv_page_type"] = pv_uv_page_type
        case .click(let pv_uv_page_type):
            param["pv_uv_page_type"] = pv_uv_page_type
        case .advertise(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .shareBook(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .buyVip(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        case .charge:
            param["pv_uv_page_type"] = "pay_apple"
        case .goodBookRecommend(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
                param["pv_uv_page_type"] = "book_chapter"
            }
        case .readTime(let minute):
            param["minute"] = "\(minute)"
            
        case .messageClick(let inputParam):
            for (key, value) in inputParam {
                param[key] = value
            }
        default:
            break
        }
        let token = genertateAppToken(param)
        param["app_token"] = token
        return param
    }
    
    var baseURL: URL {
        switch self {
        case .readTime,
             .shareBook,
             .reader5ChapterNoAd,
             .search,
             .messageClick,
             .userReadAction,
             .lanunchTime:
            return URL(string: "https://open.kxxsc.com")!
        default:
            return URL(string: "https://tj.ayd6.cn")!
        }
    }
    var method: Moya.Method {
        switch self {
        case .userReadAction:
            return .post
        default:
            break
        }
        return .get
    }
    
    
    var task: Task {

        return .requestParameters(parameters: param, encoding: URLEncoding.default)
    }
    
}

enum CommonDataConfigService: AppTargetType {
    /// 开关配置
    case switcherConfigList
    ///  启动弹框
    case lanuchAlert
    
    var path: String {
        switch self {
        case .switcherConfigList:
            return "/app/switchcraft/config"
        case .lanuchAlert:
            return "/app/apppopup/popup"
        }
    }
    
    var param: [String: Any] {
        var param = publicParam
       
        switch self {
        case .switcherConfigList:
            break
        case .lanuchAlert:
            param["type_name"] = "qidong_tanchuang"
        }
        let token = genertateAppToken(param)
        param["app_token"] = token
        return param
    }
    
    var method: Moya.Method {
        return .get
    }
    
    
    var task: Task {
        return .requestParameters(parameters: param, encoding: URLEncoding.default)
    }
    
}
