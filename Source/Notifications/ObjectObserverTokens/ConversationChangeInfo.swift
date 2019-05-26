//
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


import Foundation

extension ZMConversation : ObjectInSnapshot {
    
    @objc public static var observableKeys : Set<String> {
        return Set([#keyPath(ZMConversation.messages),
                    #keyPath(ZMConversation.lastModifiedDate),
                    #keyPath(ZMConversation.isArchived),
                    #keyPath(ZMConversation.conversationListIndicator),
                    #keyPath(ZMConversation.mutedStatus),
                    #keyPath(ZMConversation.securityLevel),
                    #keyPath(ZMConversation.displayName),
                    #keyPath(ZMConversation.estimatedUnreadCount),
                    #keyPath(ZMConversation.clearedTimeStamp),
                    #keyPath(ZMConversation.lastServerSyncedActiveParticipants),
                    #keyPath(ZMConversation.isSelfAnActiveMember),
                    #keyPath(ZMConversation.relatedConnectionState),
                    #keyPath(ZMConversation.team),
                    #keyPath(ZMConversation.accessModeStrings),
                    #keyPath(ZMConversation.accessRoleString),
                    #keyPath(ZMConversation.remoteIdentifier),
                    #keyPath(ZMConversation.localMessageDestructionTimeout),
                    #keyPath(ZMConversation.syncedMessageDestructionTimeout),
                    #keyPath(ZMConversation.language),
                    //new add
                    #keyPath(ZMConversation.groupImageSmallKey),
                    #keyPath(ZMConversation.groupImageMediumKey),
                    #keyPath(ZMConversation.autoReply),
                    #keyPath(ZMConversation.isOpenUrlJoin),
                    #keyPath(ZMConversation.isOnlyCreatorInvite),
                    #keyPath(ZMConversation.isAllowViewMembers),
                    #keyPath(ZMConversation.isOpenCreatorInviteVerify),
                    #keyPath(ZMConversation.isOpenMemberInviteVerify),
                    #keyPath(ZMConversation.creator),
                    #keyPath(ZMConversation.selfRemark),
                    #keyPath(ZMConversation.apps),
                    #keyPath(ZMConversation.topWebApps),
                    #keyPath(ZMConversation.communityID),
                    #keyPath(ZMConversation.isPlaceTop),
                    #keyPath(ZMConversation.isDisableSendMsg),
                    #keyPath(ZMConversation.disableSendLastModifiedDate),
                    #keyPath(ZMConversation.lastServiceMessageTimeStamp),
                    #keyPath(ZMConversation.orator),
            ])
    }

    public var notificationName: Notification.Name {
        return .ConversationChange
    }

}


////////////////////
////
//// ConversationObserverToken
//// This can be used for observing only conversation properties
////
////////////////////


@objcMembers public final class ConversationChangeInfo : ObjectChangeInfo {
    // 聊天置顶状态变化
    public var placeTopStatusChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.isPlaceTop))
    }
    
    public var communityIDChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.communityID))
    }
    
    public var appsChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.apps))
    }
    public var topAppsChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.topWebApps))
    }
    /// 新增对别人的回复类型改变
    public var replyTypeChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.autoReply))
    }
    
    /// 头像改变
    public var headerImgChanged : Bool {
        return changedKeysContain(keys:#keyPath(ZMConversation.groupImageSmallKey)) ||
               changedKeysContain(keys:#keyPath(ZMConversation.groupImageMediumKey))
    }
    
    /// 开启链接加入允许开启
    public var canOpenUrlChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.isOnlyCreatorInvite)) ||
               changedKeysContain(keys: #keyPath(ZMConversation.isOpenCreatorInviteVerify))
    }
    //群禁言
    public var disableSendMsgChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.isDisableSendMsg))
    }
    //是否有新的通知消息
    public var lastServiceMessageChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.lastServiceMessageTimeStamp))
    }
    //群成员禁言
    public var disableSendMsgLastModifiedDateChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.disableSendLastModifiedDate))
    }
    /// 群主确认或者成员确认改变
    public var isOpenInviteVerifyChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.isOpenCreatorInviteVerify))
    }
    //群演讲者变动
    public var oratorChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.orator))
    }
    
    public var conversationSelfRemarkChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.selfRemark))
    }
    
    public var groupCreatorChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.creator))
    }
    
    public var openUrlChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.isOpenUrlJoin))
    }
    
    public var allowViewMembers: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.isAllowViewMembers))
    }
    
    // new add
    public var selfRemarkChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.selfRemark))
    }
    
    public var languageChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.language))
    }

    public var messagesChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.messages))
    }

    public var participantsChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.lastServerSyncedActiveParticipants), #keyPath(ZMConversation.isSelfAnActiveMember))
    }

    public var nameChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.displayName))
    }

    public var lastModifiedDateChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.lastModifiedDate))
    }

    public var unreadCountChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.estimatedUnreadCount))
    }

    public var connectionStateChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.relatedConnectionState))
    }

    public var isArchivedChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.isArchived))
    }

    public var mutedMessageTypesChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.mutedStatus))
    }

    public var conversationListIndicatorChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.conversationListIndicator))
    }

    public var clearedChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.clearedTimeStamp))
    }

    public var teamChanged: Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.team))
    }

    public var securityLevelChanged : Bool {
        return changedKeysContain(keys: SecurityLevelKey)
    }
        
    public var createdRemotelyChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.remoteIdentifier))
    }
    
    public var allowGuestsChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.accessModeStrings)) ||
               changedKeysContain(keys: #keyPath(ZMConversation.accessRoleString))
    }
    
    public var destructionTimeoutChanged : Bool {
        return changedKeysContain(keys: #keyPath(ZMConversation.localMessageDestructionTimeout)) ||
                changedKeysContain(keys: #keyPath(ZMConversation.syncedMessageDestructionTimeout))
    }
    
    public var conversation : ZMConversation { return self.object as! ZMConversation }
    
    public override var description : String { return self.debugDescription }
    public override var debugDescription : String {
        return ["replyTypeChanged: \(replyTypeChanged)",
                "appsChanged: \(appsChanged)",
                "topAppsChanged: \(topAppsChanged)",
                "messagesChanged: \(messagesChanged)",
                "headerImgChanged: \(headerImgChanged)",
                "canOpenUrlChanged: \(canOpenUrlChanged)",
                "participantsChanged: \(participantsChanged)",
                "nameChanged: \(nameChanged)",
                "unreadCountChanged: \(unreadCountChanged)",
                "lastModifiedDateChanged: \(lastModifiedDateChanged)",
                "connectionStateChanged: \(connectionStateChanged)",
                "isArchivedChanged: \(isArchivedChanged)",
                "mutedMessageTypesChanged: \(mutedMessageTypesChanged)",
                "conversationListIndicatorChanged \(conversationListIndicatorChanged)",
                "clearedChanged \(clearedChanged)",
                "securityLevelChanged \(securityLevelChanged)",
                "teamChanged \(teamChanged)",
                "createdRemotelyChanged \(createdRemotelyChanged)",
                "destructionTimeoutChanged \(destructionTimeoutChanged)",
                "languageChanged \(languageChanged)"].joined(separator: ", ")
    }
    
    public required init(object: NSObject) {
        super.init(object: object)
    }
    
    static func changeInfo(for conversation: ZMConversation, changes: Changes) -> ConversationChangeInfo? {
        guard changes.changedKeys.count > 0 || changes.originalChanges.count > 0 else { return nil }
        let changeInfo = ConversationChangeInfo(object: conversation)
        changeInfo.changeInfos = changes.originalChanges
        changeInfo.changedKeys = changes.changedKeys
        return changeInfo
    }
}

@objc public protocol ZMConversationObserver : NSObjectProtocol {
    func conversationDidChange(_ changeInfo: ConversationChangeInfo)
}


extension ConversationChangeInfo {

    /// Adds a ZMConversationObserver to the specified conversation
    /// You must hold on to the token and use it to unregister
    @objc(addObserver:forConversation:)
    public static func add(observer: ZMConversationObserver, for conversation: ZMConversation) -> NSObjectProtocol {
        return ManagedObjectObserverToken(name: .ConversationChange,
                                          managedObjectContext: conversation.managedObjectContext!,
                                          object: conversation)
        { [weak observer] (note) in
            guard let `observer` = observer,
                let changeInfo = note.changeInfo as? ConversationChangeInfo
                else { return }
            
            observer.conversationDidChange(changeInfo)
        } 
    }
}


/// Conversation degraded
extension ConversationChangeInfo {
    
    /// True if the conversation security level is .secureWithIgnored and we tried to send a message
    @objc public var didNotSendMessagesBecauseOfConversationSecurityLevel : Bool {
        return self.securityLevelChanged &&
            self.conversation.securityLevel == .secureWithIgnored &&
            !self.conversation.messagesThatCausedSecurityLevelDegradation.isEmpty
    }
    
    /// Users that caused the conversation to degrade
    @objc public var usersThatCausedConversationToDegrade : Set<ZMUser> {
        guard let activeParticipants = self.conversation.activeParticipants.array as? [ZMUser] else {
            return []
        }
        
        let untrustedParticipants = activeParticipants.filter { user -> Bool in
            return !user.trusted()
        }
        return Set(untrustedParticipants)
    }
}
