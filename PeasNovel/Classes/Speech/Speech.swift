//
//  Speech.swift
//  PeasNovel
//
//  Created by lieon on 2019/8/13.
//  Copyright © 2019 NotBroken. All rights reserved.
//

import Foundation
import RealmSwift
import HandyJSON
import Alamofire
import PKHUD

class SpeechManager: NSObject {
    static let share = SpeechManager()
    private var jdSpeechManager: JDAISSpeechManager!
    fileprivate lazy var speechManagerConfig: [String: Any] = [:]
    fileprivate var statusCallback: ((Stattus) -> Void)?
    fileprivate var currentPageModel: ChapterPageModel?
    fileprivate var allTask: [ChapterPageModel] = []
    fileprivate var currentText: String?
    fileprivate var currentTime: Double = 0
    var currentStatus: Stattus = .idle
    struct SpeechResult: HandyJSON {
        var err_code: String?
        var err_msg: String?
        var progress: Float?
    }
    var timer: DispatchSourceTimer?
    enum Stattus {
        case playBegin(result: String?, currentPageModel: ChapterPageModel?, currentText: String?)
        case playEnd(result: String?, data: Data?)
        case synthesizeData(result: String?, data: Data?)
        case systhesizeFinish(result: SpeechResult?, data: Data?)
        case playbackProgress(result: SpeechResult?, currentPageModel: ChapterPageModel?, currentText: String?)
        case idle
        case pause
        case stop
        case start
        
        var value: String {
           return Stattus.getValue(self)
        }
        
       static func getValue(_ status: Stattus) -> String {
            switch status {
            case .playBegin:
                return "playBegin"
            case .playEnd:
                return "playEnd"
            case .synthesizeData:
                return "synthesizeData"
            case .systhesizeFinish:
                return "systhesizeFinish"
            case .playbackProgress:
                return "playbackProgress"
            case .idle:
                return "idle"
            case .pause:
                return "pause"
            case .stop:
                return "stop"
            case .start:
                return "start"
            }
        }
    }
    
    var isRunning: Bool {
        return !(currentStatus.value == Stattus.getValue(SpeechManager.Stattus.stop) ||
            currentStatus.value == Stattus.getValue(SpeechManager.Stattus.idle) ||
           currentStatus.value == Stattus.getValue(SpeechManager.Stattus.pause)) ||
        currentStatus.value == Stattus.getValue(SpeechManager.Stattus.start)
    }
 
    override  init() {
        super.init()
        loadConfig()
    }
    
    func startText(_ inputText: String) {
        if jdSpeechManager == nil {
            jdSpeechManager = JDAISSpeechManager.create(JDAIS_ENGINETYPE_TTS)
            jdSpeechManager!.setListener(self)
        }
        self.currentText = inputText
        speechManagerConfig[JDAIS_TTS_TEXT] = inputText
        if let paramStr = self.speechManagerConfig.toJSONString() {
            jdSpeechManager.send(JDAIS_TTS_CMD_START, withParams: paramStr)
        }
    }
    
    

    func startTasks(_ texts: [ChapterPageModel]) {
        allTask.removeAll()
        currentText = nil
        currentPageModel = nil
        if isRunning, let paramStr = speechManagerConfig.toJSONString(), jdSpeechManager != nil {
            jdSpeechManager.send(JDAIS_TTS_CMD_STOP, withParams: paramStr)
        }
         changeStauts(.start)
        allTask = texts
        allTask.forEach { $0.seperate() }
        if let pageModel = texts.first, let text = pageModel.textArray.first {
            currentPageModel = pageModel
            startText(text)
        }
        NotificationCenter.default.post(name: NSNotification.Name.Book.ListenBook.didStartAllTask, object: nil)
        if currentTime == 0 {
            addTimer()
        }
    }
    
    func stopAllTask() {
        allTask.removeAll()
        currentText = nil
        currentPageModel = nil
        changeStauts(.stop)
        if let paramStr = speechManagerConfig.toJSONString(), jdSpeechManager != nil {
             NotificationCenter.default.post(name: NSNotification.Name.Book.ListenBook.didStopAllTask, object: nil)
            jdSpeechManager.send(JDAIS_TTS_CMD_STOP, withParams: paramStr)
        }
        cancleTimer()
    }
    
    func retry() {
        let allTask = self.allTask
        startTasks(allTask)
    }
 
    func stop() {
        if let paramStr = speechManagerConfig.toJSONString() {
            jdSpeechManager.send(JDAIS_TTS_CMD_STOP, withParams: paramStr)
        }
        changeStauts(.stop)
    }
    
    func pause() {
        if let paramStr = speechManagerConfig.toJSONString() {
            jdSpeechManager.send(JDAIS_TTS_CMD_PAUSE, withParams: paramStr)
        }
        changeStauts(.pause)
    }
    
    func resume() {
        if let paramStr = speechManagerConfig.toJSONString() {
            jdSpeechManager.send(JDAIS_TTS_CMD_RESUME, withParams: paramStr)
        }
    }

    func reload() {
        loadConfig()
        if isRunning, let paramStr = speechManagerConfig.toJSONString(), jdSpeechManager != nil {
             currentStatus = .stop
            jdSpeechManager.send(JDAIS_TTS_CMD_STOP, withParams: paramStr)
        }
      
        if let pageModel = allTask.first, let text = pageModel.textArray.first {
            currentPageModel = pageModel
            currentStatus = .start
            startText(text)
        }
    }
}

extension SpeechManager {
    fileprivate func loadConfig() {
        let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
        var config: ListenBookMenuConfig!
        if let existConfig = realm.objects(ListenBookMenuConfig.self).first {
            config = existConfig
        } else {
            let newConfig = ListenBookMenuConfig()
            try? realm.write {
                realm.add(newConfig, update: .all)
            }
            config = newConfig
        }
        speechManagerConfig[JDAIS_TTS_TTS_SAMPLE_RATE] = TJDAISTextToSpeechSampleRateFlags.init(rawValue: 24000).rawValue
        speechManagerConfig[JDAIS_TTS_APP_KEY] = Constant.JDAI.appKey
        speechManagerConfig[JDAIS_TTS_SECRET_KEY] = Constant.JDAI.secretKey
        speechManagerConfig[JDAIS_TTS_SERVER_URL] = "https://aiapi.jd.com/jdai/tts"
        speechManagerConfig[JDAIS_TTS_LANGUAGE] = 0
        speechManagerConfig[JDAIS_TTS_TIM_TYPE] = config.tone
        speechManagerConfig[JDAIS_TTS_AUE_TYPE] = 0 // 0：wav 1：pcm 2：opus
        speechManagerConfig[JDAIS_TTS_VOLUME_LEVEL] = 5 // [0.1, 10.0]
        speechManagerConfig[JDAIS_TTS_SPEED_LEVEL] = (SpeechType(rawValue: config.speech_rate) ?? SpeechType.quick).rate
    }
    
    func addTimer() {
        let realm = try! Realm(configuration: Realm.Configuration.defaultConfiguration)
        if let existConfig = realm.objects(ListenBookMenuConfig.self).first,
            existConfig.timing != 0,
            currentStatus.value != Stattus.getValue(.idle) {
            currentTime = 0
            if let timer = self.timer {
                timer.cancel()
            }
            let timer = DispatchSource.makeTimerSource(flags: DispatchSource.TimerFlags.init(rawValue: 0), queue: DispatchQueue.main)
            timer.schedule(deadline: DispatchTime.now(), repeating: 1)
            timer.setEventHandler { [weak self] in
                guard let weakSelf = self else {
                    return
                }
                weakSelf.currentTime += 1
                print("SpeechManager - addTimer - currentTime:\( weakSelf.currentTime) - existConfig.timing:\(existConfig.timing * 60)")
                if Int(weakSelf.currentTime) == existConfig.timing * 60 {
                    weakSelf.stopAllTask()
                }
            }
            timer.resume()
            self.timer = timer
        } else {
            cancleTimer()
        }
    }
    
    func cancleTimer() {
        currentTime = 0
        if let timer = self.timer, !timer.isCancelled {
            timer.cancel()
        }
    }
}


extension SpeechManager: JDAISClientTTSDelegate {
    
  func onEventText(toSpeech event: String!, withResult result: String!, with data: Data!) {
        debugPrint("SpeechManager:\(event) - result:\(result) - currentStatus :\(currentStatus)")
        if currentStatus.value == Stattus.getValue(.stop) {
            return
        }
        if !SpeechManager.netIsReachable() {
            var result = SpeechResult()
            result.err_code = "-2011"
            result.err_msg = "网络断开"
            changeStauts(.systhesizeFinish(result: result, data: data))
//            changeStauts(.stop)
            return
        }
        switch event {
        case EV_SJDAIS_TTS_PlayBegin:
            changeStauts(.playBegin(result: result, currentPageModel: currentPageModel, currentText: currentText))
        case EV_SJDAIS_TTS_PlayEnd:
             changeStauts(.playEnd(result: result, data: data))
             playNext()
        case EV_SJDAIS_TTS_SynthesizeData:
             changeStauts(.synthesizeData(result: result, data: data))
        case EV_SJDAIS_TTS_SynthesizeFinish:
            if currentStatus.value == Stattus.getValue(.stop) {
                return
            }
            guard let result = JSONDeserializer<SpeechResult>.deserializeFrom(json: result) else {
                return
            }
            changeStauts(.systhesizeFinish(result: result, data: data))
            guard let err_code = result.err_code, let errMsg = result.err_msg, !errMsg.isEmpty else {
                return
            }
           if err_code == "-2011" && SpeechManager.netIsReachable() { // 网络连接失败
                DispatchQueue.main.async {
                    HUD.flash(.label(errMsg), delay: 2)
                    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + 3, execute: {
                        self.changeStauts(.stop)
                    })
                }
            }
        case EV_SJDAIS_TTS_PlaybackProgress:
            guard let result = JSONDeserializer<SpeechResult>.deserializeFrom(json: result) else {
                return
            }
            changeStauts(.playbackProgress(result: result, currentPageModel: currentPageModel, currentText: currentText))
        default:
             changeStauts(.idle)
        }
    }
    
    fileprivate func changeStauts(_ status: Stattus) {
        statusCallback?(status)
        currentStatus = status
        NotificationCenter.default.post(name: NSNotification.Name.Book.ListenBook.statusCallback, object: status)
    }
    
    fileprivate static func netIsReachable() -> Bool {
        let manager = NetworkReachabilityManager()
        if let isReachable = manager?.isReachable, !isReachable {
            return false
        }
        return true
    }
    
    fileprivate func playNext() {
        if currentStatus.value == Stattus.getValue(.stop) {
            return
        }
        guard let currentPageModel = currentPageModel  else {
            changeStauts(.stop)
            return
        }

        guard var currenttextArray = self.currentPageModel?.textArray, !allTask.isEmpty else {
            changeStauts(.stop)
            return
        }
        currenttextArray.removeFirst()
        if let text = currenttextArray.first {
            self.currentPageModel?.textArray = currenttextArray
            startText(text)
            return
        }
        allTask.removeFirst()
        if !allTask.isEmpty {
            guard let task = allTask.first else {
                return
            }
            self.currentPageModel = task
            NotificationCenter.default.post(name: NSNotification.Name.Book.ListenBook.onePageListenEnd, object: currentPageModel)
            if let text = task.textArray.first {
                startText(text)
            }
            debugPrint("SpeechManager:一页播放完毕 - currentPageModel:\(self.currentPageModel?.type)")
            return
        }
        NotificationCenter.default.post(name: NSNotification.Name.Book.ListenBook.oneChapterListenEnd, object: currentPageModel)
    }
}


extension Dictionary {
    func toJSONString() -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: self, options: .init(rawValue: 0)),
            let paramStr = String(data: data, encoding: .utf8) else {
                return nil
        }
        return paramStr
    }
}
