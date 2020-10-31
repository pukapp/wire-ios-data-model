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


extension ZMConversation {
    
    override open class func predicateForFilteringResults() -> NSPredicate {
        let selfType = ZMConversationType.init(rawValue: 1)!
        return NSPredicate(format: "\(ZMConversationConversationTypeKey) != \(ZMConversationType.invalid.rawValue) && \(ZMConversationConversationTypeKey) != \(selfType.rawValue)")
    }
    
    ///在外部分享文件时，根据关键字搜索conversation，需要注意-单聊的名称是根据参与者的名称来决定。与conversation的属性是无关的
    @objc
    public class func predicateInSharedConversations(forSearchQuery searchQuery: String) -> NSPredicate! {
        /*新增根据userDefinedName搜索用户
         1.userDefinedName代表设置的中文名称：秘密部落
         2.normalizedUserDefinedName是通过userDefinedName生成的英文字符串如：mi mi bu luo
         输入“秘”
         userDefinedNamePredicate匹配的是否包含“秘”字符串
         namePredicate匹配的是 英文字符串'mi mi bu luo'中五个单词，是否有任意单词以‘mi’开头
         */
        let userDefinedNamePredicate = NSPredicate(format: "userDefinedName MATCHES %@", ".*\(searchQuery).*")
        let formatDict = [ZMNormalizedUserDefinedNameKey: "%K MATCHES %@"]
        guard let namePredicate = NSPredicate(formatDictionary: formatDict, matchingSearch: searchQuery) else { return .none }
        
        ///单聊的话查询参与者的备注，或者name（备注搜索的话耗时太久）
        let regExp = ".*\\b\(searchQuery).*"
        //let friendRemarkPredicate = NSPredicate(format: "(\(ZMConversationConversationTypeKey) == \(ZMConversationType.oneOnOne.rawValue)) AND (ANY %K.reMark MATCHES %@)", ZMConversationLastServerSyncedActiveParticipantsKey, regExp)
        let friendNamePredicate = NSPredicate(format: "(\(ZMConversationConversationTypeKey) == \(ZMConversationType.oneOnOne.rawValue)) AND (ANY %K.name MATCHES %@)", ZMConversationLastServerSyncedActiveParticipantsKey, regExp)
        
        let searchPredicate = NSCompoundPredicate(orPredicateWithSubpredicates:
            [userDefinedNamePredicate,
             namePredicate,
             //friendRemarkPredicate,
             friendNamePredicate])
        
        return searchPredicate
    }
    

    @objc
    public class func predicate(forSearchQuery searchQuery: String) -> NSPredicate! {
//        let formatDict = [ZMNormalizedUserDefinedNameKey: "%K MATCHES %@"]
//            ZMConversationLastServerSyncedActiveParticipantsKey: "(ANY %K.normalizedName MATCHES %@)"]
        
        let formatDict = [ZMNormalizedUserDefinedNameKey: "%K MATCHES %@"]
        guard let namePredicate = NSPredicate(formatDictionary: formatDict, matchingSearch: searchQuery) else { return .none }
        
        ///只有普通群才匹配所有群群成员的名称，并且只根据searchQuery直接匹配，不根据空格分割
        let regExp = ".*\\b\(searchQuery).*"
        let memberPredicate = NSPredicate(format: "(\(ZMConversationConversationTypeKey) == \(ZMConversationType.group.rawValue)) AND (ANY %K.normalizedName MATCHES %@)", ZMConversationLastServerSyncedActiveParticipantsKey, regExp)

        let searchPredicate = NSCompoundPredicate(orPredicateWithSubpredicates:
            [namePredicate,
            memberPredicate])
        
        let activeMemberPredicate = NSPredicate(format: "%K == NULL OR %K == YES", ZMConversationClearedTimeStampKey, ZMConversationIsSelfAnActiveMemberKey)
        let basePredicate = NSPredicate(format: "(\(ZMConversationConversationTypeKey) == \(ZMConversationType.group.rawValue)) OR (\(ZMConversationConversationTypeKey) == \(ZMConversationType.hugeGroup.rawValue))")

        /// do not include team 1 to 1 conversations

        let activeParticipantsPredicate = NSPredicate(format: "%K.@count == 1",                                                                      ZMConversationLastServerSyncedActiveParticipantsKey
        )

        let userDefinedNamePredicate = NSPredicate(format: "%K == NULL",                                                                      ZMConversationUserDefinedNameKey
        )

        let teamRemoteIdentifierPredicate = NSPredicate(format: "%K != NULL",                                                                      TeamRemoteIdentifierDataKey
        )

        let notTeamMemberPredicate = NSCompoundPredicate(notPredicateWithSubpredicate: NSCompoundPredicate(andPredicateWithSubpredicates: [
            activeParticipantsPredicate,
            userDefinedNamePredicate ,
            teamRemoteIdentifierPredicate
            ]))

        return NSCompoundPredicate(andPredicateWithSubpredicates: [
            searchPredicate,
            activeMemberPredicate,
            basePredicate,
            notTeamMemberPredicate
            ])
    }
    
    class func predicateForConversationsWhereSelfUserIsActive() -> NSPredicate {
        return .init(format: "%K == YES", ZMConversationIsSelfAnActiveMemberKey)
    }

    @objc(predicateForConversationsInTeam:)
    class func predicateForConversations(in team: Team?) -> NSPredicate {
        if let team = team {
            return .init(format: "%K == %@", #keyPath(ZMConversation.team), team)
        }

        return .init(format: "%K == NULL", #keyPath(ZMConversation.team))
    }
    
    @objc(predicateForHugeGroupConversations)
    class func predicateForHugeGroupConversations() -> NSPredicate {
        let basePredicate = predicateForFilteringResults()
        let hugeGroupConversationPredicate = NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.hugeGroup.rawValue)")
        return NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, hugeGroupConversationPredicate])
    }

    @objc(predicateForPendingConversations)
    class func predicateForPendingConversations() -> NSPredicate {
        let basePredicate = predicateForFilteringResults()
        let pendingConversationPredicate = NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.connection.rawValue) AND \(ZMConversationConnectionKey).status == \(ZMConnectionStatus.pending.rawValue)")
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, pendingConversationPredicate])
    }
    
    @objc(predicateForClearedConversations)
    class func predicateForClearedConversations() -> NSPredicate {
        let cleared = NSPredicate(format: "\(ZMConversationClearedTimeStampKey) != NULL AND \(ZMConversationIsArchivedKey) == YES")
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [cleared, predicateForValidConversations()])
    }

    @objc(predicateForConversationsIncludingArchived)
    class func predicateForConversationsIncludingArchived() -> NSPredicate {
        
        return predicateForValidConversations()
    }
    
    @objc(predicateForGroupConversations)
    class func predicateForGroupConversations() -> NSPredicate {
        let groupConversationPredicate = NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.group.rawValue)")
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [predicateForConversationsExcludingArchived(), groupConversationPredicate])
    }
    
    @objc(predicateForLabeledConversations:)
    class func predicateForLabeledConversations(_ label: Label) -> NSPredicate {
        let labelPredicate = NSPredicate(format: "%@ IN \(ZMConversationLabelsKey)", label)
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [predicateForConversationsExcludingArchived(), labelPredicate])
    }
    
    class func predicateForConversationsInFolders() -> NSPredicate {
        return NSPredicate(format: "ANY %K.%K == \(Label.Kind.folder.rawValue)", ZMConversationLabelsKey, #keyPath(Label.type))
    }
    
    class func predicateForUnconnectedConversations() -> NSPredicate {
        return NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.connection.rawValue)")
    }
    
    class func predicateForOneToOneConversation() -> NSPredicate {
        return NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.oneOnOne.rawValue)")
    }
    
    class func predicateForTeamOneToOneConversation() -> NSPredicate {
        // We consider a conversation being an existing 1:1 team conversation in case the following point are true:
        //  1. It is a conversation inside a team
        //  2. The only participants are the current user and the selected user
        //  3. It does not have a custom display name
        
        let isTeamConversation = NSPredicate(format: "team != NULL")
        let isGroupConversation = NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.group.rawValue)")
        let hasNoUserDefinedName = NSPredicate(format: "\(ZMConversationUserDefinedNameKey) == NULL")
        let hasOnlyOneParticipant = NSPredicate(format: "\(ZMConversationLastServerSyncedActiveParticipantsKey).@count == 1")
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [isTeamConversation, isGroupConversation, hasNoUserDefinedName, hasOnlyOneParticipant])
    }
    
    @objc(predicateForOneToOneConversations)
    class func predicateForOneToOneConversations() -> NSPredicate {
        // We consider a conversation to be one-to-one if it's of type .oneToOne, is a team 1:1 or an outgoing connection request.
        let oneToOneConversationPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: [predicateForOneToOneConversation(), predicateForTeamOneToOneConversation(), predicateForUnconnectedConversations()])
        let notInFolderPredicate = NSCompoundPredicate(notPredicateWithSubpredicate: predicateForConversationsInFolders())
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [predicateForConversationsExcludingArchived(), oneToOneConversationPredicate, notInFolderPredicate])
    }
    
    @objc(predicateForArchivedConversations)
    class func predicateForArchivedConversations() -> NSPredicate {
        return NSCompoundPredicate(andPredicateWithSubpredicates: [predicateForConversationsIncludingArchived(), NSPredicate(format: "\(ZMConversationIsArchivedKey) == YES")])
    }

    @objc(predicateForConversationsExcludingArchived)
    class func predicateForConversationsExcludingArchived() -> NSPredicate {
        return predicateForConversationsIncludingArchived()
    }

    @objc(predicateForSharableConversations)
    class func predicateForSharableConversations() -> NSPredicate {
        let basePredicate = predicateForConversationsIncludingArchived()
        let hasOtherActiveParticipants = NSPredicate(format: "\(ZMConversationLastServerSyncedActiveParticipantsKey).@count > 0")
        let oneOnOneOrGroupConversation = NSPredicate(format: "\(ZMConversationConversationTypeKey) == \(ZMConversationType.oneOnOne.rawValue) OR \(ZMConversationConversationTypeKey) == \(ZMConversationType.group.rawValue) OR \(ZMConversationConversationTypeKey) == \(ZMConversationType.hugeGroup.rawValue)")
        let selfIsActiveMember = NSPredicate(format: "isSelfAnActiveMember == YES")
        let synced = NSPredicate(format: "\(remoteIdentifierDataKey()!) != NULL")
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, oneOnOneOrGroupConversation, hasOtherActiveParticipants, selfIsActiveMember, synced])
    }
    
    private class func predicateForValidConversations() -> NSPredicate {
        let basePredicate = predicateForFilteringResults()
        let notAConnection = NSPredicate(format: "\(ZMConversationConversationTypeKey) != \(ZMConversationType.connection.rawValue)")
        let activeConnection = NSPredicate(format: "NOT \(ZMConversationConnectionKey).status IN %@", [NSNumber(value: ZMConnectionStatus.pending.rawValue),
                                                                                                       NSNumber(value: ZMConnectionStatus.ignored.rawValue),
                                                                                                       NSNumber(value: ZMConnectionStatus.cancelled.rawValue)]) //pending connections should be in other list, ignored and cancelled are not displayed
        let predicate1 = NSCompoundPredicate(orPredicateWithSubpredicates: [notAConnection, activeConnection]) // one-to-one conversations and not pending and not ignored connections
        let noConnection = NSPredicate(format: "\(ZMConversationConnectionKey) == nil") // group conversations
        let notBlocked = NSPredicate(format: "\(ZMConversationConnectionKey).status != \(ZMConnectionStatus.blocked.rawValue)")
        let predicate2 = NSCompoundPredicate(orPredicateWithSubpredicates: [noConnection, notBlocked]) //group conversations and not blocked connections
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: [basePredicate, predicate1, predicate2])
    }
    
}
