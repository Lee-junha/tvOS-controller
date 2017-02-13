//
//  SharedKeys.swift
//  tvOSGame
//
//  Created by Paul Jones on 26/10/2015.
//  Copyright © 2015 Fluid Pixel. All rights reserved.
//

import Foundation
import UIKit

let SERVICE_NAME = "_probonjore._tcp."

let NET_SERVICE_NAME = "com.fpstudios.iPhone-controller Lauren"

let CURRENT_DEVICE_VENDOR_ID:String = UIDevice.current.identifierForVendor!.uuidString

enum MessageDirection : CustomStringConvertible {
    case incoming
    case outgoing
    
    var description: String {
        switch self {
        case .incoming: return "Incoming"
        case .outgoing: return "Outgoing"
        }
    }
}


enum MessageType : String {
    static let cases = [Message, Broadcast, Reply, RequestDeviceID, SendingDeviceID]
    
    case Message = "kMessage"
    case Broadcast = "kBroadcast"
    case Reply = "kReply"
    
    case RequestDeviceID = "kRequestDeviceID"
    case SendingDeviceID = "kSendingDeviceID"
}

extension MessageType : CustomStringConvertible {
    var description: String {
        switch self {
        case .Message: return "Message"
        case .Broadcast: return "Broadcast"
        case .Reply: return "Reply"
        case .RequestDeviceID: return "RequestDeviceID"
        case .SendingDeviceID: return "SendingDeviceID"
//        default: return self.rawValue.substringFromIndex(self.rawValue.startIndex.successor())
        }
    }
}

struct Message {
    let direction: MessageDirection
    let type: MessageType
    let senderDeviceID: String
    let targetDeviceID: String?
    let replyID: Int?
    let contents: [String: Any]?
    
    var isForThisDevice: Bool {
        if let targetDeviceID = self.targetDeviceID {
            return targetDeviceID == CURRENT_DEVICE_VENDOR_ID
        }
        return true
    }
    
    init(type: MessageType, replyID: Int? = nil, contents: [String: Any]? = nil, targetDeviceID: String? = nil) {
        self.type = type
        self.senderDeviceID = CURRENT_DEVICE_VENDOR_ID
        self.targetDeviceID = targetDeviceID
        self.replyID = replyID
        self.contents = contents
        self.direction = .outgoing
    }
    
    var dictionary: [String: Any] {
        var rv: [String: Any] = ["senderDeviceID":senderDeviceID as Any]
        
        if let contents = self.contents {
            rv[type.rawValue] = contents as Any?
        }
        else {
            rv[type.rawValue] = type.rawValue as Any?
        }
        
        if let targetDeviceID = self.targetDeviceID {
            rv["targetDeviceID"] = targetDeviceID as Any?
        }
        
        if let replyID = self.replyID {
            rv["replyID"] = replyID as Any?
        }
        
        return rv
    }
    var data: Data {
        return NSKeyedArchiver.archivedData(withRootObject: self.dictionary)
    }
    
    init?(dictionary: [String:Any]) {
        self.direction = .incoming
        
        self.senderDeviceID = dictionary["senderDeviceID"] as! String
        self.targetDeviceID = dictionary["targetDeviceID"] as? String
        self.replyID = dictionary["replyID"] as? Int
        
        for type in MessageType.cases {
            if let object = dictionary[type.rawValue] {
                self.type = MessageType(rawValue: type.rawValue)!
                if let text = object as? String, text == type.rawValue {
                    self.contents = nil
                    return
                }
                else if let message = object as? [String: Any] {
                    self.contents = message
                    return
                }
                break
            }
        }
        return nil
    }
    
    init?(data: Data) {
        if let object = NSKeyedUnarchiver.unarchiveObject(with: data) {
            if let dictionary = object as? [String: Any] {
                self.init(dictionary: dictionary)
                return
            }
        }
        return nil
    }
    
}

extension GCDAsyncSocket {
    func sendMessageObject(_ message: Message, withTimeout: TimeInterval = -1.0) {
        self.write(message.data, withTimeout: withTimeout, tag: 0)
    }
}

