//
//  User.swift
//  PeasNovel
//
//  Created by lieon on 2019/1/23.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import HandyJSON
import Moya
import RxSwift
import RxSwiftExt
import CryptoSwift
import RxDataSources

struct UserPageModel {
    
    var title: String?
    var iconName: String?
    
    init(_ iconName: String?, title: String?) {
        self.iconName = iconName
        self.title = title
    }
}


struct UserPageSection {
    
    var items: [UserPageModel]
    
    init(_ items: [UserPageModel]) {
        self.items = items
    }
}

extension UserPageSection: SectionModelType {
    
    typealias Item = UserPageModel
    
    init(original: UserPageSection, items: [Item]) {
        self = original
        self.items = items
    }
}


var me: User {
    return User.shared
}

class UserResponse: BaseResponse<User> {
    static func commonError(_ error: Error) -> UserResponse {
        let response = UserResponse()
        let status = ReponseResult()
        response.status = status
        status.code = -1
        status.msg = "遇到问题了哦"
        if let error = error as? AppError {
            status.msg = error.message
        }
        return response
    }
}

enum Gender: String, HandyJSONEnum {
    case male = "1"
    case female = "2"
    case secret = "0"
    
    var desc: String {
        switch self {
        case .male:
            return "男"
        case .female:
            return "女"
        case .secret:
            return "保密"
        }
    }
    
    var iconName: String {
        switch self {
        case .male:
            return "male"
        case .female:
            return "female"
        case .secret:
            return "secret"
        }
    }
    
}

class MasterInfo: User {}

class AccountInfo: Model {
    var account_balance: Int?
    var beans_balance: Int?
    var rmb_balance: Int?
    
}

class UserAdvertiseInfo: Model {
    var ad_status: Int? = 1
    var ad_start_time: Int?
    var ad_end_time: Int?
    var vip: VIPType = .year
    
    func mapping(mapper: HelpingMapper) {
        mapper >>> self.ad_status
        mapper >>> self.vip
    }
}

enum VIPType: Int, HandyJSONEnum {
    case none = 0
    case month = 1
    case season = 2
    case year = 3
}

class User: HandyJSON {

    static var shared = User()
    var user_id: String?
    var user_name: String?
    var phone: String?
    var reg_time: Int?
    var token: String?
    var is_new_user: Bool?
    var headimgurl: String?
    var master_info: MasterInfo?
    var account_info: AccountInfo?
    var bind_phone_rmb: String?
    var weixin_extract_bind: Int?
    var alipay_extract_bind: Int?
    var ad: UserAdvertiseInfo?
    var device_id: String?
    var registration_id: String = "" //
    var push_giuid: String = "" ///
    var getui_giuid: String = ""
    var isLogin: Bool {
        get {
            if let token = self.token, !token.isEmpty {
                return true
            }
            return false
        }
        set {
            
        } 
    }
    var sex: Gender = .male
    var account_balance: Int?
    var beans_balance: Int?
    var rmb_balance: Int?
    var nickname: String?
    var total_minute: Int?
    var day_minute: Int?
    var origin: String?
    
    var isVipValid: Bool {
        if !self.isLogin {
            return false
        }
        if let vipType = self.ad?.vip, vipType.rawValue == VIPType.none.rawValue {
            return false
        }
        if let adEndtime = self.ad?.ad_end_time, adEndtime > Int(Date().timeIntervalSince1970) {
            return true
        }
        return false
    }
    
    required init() {
        NotificationCenter.default.addObserver(self, selector: #selector(clear), name: Notification.Name.Account.signOut, object: nil)
         fetchIdentifierFromKeychain()
    }
    
    /// 获取设备标识
    private func fetchIdentifierFromKeychain() {
        do {
            let items = Keychain(service: Keychain.Configuration.serviceName, accessGroup: Keychain.Configuration.accessGroup)
            let ide = try items.read()
            self.device_id = ide
            
        } catch {
            debugPrint("Error fetching keychain items - \(error)")
        }
        if self.device_id == nil {
            do {
                let items = Keychain(service: Keychain.Configuration.serviceName, accessGroup: Keychain.Configuration.accessGroup)
                
                self.device_id = UIDevice.current.identifierForVendor?.uuidString
                try? items.save(self.device_id)
             }
        }
    }
    
    /// 归档路径
    private var localDir: String? {
        if let userDir = NSSearchPathForDirectoriesInDomains(FileManager.SearchPathDirectory.libraryDirectory, FileManager.SearchPathDomainMask.userDomainMask, true).first {
            return userDir + "/user.data"
        }
        return nil
    }
    
    @objc func clear() {
        if let localDir = localDir {
            do {
                try FileManager.default.removeItem(atPath: localDir)
                if  var currentUserJson = User.shared.toJSON() {
                    for key in currentUserJson.keys {
                        if key != "user_id", key != "device_id" {
                            currentUserJson[key] = ""
                            print("CLEAR:",currentUserJson)
                        }
                        JSONDeserializer.update(object: &User.shared, from: currentUserJson)
                    }
                }
                NotificationCenter.default.post(name: Notification.Name.Account.clear, object: nil)
            }catch {
            }
        }
    }
    
    /// 读取磁盘信息
    func readFromDisk() {
        // 从磁盘取出数据
        if let localDir = localDir {
            if let json = NSKeyedUnarchiver.unarchiveObject(withFile: localDir) as? [String: Any] {
                print("[USER] 从磁盘取出用户数据:\n", json)
                JSONDeserializer.update(object: &User.shared, from: json)
                me.fetchIdentifierFromKeychain()
            }
        }
    }
    
    /// 写入用户信息
    func writeIntoDisk() {
        if let localDir = localDir {
            guard let json = self.toJSON() else {  return  }
            if NSKeyedArchiver.archiveRootObject(json, toFile: localDir) {
                print("[USER]更新用户信息完成:", self.toJSON() ?? [:])
                NotificationCenter.default.post(name: Notification.Name.Account.update, object: nil)
            }
        }
    }
    
    func update() {
        me.writeIntoDisk()
    }
    
}

extension ObservableType where Element == Response {
    
    func userUpdate() -> Disposable {
        return flatMap {
            Observable.just(try $0.user(UserResponse.self))
            }.map {$0.data }
            .debug()
            .subscribe(onNext: { user in
                User.shared.writeIntoDisk()
            }, onError: {
                print("[USER-ObservableType]用户信息更新失败:", $0.localizedDescription)
            }, onCompleted: {
                
            }, onDisposed: {
                
            })
    }
    
    
}


extension ObservableType where Element == Response {
    
    func userResponse() -> Observable<UserResponse> {
        return flatMap{
             Observable.just(try $0.user(UserResponse.self))
        }
    }
    
}

extension PrimitiveSequence where Trait == SingleTrait, Element == Moya.Response {
    
    func userUpdate() -> Disposable {
        return flatMap {
            Single.just(try $0.user(UserResponse.self))
            }.map {$0.data }
            .subscribe(onSuccess: { (user) in
                User.shared.writeIntoDisk()
            }, onError: {
                 print("[USER]用户信息更新失败-PrimitiveSequence:", $0.localizedDescription)
            })
    }
    
    func userUpdate() -> Single<UserResponse> {
        return flatMap {
            let userResponse = try $0.user(UserResponse.self)
            User.shared.writeIntoDisk()
            return Single.just(userResponse)
        }
    }
}

extension Response {
    func user(_ type: UserResponse.Type) throws -> UserResponse {
        let jsonString = String(data: data, encoding: .utf8)
        
        print("✈ -------------------------------------------- ✈")
        print("[URL]\t:", self.request?.urlRequest?.url ?? "")
        if let paramData = request?.urlRequest?.httpBody {
            do{
                let param = try JSONSerialization.jsonObject(with: paramData, options: JSONSerialization.ReadingOptions.allowFragments)// as? [String: Any]
                print("[PARAM]\t:",param)
            }catch let e {
                print("[PARAM]\t:", String(data: paramData, encoding: String.Encoding.utf8) ?? "[ERROR]\t:\(e.localizedDescription)")
            }
        }
        
        if let header = request?.allHTTPHeaderFields {
            print("[HEADER]\t:",header)
        }
        
        print("[RES]\t\t:",jsonString ?? "", "\n")
        guard let rawJson = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any],
            let result = rawJson?["result"] as? [String: Any],
            let status = result["status"] as? [String: Any],
            let code = status["code"] as? Int  else  {
                throw MoyaError.jsonMapping(self)
        }
        if code == 0  {
            guard let ret = JSONDeserializer<UserResponse>.deserializeFrom(dict: result) else {
                throw NetError.info("加载失败，请检查网络链接")
            }
            guard let dataJson = result["data"] as? [String: Any] else {
                throw MoyaError.jsonMapping(self)
            }
           let preUserId = me.user_id
            print("[USER]更新用户信息的数据:", dataJson)
            JSONDeserializer.update(object: &User.shared, from: dataJson)
            if preUserId != me.user_id {
                NotificationCenter.default.post(name: Notification.Name.Advertise.configNeedUpdate, object: nil)
            }
            return ret
        } else {
            let message = status["msg"] as? String  ?? ""
            throw AppError(message: message, code: ErrorCode(rawValue: code) ?? .none)
        }
    
    }
}


