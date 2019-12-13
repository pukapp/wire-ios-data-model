////  Operation.swift
//  WireDataModel
//
//  Created by DBH on 2019/12/13.
//  Copyright © 2019 Wire Swiss GmbH. All rights reserved.
//

import Foundation

@objc public enum MessageOperationType: UInt16 {
    case illegal
    
    public var uniqueValue: String {
        switch self {
        case .illegal: return "illegal"
        }
    }
}

@objcMembers class Operation: ZMManagedObject {

    @NSManaged var state: Bool
    @NSManaged var type: String
    
    @NSManaged var message: ZMMessage?
    @NSManaged var operateUser: ZMUser?
    
    public static func insertOperation(_ type: MessageOperationType, byOperator user: ZMUser, onMessage message: ZMMessage) -> Operation {
        let obj = insertNewObject(in: message.managedObjectContext!)
        obj.message = message
        obj.type = type.uniqueValue
        obj.state = type == .illegal
        obj.operateUser = user
        return obj
    }
    
    override class func entityName() -> String {
        return "Operation"
    }
}
