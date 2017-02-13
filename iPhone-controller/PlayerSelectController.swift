//
//  PlayerSelectController.swift
//  tvOS-controller
//
//  Created by Lauren Brown on 17/11/2015.
//  Copyright © 2015 Fluid Pixel Limited. All rights reserved.
//

import UIKit

class PlayerSelectController: UIViewController, TVCPhoneSessionDelegate {

    let remote = TVCPhoneSession()
    
    @IBOutlet weak var playerslabel: UILabel!
    @IBOutlet weak var activityView: UIActivityIndicatorView!
    @IBOutlet weak var ConnectionStateLabel: UILabel!
    
    @IBOutlet weak var numberOfPlayersLabel: UILabel!
    
    @IBOutlet weak var ColourLabel: UILabel!
    @IBOutlet weak var ButtonRight: UIButton!
    @IBOutlet weak var ButtonLeft: UIButton!
    
    var readyToRace : Bool = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.remote.delegate = self
        activityView.startAnimating()
        activityView.hidesWhenStopped = true
        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "Start" {
            if let vc = segue.destination as? ViewController {
                vc.remote = remote
            }
        }
    }
    
    @IBAction func ChangeColourRight(_ sender: UIButton) {
        send("Colour", text: 1 as AnyObject)
    }
    
    
    @IBAction func ChangeColourLeft(_ sender: UIButton) {
        send("Colour", text: -1 as AnyObject)
    }

    @IBAction func Ready(_ sender: UIButton) {
        readyToRace = !readyToRace
        send("Ready", text: readyToRace as AnyObject)
    }
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    fileprivate func send(_ identifier: String, text:AnyObject) {
        print("\(text)")
        self.remote.sendMessage([identifier:text], replyHandler: { (reply) -> Void in
            print("Reply received: \(reply)")

            
            }) { (error) -> Void in
                print("ERROR : \(error)")
        }
    }
    
    func didConnect() {
        ConnectionStateLabel.text = "Connected To TV!"
        activityView.stopAnimating()
        
        print("Connected")
    }
    func didDisconnect() {
        ConnectionStateLabel.text = "Disconnected, reconnecting To TV..."
        activityView.startAnimating()
        print("Disconnected")
    }
//    func didReceiveBroadcast(_ message: [String : AnyObject]) {
//        print("Broadcast received: \(message)")
//    }
//    func didReceiveBroadcast(_ message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
//        self.didReceiveBroadcast(message)
//        replyHandler(["Reply":0 as AnyObject])
//    }
//    func didReceiveMessage(_ message: [String : AnyObject]) {
//        print("Message received: \(message)")
//    }
//    func didReceiveMessage(_ message: [String : AnyObject], replyHandler: ([String : AnyObject]) -> Void) {
//        self.didReceiveMessage(message)
//        replyHandler(["Reply":0 as AnyObject])
//    }
    
    internal func didReceiveBroadcast(_ message: [String : Any]) {
        print("Broadcast received: \(message)")
    }
    
    internal func didReceiveBroadcast(_ message: [String : Any], replyHandler: ([String : Any]) -> Void) {
        self.didReceiveBroadcast(message)
        replyHandler(["Reply":0 as Any])
    }
    internal func didReceiveMessage(_ message: [String : Any]) {
         print("Message received: \(message)")
    }
    internal func didReceiveMessage(_ message: [String : Any], replyHandler: ([String : Any]) -> Void) {
        self.didReceiveMessage(message)
        replyHandler(["Reply":0 as Any])
    }

}
