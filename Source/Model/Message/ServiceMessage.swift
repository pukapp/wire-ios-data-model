//
//  ServiceMessage.swift
//  WireDataModel
//
//  Created by 王杰 on 2019/5/13.
//  Copyright © 2019 Wire Swiss GmbH. All rights reserved.
//


@objc
@objcMembers public class ServiceMessage: ZMManagedObject {
    
    @NSManaged public var type: String?
    @NSManaged public var text: String?
    @NSManaged public var url: String?
    @NSManaged public var appid: String?
    @NSManaged public var isRead: Bool
    @NSManaged public var inConversation: ZMConversation?
    
    
    @NSManaged public var systemMessage: ZMSystemMessage?
    
    public override static func entityName() -> String {
        return "ServiceMessage"
    }
    
    public override static func isTrackingLocalModifications() -> Bool {
        return false
    }
}
