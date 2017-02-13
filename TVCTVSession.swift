//
//  RemoteReceiver.swift
//  tvOSGame
//
//  Created by Paul Jones on 26/10/2015.
//  Copyright © 2015 Fluid Pixel. All rights reserved.
//

import Foundation

let ERROR_SEND_FAILED = NSError(domain: "com.fpstudios.tvOSController", code: -100, userInfo: [NSLocalizedDescriptionKey:"Failed To Send Message"])

let ERROR_REPLY_FAILED = NSError(domain: "com.fpstudios.tvOSController", code: -200, userInfo: [NSLocalizedDescriptionKey:"No Message In Reply"])


@available(tvOS 9.0, *)
@objc
protocol TVCTVSessionDelegate : NSObjectProtocol {
    
    func didReceiveMessage(_ message: [String: Any], fromDevice: String)
    func didReceiveMessage(_ message: [String: Any], fromDevice: String, replyHandler: ([String: Any]) -> Void)

    func deviceDidConnect(_ device: String)
    func deviceDidDisconnect(_ device: String)
    
}

@available(tvOS 9.0, *)
@objc
open class TVCTVSession : NSObject, NetServiceDelegate, GCDAsyncSocketDelegate, NetServiceBrowserDelegate {
    weak var delegate:TVCTVSessionDelegate?

    internal var service:NetService!
    internal var socket:GCDAsyncSocket!
    internal var devSock:[GCDAsyncSocket: String?] = [:]
    
    internal var replyGroups:[Int: DispatchGroup] = [:]
    internal var replyMessages:[Int:(String, [String: Any])] = [:]
    internal var replyIdentifierCounter:Int = 0
    
    internal let delegateQueue = DispatchQueue.main
    
    open var connectedDevices:Set<String> {
        let values = devSock.values.flatMap { $0 }
        return Set<String>(values)
    }
            
    open func broadcastMessage(_ message: [String: Any], replyHandler: ((String, [String: Any]) -> Void)?, errorHandler: ((NSError) -> Void)?) {
        if let rh = replyHandler {
            for sock in devSock.keys {
                replyIdentifierCounter = replyIdentifierCounter + 1
                let replyID = replyIdentifierCounter
                let group = DispatchGroup()
                group.enter()
                replyGroups[replyID] = group
                
                group.notify(queue: DispatchQueue.main) {
                    if let params = self.replyMessages[replyID] {
                        rh(params.0, params.1)
                    }
                    else {
                        errorHandler?(ERROR_REPLY_FAILED)
                    }
                }
                sock.write(Message(type: .Broadcast, replyID: replyID, contents: message).data as Data!, withTimeout: -1.0, tag: 0)
            }
        }
        else {
            for sock in devSock.keys {
                sock.write(Message(type: .Broadcast, contents: message).data as Data!, withTimeout: -1.0, tag: 0)
            }
        }        
    }
    
    open func sendMessage(_ deviceID:String, message: [String: Any], replyHandler: ((String, [String: Any]) -> Void)?, errorHandler: ((NSError) -> Void)?) {
        
        let socklist = devSock.filter { $0.1 == deviceID }
        
        if let sock = socklist.first?.0 {
            if let rh = replyHandler {
                replyIdentifierCounter = replyIdentifierCounter + 1
                let replyID = replyIdentifierCounter
                let group = DispatchGroup()
                group.enter()
                replyGroups[replyID] = group
                
                group.notify(queue: DispatchQueue.main) {
                    if let params = self.replyMessages[replyID] {
                        rh(params.0, params.1)
                    }
                    else {
                        errorHandler?(ERROR_REPLY_FAILED)
                    }
                }
                sock.sendMessageObject(Message(type: .Message, replyID: replyID, contents: message))
            }
            else {
                sock.sendMessageObject(Message(type: .Message, contents: message))
            }
        }
        else {
            // TODO: Error! device not connected
            errorHandler?(ERROR_SEND_FAILED)
        }
    }
    
    fileprivate func dispatchReply(_ replyHandler: ((String, [String: Any]) -> Void)?, errorHandler: ((NSError) -> Void)?) -> Int {
        replyIdentifierCounter = replyIdentifierCounter + 1
        let replyID = replyIdentifierCounter
        let group = DispatchGroup()
        group.enter()
        replyGroups[replyID] = group
        
        group.notify(queue: DispatchQueue.main) {
            if let params = self.replyMessages[replyID] {
                replyHandler?(params.0, params.1)
            }
            else {
                errorHandler?(ERROR_REPLY_FAILED)
            }
        }
        
        return replyID
        
    }
    
    override init() {
        super.init()
        self.socket = GCDAsyncSocket(delegate: self, delegateQueue: delegateQueue)
        
        try! self.socket.accept(onPort: 0)
        self.service = NetService(domain: "local.", type: SERVICE_NAME, name: NET_SERVICE_NAME, port: Int32(self.socket.localPort()))
        self.service.delegate = self
        self.service.publish()

    }
    
    // MARK: GCDAsyncSocketDelegate
    open func socket(_ sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {

        if let oldValue = devSock.updateValue(nil, forKey: newSocket), let oldDevice = oldValue {
            self.delegate?.deviceDidDisconnect(oldDevice)
        }
        
        newSocket.sendMessageObject(Message(type: .RequestDeviceID))

        newSocket.readData(withTimeout: -1.0, tag: 0)
        
    }
    
    open func socketDidDisconnect(_ sock: GCDAsyncSocket!, withError err: NSError!) {
        if let oldDevice = devSock.removeValue(forKey: sock), let dev = oldDevice {
            self.delegate?.deviceDidDisconnect(dev)
            print("Device Disconnected \(dev) from socket \(sock)")
        }
        else {
            print("Socket Disconnected \(sock)")
        }

        if self.devSock.count == 0 {
            // restart connections
        }
    }
    
    
    // curried function to send the user's reply to the sender
    // calling with the first set of arguments returns another function which the user then calls
    fileprivate func sendReply(_ sock: GCDAsyncSocket, _ replyID:Int, _ reply:[String: Any]) {
        sock.sendMessageObject(Message(type: .Reply, replyID: replyID, contents: reply))
    }
    
    open func socket(_ sock: GCDAsyncSocket!, didRead data: Data!, withTag tag: Int) {
        sock.readData(withTimeout: -1.0, tag: 0)

        if let message = Message(data: data) {
            
            // Beware the double optional!
            // devSock.updateValue(...) returns the value which was replaced but this can be nil. Some(Some(...)) or Some(None)
            // If no value was replced the method returns a double optional ?? which must be unwrapped twice
            if let oldValue = devSock.updateValue(message.senderDeviceID, forKey: sock), let oldDevice = oldValue {
                if oldDevice != message.senderDeviceID {
                    print("\(oldDevice) Unexpected device on socket")
                    self.delegate?.deviceDidDisconnect(oldDevice)
                    self.delegate?.deviceDidConnect(message.senderDeviceID)
                }
            }
            else {
                print("\(message.senderDeviceID) New Device")
                self.delegate?.deviceDidConnect(message.senderDeviceID)
            }
            
            switch message.type {
            case .Message:
                if let replyID = message.replyID {
                    self.delegate?.didReceiveMessage(message.contents ?? [:], fromDevice: message.senderDeviceID, replyHandler: { [weak self] reply in
                        guard let `self` = self else { return }
                        self.sendReply(sock, replyID, reply)
                    })
                }
                else {
                    self.delegate?.didReceiveMessage(message.contents ?? [:], fromDevice: message.senderDeviceID)
                }
            case .Reply:
                if let replyID = message.replyID, let group = replyGroups.removeValue(forKey: replyID) {
                    
                    if let contents = message.contents {
                        replyMessages[replyID] = (message.senderDeviceID, contents)
                    }
                    
                    group.leave()
                    
                }
            case .SendingDeviceID:
                // already handled
                break
            case .RequestDeviceID:
                print("Device ID Requested")
                //sock.sendMessageObject(Message(type: SendingDeviceID, targetDeviceID: message.senderDeviceID)
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



//internal var arrServices:[NSNetService] = []
//internal var coServiceBrowser:NSNetServiceBrowser!
//internal var dictSockets:[String:AnyObject] = [:]

//    func getSelectedSocket() -> GCDAsyncSocket {
//        if let coServiceName = self.arrServices.first?.name,
//            let rv = self.dictSockets[coServiceName] as? GCDAsyncSocket {
//                return rv
//        }
//        else {
//            fatalError("Could not getSelectedSocket - nil")
//        }
//    }
    
//}

/*
#import "RemoteReceiver.h"
#import "GCDAsyncSocket.h"
#import "tvOSGame-Swift.h"


#define ACK_SERVICE_NAME @"_ack._tcp."



@implementation RemoteReceiver
- (void)netServiceDidPublish:(NSNetService *)service
{
//    NSLog(@"Bonjour Service Published: domain(%@) type(%@) name(%@) port(%i)", [service domain], [service type], [service name], (int)[service port]);
}
- (void)netService:(NSNetService *)service didNotPublish:(NSDictionary *)errorDict
{
//    NSLog(@"Failed to Publish Service: domain(%@) type(%@) name(%@) - %@", [service domain], [service type], [service name], errorDict);
}
-(void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag{
//    NSLog(@"Write data is done");
}
@end
*/



