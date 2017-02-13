//
//  ViewController.swift
//  iPhone-controller
//
//  Created by Paul Jones on 02/11/2015.
//  Copyright © 2015 Fluid Pixel Limited. All rights reserved.
//

import UIKit
import CoreMotion
import SceneKit

class ViewController: UIViewController, TVCPhoneSessionDelegate {
    
    var remote = TVCPhoneSession()
    let motion = CMMotionManager()
    
    var buttonEnabled = 0
    var speedSquared : Float = 0.0

    @IBOutlet weak var speed: UILabel!
    @IBOutlet var TouchPad: UIPanGestureRecognizer!
    @IBOutlet var messageArea:UILabel!
    
    @IBOutlet weak var AccelerateButton: UIButton!
    @IBOutlet weak var BreakButton: UIButton!
    
    //for touchpad-to canvas on tv
    var point = CGPoint.zero
    var swiped = false
    
    @IBOutlet weak var textMessage: UITextView!
    
    
    @IBAction func button1Pressed() {
        send("Button", text: 1 as Any)
        buttonEnabled = 1
        
        //set up accelerometer readings
        
        if motion.isDeviceMotionAvailable {
            motion.deviceMotionUpdateInterval = 0.5
            motion.startDeviceMotionUpdates(to: OperationQueue.main, withHandler: { (data: CMDeviceMotion?, error :NSError?) -> Void in
                if error == nil && data != nil {
                    
                    let temp = data!.attitude
                    
                    let accel : [Float] = [Float(temp.pitch), Float(temp.yaw), Float(temp.roll)]
                    self.send("Accelerometer", text: accel as Any)
                }else {
                    self.write((error?.localizedDescription)!)
                }
            } as! CMDeviceMotionHandler)
        }

    }

    @IBAction func button2Pressed() {
        send("Button", text: 2 as Any)
        buttonEnabled = 2
        motion.stopDeviceMotionUpdates()

    }
    @IBAction func button3Pressed() {
        send("Button", text: 3 as Any)
        buttonEnabled = 3
        motion.stopDeviceMotionUpdates()

    }
    //Button tap controls
    @IBAction func OnAccelerateTapped(_ sender: UIButton) {
        //Note: Touch inside disables the time the same way touch outside does,
        //      so the user can hold the button to gain acceleration
        // 1  - accelerate
        // 0  - release
        // -1 - break
        send("Speed", text: 0 as Any)
    }
    
    @IBAction func OnAccelerateReleased(_ sender: UIButton) {
        send("Speed", text: 0 as Any)
        
    }
    
    @IBAction func AcceleratePressed(_ sender: UIButton) {
        send("Speed", text: 1 as Any)
    }
    

    @IBAction func OnBreakTapped(_ sender: UIButton) {
        send("Speed", text: 0 as Any)
    }
    
    @IBAction func BreakPressed(_ sender: UIButton) {
        send("Speed", text: -1 as Any)
    }
    
    @IBAction func OnBreakReleased(_ sender: UIButton) {
        send("Speed", text: 0 as Any)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = false

        if touches.first != nil {
            let touch = touches.first!
            if buttonEnabled == 2 {
            point = touch.location(in: self.view)
            
            send("DrawBegin", text: [point.x, point.y])
            }
        }
        super.touchesBegan(touches, with: event)
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        swiped = true
        
        if touches.first != nil {
            let touch = touches.first!
            if buttonEnabled == 2 {
                let currentPoint : CGPoint = touch.location(in: view)
                send("DrawMove", text: [currentPoint.x, currentPoint.y])
                point = currentPoint
            }
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if !swiped {
            if buttonEnabled == 2 {
                send("DrawEnd", text: [point.x, point.y])
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.remote.delegate = self
        self.view?.isMultipleTouchEnabled = true
        
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        let value = UIInterfaceOrientation.landscapeLeft.rawValue
        UIDevice.current.setValue(value, forKey: "orientation")
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


    fileprivate func send(_ identifier: String, text:Any) {
        self.write("\(text)")
        self.remote.sendMessage([identifier:text], replyHandler: { (reply) -> Void in
            self.write("Reply received: \(reply)")
            
            if var tempSpeed = reply["Reply"] as? Float {
                tempSpeed = sqrt(tempSpeed)
                self.speed.text = "\(tempSpeed)mph"
            }
            
            }) { (error) -> Void in
                 self.write("ERROR : \(error)")
        }
    }
    fileprivate func write(_ text:String) {
        DispatchQueue.main.async {
            let existingText = self.textMessage.text!
            self.textMessage.text = "\(existingText)\n\(text)"
        }
    }
    
    func didConnect() {
        self.write("Connected")
    }
    func didDisconnect() {
        self.write("Disconnected")
    }
    func didReceiveBroadcast(_ message: [String : Any]) {
        self.write("Broadcast received: \(message)")
    }
    func didReceiveBroadcast(_ message: [String : Any], replyHandler: ([String : Any]) -> Void) {
        self.didReceiveBroadcast(message)
        replyHandler(["Reply":0 as Any])
    }
    func didReceiveMessage(_ message: [String : Any]) {
        self.write("Message received: \(message)")
    }
    func didReceiveMessage(_ message: [String : Any], replyHandler: ([String : Any]) -> Void) {
        self.didReceiveMessage(message)
        replyHandler(["Reply":0 as Any])
    }
    
}

