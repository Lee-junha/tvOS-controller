//
//  RemoteSender.swift
//  tvOSController
//
//  Created by Paul Jones on 26/10/2015.
//  Copyright © 2015 Fluid Pixel. All rights reserved.
//

import Foundation
import UIKit


let ERROR_SEND_FAILED = NSError(domain: "com.fpstudios.tvOSController", code: -100, userInfo: [NSLocalizedDescriptionKey:"Failed To Send Message"])

let ERROR_REPLY_FAILED = NSError(domain: "com.fpstudios.tvOSController", code: -200, userInfo: [NSLocalizedDescriptionKey:"No Message In Reply"])

@available(iOS 9.0, *)
protocol TVCPhoneSessionDelegate : class {

    func didConnect()
    func didDisconnect()
    
    func didReceiveBroadcast(_ message: [String : Any], replyHandler: ([String : Any]) -> Void)
    func didReceiveBroadcast(_ message: [String : Any])
    
    func didReceiveMessage(_ message: [String : Any])
    func didReceiveMessage(_ message: [String : Any], replyHandler: ([String : Any]) -> Void)
    
}



@available(iOS 9.0, *)
@objc
open class TVCPhoneSession : NSObject, NetServiceBrowserDelegate, NetServiceDelegate, GCDAsyncSocketDelegate {
    
    weak var delegate:TVCPhoneSessionDelegate?

    internal let coServiceBrowser = NetServiceBrowser()
    internal var dictSockets:[String:GCDAsyncSocket] =  [:]
    internal var arrDevices:Set<NetService> = []

    internal var replyGroups:[Int:DispatchGroup] = [:]
    internal var replyMessages:[Int:[String:Any]] = [:]
    internal var replyIdentifierCounter:Int = 0

    open var connected:Bool {
        return self.selectedSocket != nil
    }
    
    open func sendMessage(_ message: [String : Any], replyHandler: (([String : Any]) -> Void)?, errorHandler: ((NSError) -> Void)?) {
        
        if let selSock = self.selectedSocket {
            if let rh = replyHandler {
                replyIdentifierCounter = replyIdentifierCounter + 1
                let replyKey = replyIdentifierCounter
                let group = DispatchGroup()
                replyGroups[replyKey] = group
                
                group.enter()
                group.notify(queue: DispatchQueue.main) {
                    if let reply = self.replyMessages.removeValue(forKey: replyKey) {
                        rh(reply)
                    }
                    else {
                        errorHandler?(ERROR_REPLY_FAILED)
                    }
                }
                
                selSock.sendMessageObject(Message(type: .Message, replyID: replyKey, contents: message))
                
            }
            else {
                selSock.sendMessageObject(Message(type: .Message, contents: message))
            }
        }
        else {
            errorHandler?(ERROR_SEND_FAILED)
        }
        
    }
    
    var selectedSocket:GCDAsyncSocket? {
        if let coService = self.arrDevices.first?.name {
            return self.dictSockets[coService]
        }
        return nil
    }


    override init() {
        super.init()
        self.coServiceBrowser.delegate = self
        self.coServiceBrowser.searchForServices(ofType: SERVICE_NAME, inDomain: "local.")
    }
    
    func connectWithServer(_ service:NetService) -> Bool {
        if let coSocket = self.dictSockets[service.name], coSocket.isConnected() {
            return true
        }
        let coSocket = GCDAsyncSocket(delegate: self, delegateQueue: DispatchQueue.main)
        
        if let addrs = service.addresses {
            for address in addrs {
                do {
                    try coSocket?.connect(toAddress: address)
                    self.dictSockets[service.name] = coSocket
                    return true
                }
                catch let error as NSError {
                    print ("Can't connect to \(address)\n\(error)")
                }
            }
        }
        return false

    }
    
    // MARK: NSNetServiceBrowserDelegate
    open func netServiceBrowserDidStopSearch(_ browser: NetServiceBrowser) {
        self.coServiceBrowser.stop()
        self.coServiceBrowser.searchForServices(ofType: SERVICE_NAME, inDomain: "local.")
        print("Browsing Stopped")
    }
    open func netServiceBrowser(_ browser: NetServiceBrowser, didNotSearch errorDict: [String : NSNumber]) {
        self.coServiceBrowser.stop()
        self.coServiceBrowser.searchForServices(ofType: SERVICE_NAME, inDomain: "local.")
        print("Browsing Stopped")
    }
    open func netServiceBrowser(_ browser: NetServiceBrowser, didRemove service: NetService, moreComing: Bool) {
        self.arrDevices.remove(service)
    }
    open func netServiceBrowser(_ browser: NetServiceBrowser, didFind service: NetService, moreComing: Bool) {
        if service.name == NET_SERVICE_NAME {
            self.arrDevices.insert(service)
            service.delegate = self
            service.resolve(withTimeout: 30.0)
        }
    }
    
    
    // MARK: NSNetServiceDelegate
    open func netService(_ sender: NetService, didNotResolve errorDict: [String : NSNumber]) {
        sender.delegate = self
    }
    open func netServiceDidResolveAddress(_ sender: NetService) {
        self.connectWithServer(sender)
    }
    

    // MARK: GCDAsyncSocketDelegate
    open func socket(_ sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        sock.readData(withTimeout: -1.0, tag: 0)
        
        sock.sendMessageObject(Message(type: .SendingDeviceID))
        
        delegate?.didConnect()
    }
    open func socketDidDisconnect(_ sock: GCDAsyncSocket!, withError err: NSError!) {
        delegate?.didDisconnect()
        
        // clearout pending replies and generate errors for them
        replyMessages.removeAll()
        let groups = replyGroups.map { $0.1 }
        replyGroups.removeAll()
        for group in groups {
            group.leave()
        }
    }

    // curried function to send the user's reply to the sender
    // calling with the first set of arguments returns another function which the user then calls
    fileprivate func sendReply(_ sock: GCDAsyncSocket, _ replyID:Int, _ reply:[String:Any]) {
        sock.sendMessageObject(Message(type: .Reply, replyID: replyID, contents: reply))
    }
    open func socket(_ sock: GCDAsyncSocket!, didRead data: Data!, withTag tag: Int) {
        sock.readData(withTimeout: -1.0, tag: 0)
        
        if let message = Message(data: data) {
            switch message.type {
            case .Reply:
                if let replyID = message.replyID, let group = replyGroups.removeValue(forKey: replyID) {
                    if let reply = message.contents {
                        replyMessages[replyID] = reply as [String : Any]?
                    }
                    group.leave()
                }
                else {
                    print("Unable to process reply. Reply received for unknown originator or duplicate reply")
                    // error
                }
                
            case .Broadcast:
                if let contents = message.contents {
                    if let replyID = message.replyID {
//                        self.delegate?.didReceiveBroadcast(contents as [String : Any], replyHandler: sendReply(sock, replyID))
                    }
                    else {
                        self.delegate?.didReceiveBroadcast(contents as [String : Any])
                    }
                }
                else {
                    print("Unhandled Broadcast Received: \(message.type)")
                }
                
            case .Message:
                if let contents = message.contents {
                    if let replyID = message.replyID {
//                        self.delegate?.didReceiveMessage(contents as [String : Any], replyHandler: sendReply(sock, replyID))
                    }
                    else {
                        self.delegate?.didReceiveMessage(contents as [String : Any])
                    }
                }
                else {
                    print("Unhandled Message Received: \(message.type)")
                }
                
            case .RequestDeviceID:
                sock.sendMessageObject(Message(type: .SendingDeviceID))
            default:
                print("Unhandled Message Received: \(message.type)")
            }
        }
        else {
            print("Unknown Data: \(data)")
            if let testString = String(data: data, encoding: String.Encoding.utf8) {
                print("       UTF8 : \(testString)")
            }
            else if let testString = String(data: data, encoding: String.Encoding.windowsCP1250) {
                print("     CP1250 : \(testString)")
            }
        }
        
    }

    
}




