//
//  UserAliasname.swift
//  WireDataModel
//
//  Created by 王杰 on 2019/2/21.
//  Copyright © 2019 Wire Swiss GmbH. All rights reserved.
//

import UIKit

@objcMembers public class UserAliasname: ZMManagedObject {

    public enum Fields : String {
        case aliasName = "aliasName"
        case remoteIdentifier = "remoteIdentifier"
        case inConverstion = "inConverstion"
    }
    
    @NSManaged public var aliasName : String?
    @NSManaged public var remoteIdentifier : String?
    @NSManaged public var inConverstion : ZMConversation?
    
    public override func keysTrackedForLocalModifications() -> Set<String> {
        return []
    }
    
    public override static func entityName() -> String {
        return "UserAliasname"
    }
    
    public override static func sortKey() -> String? {
        return Fields.remoteIdentifier.rawValue
    }
    
    public override static func isTrackingLocalModifications() -> Bool {
        return false
    }
    
}

extension UserAliasname {
    
    @available(iOSApplicationExtension 9.0, *)
    @objc(updateFromAliasName:remoteIdentifier:managedObjectContext:inConversation:)
    static public func update(from aliasName: String?,remoteIdentifier: String?, managedObjectContext: NSManagedObjectContext, inConversation: ZMConversation? = nil) -> Void {
        
        guard let remoteid = remoteIdentifier else {return}
        
        guard let set = inConversation?.membersAliasname else {
            let entry = UserAliasname.insertNewObject(in: managedObjectContext)
            entry.remoteIdentifier = remoteIdentifier
            entry.aliasName = aliasName
            entry.inConverstion = inConversation
            return
        }
        
        for aliasname in set {
            guard let ali = aliasname as? UserAliasname else {continue}
            guard let id = ali.remoteIdentifier else {continue}
            if id == remoteid && ali.inConverstion?.remoteIdentifier?.transportString() == inConversation?.remoteIdentifier?.transportString() {
                ali.aliasName = aliasName
                break
            }
        }
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
    @objc(createFromTransportData:managedObjectContext:inConversation:)
    static public func create(from transportData: Dictionary<String,Any>?, managedObjectContext: NSManagedObjectContext, inConversation:ZMConversation?) -> Void {
        guard let transportdata = transportData else {return}
        guard let members = transportdata["members"] as? Dictionary<String,Any> else {return}
        guard let others = members["others"] as? Array<Dictionary<String,Any>> else {return}
        guard let self_ = members["self"] as? Dictionary<String,Any> else {return}
        for other in others {
            guard let id = other["id"] as? String else {continue}
            guard let aliasname = other["aliasname"] as? String else {return}
            UserAliasname.insert(aliasName: aliasname, remoteIdentifier: id, managedObjectContext: managedObjectContext, inConversation: inConversation)
        }
        guard let self_id = self_["id"] as? String else {return}
        guard let self_aliasname = self_["alias_name_ref"] as? String else {return}
        UserAliasname.insert(aliasName: self_aliasname, remoteIdentifier: self_id, managedObjectContext: managedObjectContext, inConversation: inConversation)
    }
    
    @objc(getUserInConversationAliasNameFrom:userId:)
    static public func getUserInConversationAliasName(from conversation: ZMConversation?, userId:String?) -> String? {
        guard let conv = conversation else {return nil}
        guard let userid = userId else {return nil}
        let aliasNameEntry =  conv.membersAliasname.first { (aliasname) -> Bool in
            guard let alias = aliasname as? UserAliasname else {return false}
            return alias.remoteIdentifier == userid
        } as? UserAliasname
        return aliasNameEntry?.aliasName
    }
    
    
    static private func insert(aliasName: String?,remoteIdentifier: String?, managedObjectContext: NSManagedObjectContext, inConversation: ZMConversation?) -> Void {
        let entry = UserAliasname.insertNewObject(in: managedObjectContext)
        entry.remoteIdentifier = remoteIdentifier
        entry.aliasName = aliasName
        entry.inConverstion = inConversation
    }
}
