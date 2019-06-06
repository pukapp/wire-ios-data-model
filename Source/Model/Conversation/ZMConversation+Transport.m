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


@import WireTransport;

#import "ZMConversation+Transport.h"
#import "ZMConversation+Internal.h"
#import "ZMUser+Internal.h"
#import "ZMMessage+Internal.h"
#import "ZMUpdateEvent+WireDataModel.h"
#import <WireDataModel/WireDataModel-Swift.h>

static NSString* ZMLogTag ZM_UNUSED = @"Conversations";

static NSString *const ConversationInfoNameKey = @"name";
static NSString *const ConversationInfoTypeKey = @"type";
static NSString *const ConversationInfoIDKey = @"id";

static NSString *const ConversationInfoOthersKey = @"others";
static NSString *const ConversationInfoMembersKey = @"members";
static NSString *const ConversationInfoCreatorKey = @"creator";
static NSString *const ConversationInfoTeamIdKey = @"team";
static NSString *const ConversationInfoAccessModeKey = @"access";
static NSString *const ConversationInfoAccessRoleKey = @"access_role";
static NSString *const ConversationInfoMessageTimer = @"message_timer";

static NSString *const ConversationInfoAppsKey = @"apps";


NSString *const ZMConversationInfoOTRMutedValueKey = @"otr_muted";
NSString *const ZMConversationInfoOTRMutedStatusValueKey = @"otr_muted_status";
NSString *const ZMConversationInfoOTRMutedReferenceKey = @"otr_muted_ref";
NSString *const ZMConversationInfoOTRArchivedValueKey = @"otr_archived";
NSString *const ZMConversationInfoOTRArchivedReferenceKey = @"otr_archived_ref";


// 新增
static NSString *const ConversationInfoAutoReplyKey = @"auto_reply";

// 聊天置顶
NSString *const ZMConversationInfoPlaceTopKey = @"place_top";

NSString *const ZMConversationInfoOTRSelfRemarkBoolKey = @"alias_name";
NSString *const ZMConversationInfoOTRSelfRemarkReferenceKey = @"alias_name_ref";
NSString *const ZMConversationInfoOTRSelfVerifyKey = @"confirm";
NSString *const ZMConversationInfoMemberInviteVerfyKey = @"memberjoin_confirm";
NSString *const ZMConversationInfoOTRCreatorChangeKey = @"new_creator";
NSString *const ZMConversationInfoBlockTimeKey = @"block_time";
NSString *const ZMConversationInfoBlockUserKey = @"block_user";
NSString *const ZMConversationInfoOratorKey = @"orator";
NSString *const ZMConversationInfoManagerKey = @"manager";
NSString *const ZMConversationInfoManagerAddKey = @"man_add";
NSString *const ZMConversationInfoManagerDelKey = @"man_del";
NSString *const ZMConversationInfoOTRCanAddKey = @"addright";
NSString *const ZMCOnversationInfoOTROpenUrlJoinKey = @"url_invite";
NSString *const ZMCOnversationInfoOTRAllowViewMembersKey = @"viewmem";
NSString *const ZMConversationInfoTopAppsKey = @"top_apps_detail";
NSString *const ZMConversationInfoIsAllowMemberAddEachOtherKey = @"add_friend";
NSString *const ZMConversationInfoIsVisibleForMemberChangeKey = @"view_chg_mem_notify";

@implementation ZMConversation (Transport)

- (void)updateClearedFromPostPayloadEvent:(ZMUpdateEvent *)event
{
    if (event.timeStamp != nil) {
        [self updateCleared:event.timeStamp synchronize:YES];
    }
}

- (void)updateWithUpdateEvent:(ZMUpdateEvent *)updateEvent
{
    if (updateEvent.timeStamp != nil) {
        [self updateServerModified:updateEvent.timeStamp];
    }
}

- (void)updateWithTransportData:(NSDictionary *)transportData serverTimeStamp:(NSDate *)serverTimeStamp;
{
    NSUUID *remoteId = [transportData uuidForKey:ConversationInfoIDKey];
    RequireString(remoteId == nil || [remoteId isEqual:self.remoteIdentifier],
                  "Remote IDs not matching for conversation: %s vs. %s",
                  remoteId.transportString.UTF8String,
                  self.remoteIdentifier.transportString.UTF8String);
    
    if (transportData[ConversationInfoNameKey] != [NSNull null]) {
        self.userDefinedName = [transportData stringForKey:ConversationInfoNameKey];
    }
    
    self.conversationType = [self conversationTypeFromTransportData:[transportData numberForKey:ConversationInfoTypeKey]];
    /// 允许查看群成员
    self.isAllowViewMembers = [transportData[ZMCOnversationInfoOTRAllowViewMembersKey] boolValue];
    /// 开启url链接加入
    self.isOpenUrlJoin = [transportData[ZMCOnversationInfoOTROpenUrlJoinKey] boolValue];
    /// 群聊邀请确认
    self.isOpenCreatorInviteVerify = [transportData[ZMConversationInfoOTRSelfVerifyKey] boolValue];
    /// 群聊邀请确认
    self.isOpenMemberInviteVerify = [transportData[ZMConversationInfoMemberInviteVerfyKey] boolValue];
    /// 仅限群主拉人
    self.isOnlyCreatorInvite = [transportData[ZMConversationInfoOTRCanAddKey] boolValue];
    /// 会话绑定的社区id
    NSNumber *forumIdNumber = [transportData optionalNumberForKey:@"forumid"];
    if (forumIdNumber != nil) {
        // Backend is sending the miliseconds, we need to convert to seconds.
        self.communityID = [forumIdNumber stringValue];
    }
    // 成员是否可以互相添加好友
    self.isAllowMemberAddEachOther = [transportData[ZMConversationInfoIsAllowMemberAddEachOtherKey] boolValue];
    // 成员变动其他群成员是否可见
    self.isVisibleForMemberChange = [transportData[ZMConversationInfoIsVisibleForMemberChangeKey] boolValue];
    self.isDisableSendMsg = !([[transportData optionalNumberForKey:ZMConversationInfoBlockTimeKey] integerValue] == 0);

    if(transportData[@"assets"] != [NSNull null]) {
        NSArray *imgArr = [transportData arrayForKey:@"assets"];
        for (NSDictionary *dic in imgArr) {
            if ([dic[@"size"] isEqualToString:@"preview"]) {
                self.groupImageSmallKey = dic[@"key"];
            }
            if ([dic[@"size"] isEqualToString:@"complete"]) {
                self.groupImageMediumKey = dic[@"key"];
            }
        }
    }
    
    if (serverTimeStamp != nil) {
        [self updateLastModified:serverTimeStamp];
        [self updateServerModified:serverTimeStamp];
    }
    
    NSDictionary *selfStatus = [[transportData dictionaryForKey:ConversationInfoMembersKey] dictionaryForKey:@"self"];
    if(selfStatus != nil) {
        [self updateSelfStatusFromDictionary:selfStatus timeStamp:nil previousLastServerTimeStamp:nil];
    }
    else {
        ZMLogError(@"Missing self status in conversation data");
    }
    
    NSUUID *creatorId = [transportData uuidForKey:ConversationInfoCreatorKey];
    if(creatorId != nil) {
        self.creator = [ZMUser userWithRemoteID:creatorId createIfNeeded:YES inContext:self.managedObjectContext];
    }
    
    NSDictionary *members = [transportData dictionaryForKey:ConversationInfoMembersKey];
    if(members != nil) {
        [self updateMembersWithPayload:members];
        [self updatePotentialGapSystemMessagesIfNeededWithUsers:self.activeParticipants.set];
    }
    else {
        ZMLogError(@"Invalid members in conversation JSON: %@", transportData);
    }

    NSUUID *teamId = [transportData optionalUuidForKey:ConversationInfoTeamIdKey];
    if (nil != teamId) {
        [self updateTeamWithIdentifier:teamId];
    }
    
    NSArray *apps = [transportData optionalArrayForKey:ConversationInfoAppsKey];
    if (nil != apps) {
        [self updateWithApps:apps];
    }
    NSArray *topApps = [transportData optionalArrayForKey:ZMConversationInfoTopAppsKey];
    if (nil != topApps) {
        [self updateWithTopApps:topApps];
    }
    NSArray *orator = [transportData optionalArrayForKey:ZMConversationInfoOratorKey];
    if (orator && orator.count > 0) {
        [orator enumerateObjectsUsingBlock:^(NSString*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NOT_USED(idx);
            NOT_USED(stop);
            ZMUser *user = [ZMUser userWithRemoteID:[NSUUID uuidWithTransportString:obj] createIfNeeded:YES inContext:self.managedObjectContext];
            user.needsToBeUpdatedFromBackend = YES;
        }];
        self.orator = orator.set;
    }
    NSArray *managers = [transportData optionalArrayForKey:ZMConversationInfoManagerKey];
    if (managers && managers.count > 0) {
        [managers enumerateObjectsUsingBlock:^(NSString*  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            NOT_USED(idx);
            NOT_USED(stop);
            ZMUser *user = [ZMUser userWithRemoteID:[NSUUID uuidWithTransportString:obj] createIfNeeded:YES inContext:self.managedObjectContext];
            user.needsToBeUpdatedFromBackend = YES;
        }];
        self.manager = managers.set;
    }
    
    // 群成员数量
    NSNumber *membersCountNumber = [transportData optionalNumberForKey:@"memsum"];
    self.membersCount = self.conversationType == ZMConversationTypeHugeGroup
    ? membersCountNumber.integerValue
    : (NSInteger)self.activeParticipants.count;
    
    self.accessModeStrings = [transportData optionalArrayForKey:ConversationInfoAccessModeKey];
    self.accessRoleString = [transportData optionalStringForKey:ConversationInfoAccessRoleKey];
    
    NSNumber *messageTimerNumber = [transportData optionalNumberForKey:ConversationInfoMessageTimer];
    
    if (messageTimerNumber != nil) {
        // Backend is sending the miliseconds, we need to convert to seconds.
        self.syncedMessageDestructionTimeout = messageTimerNumber.doubleValue / 1000;
    }
    [UserAliasname createFromTransportData:transportData managedObjectContext:self.managedObjectContext inConversation:self];
    
    [UserDisableSendMsgStatus createFrom:transportData managedObjectContext:self.managedObjectContext inConversation:self.remoteIdentifier.transportString];
}

- (void)updateMembersWithPayload:(NSDictionary *)members
{
    NSArray *usersInfos = [members arrayForKey:ConversationInfoOthersKey];
    NSMutableOrderedSet<ZMUser *> *users = [NSMutableOrderedSet orderedSet];
    NSMutableOrderedSet<ZMUser *> *lastSyncedUsers = [NSMutableOrderedSet orderedSet];
    if (self.mutableLastServerSyncedActiveParticipants != nil) {
        lastSyncedUsers = self.mutableLastServerSyncedActiveParticipants;
    }
    
    for (NSDictionary *userDict in [usersInfos asDictionaries]) {
        
        NSUUID *userId = [userDict uuidForKey:ConversationInfoIDKey];
        if (userId == nil) {
            continue;
        }
        
        [users addObject:[ZMUser userWithRemoteID:userId createIfNeeded:YES inContext:self.managedObjectContext]];
    }
    
    // 获取对方对自己设置的智能推送状态
    if (usersInfos.count == 1){
        NSDictionary *userInfo = (NSDictionary *)usersInfos[0];
        self.autoReplyFromOther = [self autoReplyTypeFromTransportData:[userInfo optionalNumberForKey:ConversationInfoAutoReplyKey]];
    }
    
    NSMutableOrderedSet<ZMUser *> *addedUsers = [users mutableCopy];
    [addedUsers minusOrderedSet:lastSyncedUsers];
    NSMutableOrderedSet<ZMUser *> *removedUsers = [lastSyncedUsers mutableCopy];
    [removedUsers minusOrderedSet:users];
    
    ZMLogDebug(@"updateMembersWithPayload (%@) added = %lu removed = %lu", self.remoteIdentifier.transportString, (unsigned long)addedUsers.count, (unsigned long)removedUsers.count);
    
    [self internalAddParticipants:addedUsers.set];
    [self internalRemoveParticipants:removedUsers.set sender:[ZMUser selfUserInContext:self.managedObjectContext]];
}

- (void)updateTeamWithIdentifier:(NSUUID *)teamId
{
    VerifyReturn(nil != teamId);
    self.teamRemoteIdentifier = teamId;
    self.team = [Team fetchOrCreateTeamWithRemoteIdentifier:teamId createIfNeeded:NO inContext:self.managedObjectContext created:nil];
}

- (void)updatePotentialGapSystemMessagesIfNeededWithUsers:(NSSet <ZMUser *>*)users
{
    ZMSystemMessage *latestSystemMessage = [ZMSystemMessage fetchLatestPotentialGapSystemMessageInConversation:self];
    if (nil == latestSystemMessage) {
        return;
    }
    
    NSMutableSet <ZMUser *>* removedUsers = latestSystemMessage.users.mutableCopy;
    [removedUsers minusSet:users];
    
    NSMutableSet <ZMUser *>* addedUsers = users.mutableCopy;
    [addedUsers minusSet:latestSystemMessage.users];
    
    latestSystemMessage.addedUsers = addedUsers;
    latestSystemMessage.removedUsers = removedUsers;
    [latestSystemMessage updateNeedsUpdatingUsersIfNeeded];
}

/// Pass timestamp when the timestamp equals the time of the lastRead / cleared event, otherwise pass nil
- (void)updateSelfStatusFromDictionary:(NSDictionary *)dictionary timeStamp:(NSDate *)timeStamp previousLastServerTimeStamp:(NSDate *)previousLastServerTimestamp
{
    self.isSelfAnActiveMember = YES;
    
    [self updateMutedStatusWithPayload:dictionary];
    if ([self updateIsArchivedWithPayload:dictionary] && self.isArchived && previousLastServerTimestamp != nil) {
        if (timeStamp != nil && self.clearedTimeStamp != nil && [self.clearedTimeStamp isEqualToDate:previousLastServerTimestamp]) {
            [self updateCleared:timeStamp synchronize:NO];
        }
    }
    self.selfRemark = [dictionary optionalStringForKey:ZMConversationInfoOTRSelfRemarkReferenceKey];
    self.isPlacedTop = [dictionary[ZMConversationInfoPlaceTopKey] boolValue];
}

- (void)updateWithApps:(NSArray *)apps {
    if (apps && apps.count > 0) {
        self.apps = [apps componentsJoinedByString:@","];
    }
}

- (void)updateWithTopApps:(NSArray *)topApps {

    NSMutableOrderedSet<ZMWebApp *> *topWebApps = [NSMutableOrderedSet orderedSet];
    
    for (NSDictionary *appDict in [topApps asDictionaries]) {
        
        NSString *userId = [appDict stringForKey:@"app_id"];
        if (userId == nil) {
            continue;
        }
        [topWebApps addObject:[ZMWebApp createOrUpdateWebApp:appDict context:self.managedObjectContext]];
    }
    self.topWebApps = topWebApps;
}

- (BOOL)updateIsArchivedWithPayload:(NSDictionary *)dictionary
{
    if (dictionary[ZMConversationInfoOTRArchivedReferenceKey] != nil && dictionary[ZMConversationInfoOTRArchivedReferenceKey] != [NSNull null]) {
        NSDate *silencedRef = [dictionary dateForKey:ZMConversationInfoOTRArchivedReferenceKey];
        if (silencedRef != nil && [self updateArchived:silencedRef synchronize:NO]) {
            NSNumber *archived = [dictionary optionalNumberForKey:ZMConversationInfoOTRArchivedValueKey];
            self.internalIsArchived = [archived isEqual:@1];
            return YES;
        }
    }
    return NO;
}

- (ZMAutoReplyType)autoReplyTypeFromTransportData:(NSNumber *)autoReplyType
{
    int const t = [autoReplyType intValue];
    return (ZMAutoReplyType)t;
}

- (ZMConversationType)conversationTypeFromTransportData:(NSNumber *)transportType
{
    return [[self class] conversationTypeFromTransportData:transportType];
}

+ (ZMConversationType)conversationTypeFromTransportData:(NSNumber *)transportType
{
    int const t = [transportType intValue];
    switch (t) {
        case ZMConvTypeGroup:
            return ZMConversationTypeGroup;
        case ZMConvOneToOne:
            return ZMConversationTypeOneOnOne;
        case ZMConvConnection:
            return ZMConversationTypeConnection;
        case ZMConvTypeHugeGroup:
            return ZMConversationTypeHugeGroup;
        default:
            NOT_USED(ZMConvTypeSelf);
            return ZMConversationTypeSelf;
    }
}

- (BOOL)shouldAddEvent:(ZMUpdateEvent *)event
{
    NSDate *timeStamp = event.timeStamp;
    if (self.clearedTimeStamp != nil && timeStamp != nil &&
        [self.clearedTimeStamp compare:timeStamp] != NSOrderedAscending)
    {
        return NO;
    }
    if (self.conversationType == ZMConversationTypeSelf){
        return NO;
    }
    return YES;
}

@end
