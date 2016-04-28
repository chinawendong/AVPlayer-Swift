//
//  PlayerManager.swift
//  AVPlayer-Swift
//
//  Created by 云族佳 on 16/4/26.
//  Copyright © 2016年 温仲斌. All rights reserved.
//

import UIKit

import AVFoundation

import MediaPlayer

@objc protocol PlayerManagerDelegate  {
    /**
     获取缓冲
     
     - parameter totalBuffer:         缓冲进度
     - parameter itemdurationSeconds: 总时长
     */
    optional func PlayerManagerDelegateTotalBuffer(Progress : Float, itemdurationSeconds : String)
    /**
     获取歌曲进度
     
     - parameter schedule: 进度百分比
     - parameter current:  当前时间
     */
    optional func PlayerManagerDelegateSchedule(value : Float, current : String)
    
}

enum PlayerModel {
    case None//顺序播放
    case Single//单曲循环
    case Random//随机
    case Cycle//循环播放
}

class PlayerManager : NSObject {
    
    static let playerManager = PlayerManager.init()
    //代理
    weak var delegate : PlayerManagerDelegate?
    //总时长
    var totalDuration : NSTimeInterval?
    //播放模式
    var playerModel : PlayerModel = .Cycle
    //当前播放的Item
    var playerItem : AVPlayerItem? {
        willSet {
            playerItem?.removeObserver(self, forKeyPath: "status")
            playerItem?.removeObserver(self, forKeyPath: "loadedTimeRanges")
        }
        
        didSet {
            playerItem?.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.New, context: nil)
            playerItem?.addObserver(self, forKeyPath: "loadedTimeRanges", options: NSKeyValueObservingOptions.New, context: nil)
        }
    }
    //播放器
    let player : AVPlayer = AVPlayer()
    //记录播放位置
    var playbackPosition = 0
    //播放数组
    var array : [String]?
    
    struct Static {
        static var onceToken : dispatch_once_t = 0
    }
    
    override init() {
        super.init()
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.player.addPeriodicTimeObserverForInterval(CMTimeMake(Int64(1.0), Int32(1.0)), queue: dispatch_get_main_queue()) { (time) in
                self.delegate?.PlayerManagerDelegateSchedule?(Float(CMTimeGetSeconds(time)/CMTimeGetSeconds((self.playerItem?.duration)!)), current : self.getTimeString(CMTimeGetSeconds(time)))
            }
        }
    }
    
    //MARK:缓冲中~
    func loging(notification : NSNotification) {
        print(notification)
    }
    
    //MARK:意外中断处理
    func treatmentAccident(notification : NSNotification) {
        print(notification)
    }
    
    func getTimeString(timeInterval : NSTimeInterval) -> String {
        let hours = Int(timeInterval / 3600)
        let minutes = Int(timeInterval / 60) - hours * 60
        let seconds = Int(timeInterval) - hours * 60 - minutes * 60
        if hours > 0 {
            return PlayerManager.generateTimeFormat(hours) + ":" + PlayerManager.generateTimeFormat(minutes) + ":" + PlayerManager.generateTimeFormat(seconds)
        }else {
            return PlayerManager.generateTimeFormat(minutes) + ":" + PlayerManager.generateTimeFormat(seconds)
        }
    }
    
    class func generateTimeFormat(time : Int) -> String {
        if time < 10 {
            return "0" + "\(time)"
        }else {
            return "\(time)"
        }
    }
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        //MARK:当前是否可播放
        if keyPath == "status" {
            switch (change!["new"] as! Int) {
            case 0:
                print("未知错误")
            case 1:
                print("可以播放")
            case 2:
                print("播放失败")
            default:
                break
            }
        }
        //MARK:获取缓冲
        if keyPath == "loadedTimeRanges" {
            
            let loadArray = self.playerItem?.loadedTimeRanges
            let timeRanges = loadArray?.first?.CMTimeRangeValue
            let starTime = CMTimeGetSeconds((timeRanges?.start)!)
            let durationSeconds = CMTimeGetSeconds((timeRanges?.duration)!)
            let totalBuffer = ceil(NSTimeInterval(starTime + durationSeconds))
            totalDuration = CMTimeGetSeconds(playerItem!.duration)
            self.delegate?.PlayerManagerDelegateTotalBuffer?(Float(totalBuffer / totalDuration!),itemdurationSeconds: self.getTimeString(totalDuration!))
        }
    }
    
    //MARK:播放结束
    func avplayerItemDidPlayToEndTimeNotification(aa:NSNotification?){
        self.nextPlayer()
    }
    
    //MARK:指定播放时间
    func setTime(value : Float) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.player.pause()
            self.playerItem?.seekToTime(CMTimeMake(Int64(value * Float(self.totalDuration!)), Int32(1.0)), completionHandler: { (bool) in
                if bool {
                    self.player.play()
                }
            })
        }
    }
    
    //MARK:下一首
    func nextPlayer() {
        self.replacem()

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            switch self.playerModel {
            case .None:
                if self.playbackPosition + 1 >= (self.array?.count)! {
                    print("全部播放完毕")
                    return
                }
                self.playbackPosition += 1
            case .Cycle :
                self.playbackPosition = (self.playbackPosition + 1) % (self.array?.count)!
            case .Random :
                var index = 0
                repeat {
                    index = Int(arc4random() % UInt32((self.array?.count)!))
                } while index == self.playbackPosition
                self.playbackPosition = index
            default:
                break
            }

            self.playerItem((self.array?[self.playbackPosition])!)
        }
    }
    
    //MARK:前一首
    func playerInFrontOf() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            self.replacem()

            switch self.playerModel {
            case .None:
                if self.playbackPosition - 1 < 0{
                    print("已经是第一首了")
                    return
                }
                self.playbackPosition -= 1
            case .Cycle :
                self.playbackPosition = ((self.playbackPosition - 1) + (self.array?.count)!) % (self.array?.count)!
            case .Random :
                var index = 0
                repeat {
                    index = Int(arc4random() % UInt32((self.array?.count)!))
                } while index == self.playbackPosition
                self.playbackPosition = index
            default:
                break
            }

            self.playerItem((self.array?[self.playbackPosition])!)
        }
    }
    
    //MARK:跳到指定item
    func playerSpecified(index : Int) {
        self.playbackPosition = index
        self.playerItem((array?[playbackPosition])!)
    }
    
    //MARK:播放
    func play() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            dispatch_once(&Static.onceToken) {
                self.loadNotificationAndAudioSession()
            }
            self.replacem()
            self.playerItem((self.array?[self.playbackPosition])!)
        }
    }
    
    
    //MARK: 通知 设置后台播放
    func loadNotificationAndAudioSession() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(avplayerItemDidPlayToEndTimeNotification), name: AVPlayerItemDidPlayToEndTimeNotification, object: nil )
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(loging), name: AVPlayerItemPlaybackStalledNotification, object: nil )
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(treatmentAccident), name: AVAudioSessionInterruptionNotification, object: nil )
        
        try! AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
        try! AVAudioSession.sharedInstance().setActive(true)
        UIApplication.sharedApplication().beginReceivingRemoteControlEvents()
        UIApplication.sharedApplication().canBecomeFirstResponder()
    }
    
    //MARK:暂停
    func pause() {
        self.player.pause()
    }
    
    //MARK: 重新开始
    func restart() {
        self.player.seekToTime(CMTimeMake(0, 1))
        self.player.play()
    }
    
    //MARK: 更换item
    func playerItem(string : String) {
        
        let asset = AVURLAsset.init(URL: NSURL.init(string: string)!)
        
        var currURL = NSURL.init()
        
        if ((playerItem) != nil) {
            currURL = (playerItem?.asset as! AVURLAsset).URL
        }
        
        if currURL == asset.URL {
            return
        }
        
        self.playerItem = AVPlayerItem.init(asset: asset)
        self.player.replaceCurrentItemWithPlayerItem( self.playerItem!)
        self.player.play()
        
        self.setnowPlayingInfo(asset)
    }
    
    //MARK: 设置锁屏信息
    func setnowPlayingInfo(asset : AVURLAsset) {
        var dict = [String : AnyObject]()
        for string in asset.availableMetadataFormats {
            for metadataItem in asset.metadataForFormat(string) {
                if (metadataItem.commonKey != nil) {
                    switch metadataItem.commonKey! {
                    case "albumName":
                        dict[MPMediaItemPropertyAlbumTitle] = metadataItem.value
                    case "title":
                        dict[MPMediaItemPropertyTitle] = metadataItem.value
                    case "artwork":
                        dict[MPMediaItemPropertyArtwork] = MPMediaItemArtwork.init(image: UIImage.init(data: metadataItem.dataValue!)!)
                    case "artist":
                        dict[MPMediaItemPropertyAlbumArtist] = metadataItem.value
                    default:
                        break
                    }
                }
            }
        }
        dict[MPMediaItemPropertyPlaybackDuration] = CMTimeGetSeconds(asset.duration)
        MPNowPlayingInfoCenter.defaultCenter().nowPlayingInfo = dict
    }
    
    //MARK:远程控制
    class func remoteControlReceivedWithEvent(receivedEvent : UIEvent) {
        if (receivedEvent.type == UIEventType.RemoteControl) {
            switch (receivedEvent.subtype) {
            case UIEventSubtype.RemoteControlPreviousTrack:
                self.playerManager.playerInFrontOf()
            case UIEventSubtype.RemoteControlNextTrack:
                self.playerManager.nextPlayer()
            case UIEventSubtype.RemoteControlStop:
                self.playerManager.pause()
            case UIEventSubtype.RemoteControlPause:
                self.playerManager.pause()
            case UIEventSubtype.RemoteControlPlay:
                self.playerManager.play()
            default:
                break;
            }
        }
    }
    
    func replacem() {
        guard ((self.array?[playbackPosition]) != nil) else {
            print("播放数组为nil")
            return
        }
    }
}
