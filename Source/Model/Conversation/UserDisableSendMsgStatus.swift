//
//  UserDisableSendMsgStatus.swift
//  WireDataModel
//
//  Created by 王杰 on 2019/4/25.
//  Copyright © 2019 Wire Swiss GmbH. All rights reserved.
//

@objc
@objcMembers public class UserDisableSendMsgStatus: ZMManagedObject {
    
    @NSManaged public var block_time: Int64
    @NSManaged public var withConversation: ZMConversation?
    @NSManaged public var userid: String?
    @NSManaged public var needUpload: Bool
    
    public override func keysTrackedForLocalModifications() -> Set<String> {
        return [ZMConversationInfoBlockTimeKey]
    }
    
    public override static func entityName() -> String {
        return "UserDisableSendMsgStatus"
    }
    
    public override static func isTrackingLocalModifications() -> Bool {
        return true
    }
    
    public override static func sortKey() -> String? {
        return ZMConversationInfoBlockTimeKey
    }
    
    public override static func predicateForObjectsThatNeedToBeInsertedUpstream() -> NSPredicate? {
        return NSPredicate(format: "%K == YES", #keyPath(UserDisableSendMsgStatus.needUpload))
    }
    
    public override static func predicateForObjectsThatNeedToBeUpdatedUpstream() -> NSPredicate? {
        let baseModifiedPredicate = NSPredicate(format: "modifiedKeys != NULL AND %K == NO", #keyPath(UserDisableSendMsgStatus.needUpload))
        return baseModifiedPredicate
    }
    
}

extension UserDisableSendMsgStatus {
    
    static public func update(managedObjectContext: NSManagedObjectContext, block_time: NSNumber?, user: String?, conversation: String?, fromPushChannel: Bool = false) {
        guard let block_time = block_time, let u = user, let conv = conversation, let uuid = UUID(uuidString: conv) else {return}
        guard let conver = ZMConversation(remoteID: uuid, createIfNeeded: false, in: managedObjectContext) else {return}
        let insert = {
            let entry = UserDisableSendMsgStatus.insertNewObject(in: managedObjectContext)
            entry.block_time = block_time.int64Value
            entry.userid = u
            entry.withConversation = conver
            if !fromPushChannel {
               entry.needUpload = true
            }
            conver.disableSendLastModifiedDate = Date()
        }
        var exist: Bool = false
        conver.membersSendMsgStatuses.forEach { (status) in
            if status.userid == u {
                status.block_time = block_time.int64Value
                if !fromPushChannel {
                    status.setLocallyModifiedKeys([ZMConversationInfoBlockTimeKey])
                }
                conver.disableSendLastModifiedDate = Date()
                exist = true
                return
            }
        }
        if !exist {
            insert()
        }
    }
    
    static public func getBlockTime(managedObjectContext: NSManagedObjectContext, user: String?, conversation: String?) -> NSNumber? {
        guard let user = user, let convString = conversation, let uuid = UUID.init(uuidString: convString), let conver = ZMConversation.init(remoteID: uuid, createIfNeeded: false, in: managedObjectContext) else {return nil}
        var blockTime: NSNumber?
        conver.membersSendMsgStatuses.forEach { (status) in
            if status.userid == user {
                blockTime = NSNumber(value: status.block_time)
                return
            }
        }
        return blockTime
    }
    
    /*   {
     access =     (
     invite
     );
     creator = "a15b05f1-e1a1-411d-ac9c-d201cab2173c";
     id = "618db01d-a506-4d50-a534-eca5e588495c";
     "last_event" = "0.0";
     "last_event_time" = "1970-01-01T00:00:00.000Z";
     members =     {
     others =         (
     {
     id = "136da6ee-849a-4b98-8c9b-d90312fe040e";
     status = 0;
     },
     {
     aliasname = yolll;
     id = "22200053-2e38-48aa-9ec5-2bc6c853c855";
     status = 0;
     },
     {
     aliasname = "new18-555-04";
     id = "5e61dc20-0954-4a36-85d8-6523ba0f24be";
     status = 0;
     },
     {
     id = "df3f5469-6885-45de-9b74-bb22cbea95f1";
     status = 0;
     }
     );
     self =         {
     "alias_name" = 1;
     "alias_name_ref" = "We\U2019";
     hidden = 0;
     "hidden_ref" = "<null>";
     id = "a15b05f1-e1a1-411d-ac9c-d201cab2173c";
     "otr_archived" = 0;
     "otr_archived_ref" = "<null>";
     "otr_muted" = 1;
     "otr_muted_ref" = "1970-01-01T00:00:00.000Z";
     service = "<null>";
     status = 0;
     "status_ref" = "0.0";
     "status_time" = "1970-01-01T00:00:00.000Z";
     };
     };
     name = "xuhl302, \U738b\U6770, Jio";
     team = "<null>";
     type = 0;
     }
     */
    static public func create(from transportData: Dictionary<String,Any>?, managedObjectContext: NSManagedObjectContext, inConversation: String?) -> Void {
        guard let transportdata = transportData else {return}
        guard let members = transportdata["members"] as? Dictionary<String,Any> else {return}
        guard let others = members["others"] as? Array<Dictionary<String,Any>> else {return}
        guard let self_ = members["self"] as? Dictionary<String,Any> else {return}
        for other in others {
            guard let id = other["id"] as? String  else {continue}
            guard let block_time = other["block_time"] as? Int64 else {continue}
            UserDisableSendMsgStatus.update(managedObjectContext: managedObjectContext, block_time: NSNumber.init(value: block_time), user: id, conversation: inConversation, fromPushChannel: true)
        }
        guard let self_blocktime = self_["block_time"] as? Int64 else {return}
        let selfuser = ZMUser.selfUser(in: managedObjectContext).remoteIdentifier.transportString()
        UserDisableSendMsgStatus.update(managedObjectContext: managedObjectContext, block_time: NSNumber.init(value: self_blocktime), user: selfuser, conversation: inConversation, fromPushChannel: true)
    }
}
