//
//  ViewController.swift
//  AVPlayer-Swift
//
//  Created by 云族佳 on 16/4/26.
//  Copyright © 2016年 温仲斌. All rights reserved.
//

import UIKit

import AVFoundation

class ViewController: UIViewController, PlayerManagerDelegate {
    
    @IBOutlet weak var haha: UISlider!
    @IBOutlet weak var jindulabel: UILabel!
    @IBOutlet weak var zongchangdu: UILabel!
    @IBOutlet weak var huanchong: UIProgressView!
    override func viewDidLoad() {
        super.viewDidLoad()
        PlayerManager.playerManager.delegate = self
        PlayerManager.playerManager.array = ["http://ac-pnpdahud.clouddn.com/702c914d0c6ae323.mp3", "http://ac-pnpdahud.clouddn.com/edb9467d562d496b.mp3", "http://ac-pnpdahud.clouddn.com/01c2cfec32540933.mp3", "http://ac-pnpdahud.clouddn.com/36ba946bc84a1d18.mp3"]
    }
    
    @IBAction func changeValue(sender: AnyObject) {
        PlayerManager.playerManager.setTime(haha.value)
    }
    @IBAction func change(sender: AnyObject) {
        PlayerManager.playerManager.playerInFrontOf()
        
    }
    @IBAction func bofang(sender: AnyObject) {
        PlayerManager.playerManager.play()
    }
    @IBAction func next(sender: AnyObject) {
        PlayerManager.playerManager.nextPlayer()
    }
    @IBOutlet weak var bofang: UIButton!
    @IBAction func zanting(sender: AnyObject) {
        PlayerManager.playerManager.pause()
    }
    
    @IBAction func chongbo(sender: AnyObject) {
        PlayerManager.playerManager.restart()
    }
    @IBOutlet weak var next: UIButton!
    func PlayerManagerDelegateTotalBuffer(totalBuffer: Float, itemdurationSeconds: String) {
        self.huanchong.setProgress(totalBuffer, animated: true)
        self.zongchangdu.text = itemdurationSeconds
    }
    
    func PlayerManagerDelegateSchedule(schedule: Float, current: String) {
        self.haha.setValue(schedule, animated: true)
        self.jindulabel.text = current
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

