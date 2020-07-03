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


@import Foundation;
@import WireImages;
@import WireUtilities;
@import WireTransport;
@import WireCryptobox;
@import MobileCoreServices;
@import WireImages;

#import "ZMManagedObject+Internal.h"
#import "ZMConversation+Internal.h"
#import "ZMConversation+UnreadCount.h"

#import "ZMUser+Internal.h"

#import "ZMMessage+Internal.h"

#import "NSManagedObjectContext+zmessaging.h"
#import "ZMConnection+Internal.h"

#import "ZMConversationList+Internal.h"

#import "ZMConversationListDirectory.h"
#import <WireDataModel/WireDataModel-Swift.h>
#import "NSPredicate+ZMSearch.h"

static NSString* ZMLogTag ZM_UNUSED = @"Conversations";

NSString *const ZMConversationConnectionKey = @"connection";
NSString *const ZMConversationHasUnreadMissedCallKey = @"hasUnreadMissedCall";
NSString *const ZMConversationHasUnreadUnsentMessageKey = @"hasUnreadUnsentMessage";
NSString *const ZMConversationIsArchivedKey = @"internalIsArchived";
NSString *const ZMConversationIsSelfAnActiveMemberKey = @"isSelfAnActiveMember";
NSString *const ZMConversationMutedStatusKey = @"mutedStatus";
NSString *const ZMConversationAllMessagesKey = @"allMessages";
NSString *const ZMConversationHiddenMessagesKey = @"hiddenMessages";
NSString *const ZMConversationMembersAliasnameKey = @"membersAliasname";
NSString *const ZMConversationMembersSendMsgStatusesKey = @"membersSendMsgStatuses";
NSString *const ZMConversationLastServerSyncedActiveParticipantsKey = @"lastServerSyncedActiveParticipants";
NSString *const ZMConversationParticipantRolesKey = @"participantRoles";
NSString *const ZMConversationNonTeamRolesKey = @"nonTeamRoles";
NSString *const ZMConversationHasUnreadKnock = @"hasUnreadKnock";
NSString *const ZMConversationUserDefinedNameKey = @"userDefinedName";
NSString *const ZMIsDimmedKey = @"zmIsDimmed";
NSString *const ZMNormalizedUserDefinedNameKey = @"normalizedUserDefinedName";
NSString *const ZMConversationListIndicatorKey = @"conversationListIndicator";
NSString *const ZMConversationConversationTypeKey = @"conversationType";
NSString *const ZMConversationLastServerTimeStampKey = @"lastServerTimeStamp";
NSString *const ZMConversationLastReadServerTimeStampKey = @"lastReadServerTimeStamp";
NSString *const ZMConversationClearedTimeStampKey = @"clearedTimeStamp";
NSString *const ZMConversationArchivedChangedTimeStampKey = @"archivedChangedTimestamp";
NSString *const ZMConversationSilencedChangedTimeStampKey = @"silencedChangedTimestamp";
NSString *const ZMConversationExternalParticipantsStateKey = @"externalParticipantsState";
NSString *const ZMConversationNeedsToDownloadRolesKey = @"needsToDownloadRoles";
NSString *const ZMConversationLegalHoldStatusKey = @"legalHoldStatus";
NSString *const ZMConversationNeedsToVerifyLegalHoldKey = @"needsToVerifyLegalHold";
NSString *const ZMNotificationConversationKey = @"ZMNotificationConversationKey";
NSString *const ZMConversationEstimatedUnreadCountKey = @"estimatedUnreadCount";
NSString *const ZMConversationRemoteIdentifierDataKey = @"remoteIdentifier_data";
NSString *const SecurityLevelKey = @"securityLevel";
NSString *const ZMConversationLabelsKey = @"labels";

static NSString *const ConnectedUserKey = @"connectedUser";
NSString *const CreatorKey = @"creator";
static NSString *const DraftMessageDataKey = @"draftMessageData";
static NSString *const IsPendingConnectionConversationKey = @"isPendingConnectionConversation";
static NSString *const LastModifiedDateKey = @"lastModifiedDate";
static NSString *const DisableSendLastModifiedDateKey = @"disableSendLastModifiedDate";
static NSString *const LastReadMessageKey = @"lastReadMessage";
static NSString *const lastEditableMessageKey = @"lastEditableMessage";
static NSString *const NeedsToBeUpdatedFromBackendKey = @"needsToBeUpdatedFromBackend";
static NSString *const RemoteIdentifierKey = @"remoteIdentifier";
static NSString *const TeamRemoteIdentifierKey = @"teamRemoteIdentifier";
NSString *const TeamRemoteIdentifierDataKey = @"teamRemoteIdentifier_data";
static NSString *const VoiceChannelKey = @"voiceChannel";
static NSString *const VoiceChannelStateKey = @"voiceChannelState";

static NSString *const LocalMessageDestructionTimeoutKey = @"localMessageDestructionTimeout";
static NSString *const SyncedMessageDestructionTimeoutKey = @"syncedMessageDestructionTimeout";
static NSString *const HasReadReceiptsEnabledKey = @"hasReadReceiptsEnabled";

static NSString *const LanguageKey = @"language";

static NSString *const DownloadedMessageIDsDataKey = @"downloadedMessageIDs_data";
static NSString *const LastEventIDDataKey = @"lastEventID_data";
static NSString *const ClearedEventIDDataKey = @"clearedEventID_data";
static NSString *const ArchivedEventIDDataKey = @"archivedEventID_data";
static NSString *const LastReadEventIDDataKey = @"lastReadEventID_data";

static NSString *const TeamKey = @"team";

static NSString *const AccessModeStringsKey = @"accessModeStrings";
static NSString *const AccessRoleStringKey = @"accessRoleString";

NSTimeInterval ZMConversationDefaultLastReadTimestampSaveDelay = 3.0;

const NSUInteger ZMConversationMaxEncodedTextMessageLength = 1500;
const NSUInteger ZMConversationMaxTextMessageLength = ZMConversationMaxEncodedTextMessageLength - 50; // Empirically we verified that the encoding adds 44 bytes

/*----------------------------------*/
///conversation新增，这里的key主要用于ZMConversationTranscoder中用来监听属性改变，发起请求

NSString *const ZMConversationAutoReplyKey = @"autoReply";
NSString *const ZMConversationAutoReplyFromOtherKey = @"autoReplyFromOther";

NSString *const ZMConversationSelfRemarkKey = @"selfRemark";
NSString *const ZMConversationIsOpenCreatorInviteVerifyKey = @"isOpenCreatorInviteVerify";
NSString *const ZMConversationIsOpenMemberInviteVerifyKey = @"isOpenMemberInviteVerify";
NSString *const ZMConversationOnlyCreatorInviteKey = @"isOnlyCreatorInvite";
NSString *const ZMConversationOpenUrlJoinKey = @"isOpenUrlJoin";
NSString *const ZMConversationAllowViewMembersKey = @"isAllowViewMembers";

NSString *const ZMConversationPreviewAvatarKey = @"groupImageSmallKey";
NSString *const ZMConversationCompleteAvatarKey = @"groupImageMediumKey";

NSString *const ZMConversationAppsKey = @"apps";
NSString *const ZMConversationTopWebAppsKey = @"topWebApps";

NSString *const ZMConversationIsPlacedTopKey = @"isPlacedTop";
NSString *const ZMConversationIsAllowMemberAddEachOtherKey = @"isAllowMemberAddEachOther";
NSString *const ZMConversationIsVisibleForMemberChangeKey = @"isVisibleForMemberChange";
NSString *const ZMConversationIsDisableSendMsgKey = @"isDisableSendMsg";
NSString *const ZMConversationManagerAddKey = @"managerAdd";
NSString *const ZMConversationManagerDelKey = @"managerDel";
NSString *const ZMConversationIsVisitorsVisibleKey = @"isVisitorsVisible";
NSString *const ZMConversationIsMessageVisibleOnlyManagerAndCreatorKey = @"isMessageVisibleOnlyManagerAndCreator";
NSString *const ZMConversationAnnouncementKey = @"announcement";
NSString *const ShowMemsumKey = @"showMemsum";
NSString *const EnabledEditMsgKey = @"enabledEditMsg";

/*----------------------------------*/

//transport

// 新增--此处定义的key主要是用来解析服务端返回的字段，以及发送请求时传入的字段
static NSString *const ConversationInfoAutoReplyKey = @"auto_reply";

NSString *const ZMConversationInfoPlaceTopKey = @"place_top";
NSString *const ZMConversationInfoOTRSelfRemarkBoolKey = @"alias_name";
NSString *const ZMConversationInfoOTRSelfRemarkReferenceKey = @"alias_name_ref";
NSString *const ZMConversationInfoOTRSelfVerifyKey = @"confirm";
NSString *const ZMConversationInfoMemberInviteVerfyKey = @"memberjoin_confirm";
NSString *const ZMConversationInfoOTRCreatorChangeKey = @"new_creator";
NSString *const ZMConversationInfoBlockTimeKey = @"block_time";
NSString *const ZMConversationInfoBlockDurationKey = @"block_duration";
NSString *const ZMConversationInfoOpt_idKey = @"opt_id";
NSString *const ZMConversationInfoBlockUserKey = @"block_user";
NSString *const ZMConversationInfoOratorKey = @"orator";
NSString *const ZMConversationInfoManagerKey = @"manager";
NSString *const ZMConversationInfoManagerAddKey = @"man_add";
NSString *const ZMConversationInfoManagerDelKey = @"man_del";
NSString *const ZMConversationInfoOTRCanAddKey = @"addright";
NSString *const ZMCOnversationInfoOTROpenUrlJoinKey = @"url_invite";
NSString *const ZMCOnversationInfoOTRAllowViewMembersKey = @"viewmem";
NSString *const ZMConversationInfoAppsKey = @"apps";
NSString *const ZMConversationInfoTopAppsKey = @"top_apps";
NSString *const ZMConversationInfoTopWebAppsKey = @"top_apps_detail";
NSString *const ZMConversationInfoIsAllowMemberAddEachOtherKey = @"add_friend";
NSString *const ZMConversationInfoIsVisibleForMemberChangeKey = @"view_chg_mem_notify";
NSString *const ZMConversationInfoIsVisitorsVisibleKey = @"show_invitor_list";
NSString *const ZMConversationInfoIsMessageVisibleOnlyManagerAndCreatorKey = @"msg_only_to_manager";
NSString *const ZMConversationInfoAnnouncementKey = @"advisory";
NSString *const ZMConversationBlockedKey = @"blocked";
NSString *const ZMConversationShowMemsumKey = @"show_memsum";
NSString *const ZMConversationEnabledEditMsgKey = @"enabled_edit_msg";
NSString *const ZMConversationAssistantBotKey = @"assistant_bot";
NSString *const ZMConversationAssistantBotOptKey = @"assistant_bot_opt";

@interface ZMConversation ()

@property (nonatomic) NSString *normalizedUserDefinedName;
@property (nonatomic) ZMConversationType conversationType;

@property (nonatomic) NSTimeInterval lastReadTimestampSaveDelay;
@property (nonatomic) int64_t lastReadTimestampUpdateCounter;
@property (nonatomic) BOOL internalIsArchived;

@property (nonatomic) NSDate *pendingLastReadServerTimestamp;
@property (nonatomic) NSDate *lastReadServerTimeStamp;
@property (nonatomic) NSDate *lastServerTimeStamp;
@property (nonatomic) NSDate *clearedTimeStamp;
@property (nonatomic) NSDate *archivedChangedTimestamp;
@property (nonatomic) NSDate *silencedChangedTimestamp;

@property (nonatomic) NSDate *previewAvatarData;
@property (nonatomic) NSDate *completeAvatarData;
@end

/// Declaration of properties implemented (automatically) by Core Data
@interface ZMConversation (CoreDataForward)

@property (nonatomic) NSDate *primitiveLastReadServerTimeStamp;
@property (nonatomic) NSDate *primitiveLastServerTimeStamp;
@property (nonatomic) NSUUID *primitiveRemoteIdentifier;
@property (nonatomic) NSNumber *primitiveConversationType;
@property (nonatomic) NSData *remoteIdentifier_data;

@property (nonatomic) ZMConversationSecurityLevel securityLevel;
@end


@implementation ZMConversation

@dynamic userDefinedName;
@dynamic allMessages;
@dynamic lastModifiedDate;
@dynamic disableSendLastModifiedDate;
@dynamic creator;
@dynamic lastServiceMessage;
@dynamic normalizedUserDefinedName;
@dynamic conversationType;
@dynamic clearedTimeStamp;
@dynamic lastServiceMessageTimeStamp;
@dynamic lastReadServerTimeStamp;
@dynamic lastServerTimeStamp;
@dynamic internalIsArchived;
@dynamic archivedChangedTimestamp;
@dynamic silencedChangedTimestamp;
@dynamic team;
@dynamic labels;
// 新增

@dynamic messagesNonceSet;
@dynamic lastVisibleMessage;
@dynamic selfRemark;

@dynamic autoReply;
@dynamic autoReplyFromOther;

@dynamic isOpenUrlJoin;
@dynamic isOpenCreatorInviteVerify;
@dynamic isOpenMemberInviteVerify;
@dynamic isOnlyCreatorInvite;
@dynamic isAllowViewMembers;

@dynamic joinGroupUrl;
@dynamic appletsIcon;

@dynamic groupImageMediumKey;
@dynamic groupImageSmallKey;
@synthesize previewAvatarData;
@synthesize completeAvatarData;

@dynamic apps;
@dynamic topApps;
@dynamic topWebApps;
@dynamic communityID;
    
@dynamic isPlacedTop;
@dynamic isReadAnnouncement;

@dynamic orator;
@dynamic manager;
@dynamic managerAdd;
@dynamic managerDel;
@dynamic isServiceNotice;
@dynamic isVisitorsVisible;
@dynamic isMessageVisibleOnlyManagerAndCreator;
@dynamic announcement;

@dynamic membersAliasname;
@dynamic membersSendMsgStatuses;
@dynamic membersCount;
@dynamic isAllowMemberAddEachOther;
@dynamic isVisibleForMemberChange;
@dynamic isDisableSendMsg;
@dynamic blocked;
@dynamic blockWarningMessage;
@dynamic blockWarningMessageTimeStamp;
@dynamic showMemsum;
@dynamic enabledEditMsg;
@dynamic fifth_name;
@dynamic fifth_image;
@dynamic assistantBot;

@dynamic participantRoles;
@dynamic nonTeamRoles;

@synthesize pendingLastReadServerTimestamp;
@synthesize lastReadTimestampSaveDelay;
@synthesize lastReadTimestampUpdateCounter;
@synthesize creatorChangeTimestamp;


- (BOOL)isArchived
{
    return self.internalIsArchived;
}

- (void)setIsArchived:(BOOL)isArchived
{
    self.internalIsArchived = isArchived;
    
    if (self.lastServerTimeStamp != nil) {
        [self updateArchived:self.lastServerTimeStamp synchronize:YES];
    }
}

- (NSUInteger)estimatedUnreadCount
{
    return (unsigned long)self.internalEstimatedUnreadCount;
}

- (NSUInteger)estimatedUnreadSelfMentionCount
{
    return (unsigned long)self.internalEstimatedUnreadSelfMentionCount;
}

- (NSUInteger)estimatedUnreadSelfReplyCount
{
    return (unsigned long)self.internalEstimatedUnreadSelfReplyCount;
}

- (NSOrderedSet *)messagesFilterService {
    return [self.messages filteredOrderedSetUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id  _Nullable evaluatedObject, id ZM_UNUSED bindings) {
        if ([evaluatedObject isKindOfClass:[ZMSystemMessage class]] && ((ZMSystemMessage *)evaluatedObject).isService) {
            return NO;
        }
        return YES;
    }]];
}

+ (NSSet *)keyPathsForValuesAffectingEstimatedUnreadCount
{
    return [NSSet setWithObjects: ZMConversationInternalEstimatedUnreadCountKey, ZMConversationLastReadServerTimeStampKey, nil];
}

+ (NSFetchRequest *)sortedFetchRequest
{
    NSFetchRequest *request = [super sortedFetchRequest];

    if(request.predicate) {
        request.predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[request.predicate]];
    }
    else {
        request.predicate = self.predicateForFilteringResults;
    }
    return request;
}

+ (NSPredicate *)predicateForObjectsThatNeedToBeInsertedUpstream;
{
    NSPredicate *superPredicate = [super predicateForObjectsThatNeedToBeInsertedUpstream];
    NSPredicate *onlyGoupPredicate = [NSPredicate predicateWithFormat:@"(%K == %@) OR (%K == %@)",
                                      ZMConversationConversationTypeKey, @(ZMConversationTypeGroup),
                                      ZMConversationConversationTypeKey, @(ZMConversationTypeHugeGroup)];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[superPredicate, onlyGoupPredicate]];
}

+ (NSPredicate *)predicateForObjectsThatNeedToBeUpdatedUpstream;
{
    NSPredicate *superPredicate = [super predicateForObjectsThatNeedToBeUpdatedUpstream];
    NSPredicate *onlyGoupPredicate = [NSPredicate predicateWithFormat:@"(%K != NULL) AND (%K != %@) AND (%K == 0)",
                                      [self remoteIdentifierDataKey],
                                      ZMConversationConversationTypeKey, @(ZMConversationTypeInvalid),
                                      NeedsToBeUpdatedFromBackendKey];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[superPredicate, onlyGoupPredicate]];
}

- (void)awakeFromFetch;
{
    [super awakeFromFetch];
    self.lastReadTimestampSaveDelay = ZMConversationDefaultLastReadTimestampSaveDelay;
//    if (self.managedObjectContext.zm_isSyncContext) {
//        // From the documentation: The managed object context’s change processing is explicitly disabled around this method so that you can use public setters to establish transient values and other caches without dirtying the object or its context.
//        // Therefore we need to do a dispatch async  here in a performGroupedBlock to update the unread properties outside of awakeFromFetch
//        ZM_WEAK(self);
//        [self.managedObjectContext performGroupedBlock:^{
//            ZM_STRONG(self);
//            [self calculateLastUnreadMessages];
//        }];
//    }
}

- (void)awakeFromInsert;
{
    [super awakeFromInsert];
    self.lastReadTimestampSaveDelay = ZMConversationDefaultLastReadTimestampSaveDelay;
    if (self.managedObjectContext.zm_isSyncContext) {
        // From the documentation: You are typically discouraged from performing fetches within an implementation of awakeFromInsert. Although it is allowed, execution of the fetch request can trigger the sending of internal Core Data notifications which may have unwanted side-effects. Since we fetch the unread messages here, we should do a dispatch async
        [self.managedObjectContext performGroupedBlock:^{
            [self calculateLastUnreadMessages];
        }];
    }
}


///activeParticipants的计算过程占用cpu比较多，这里还是之前的逻辑，但是换种写法，来降低cpu计算量。
-(NSSet <ZMUser *> *)activeParticipants
{
    
    NSMutableSet *activeParticipants = [NSMutableSet set];
    
    if (self.internalConversationType != ZMConversationTypeGroup &&
        self.internalConversationType != ZMConversationTypeHugeGroup) {
        [activeParticipants addObject:[ZMUser selfUserInContext:self.managedObjectContext]];
        if (self.connectedUser != nil) {
            [activeParticipants addObject:self.connectedUser];
        }
    }
    else if(self.isSelfAnActiveMember &&
            ![self.lastServerSyncedActiveParticipants containsObject:[ZMUser selfUserInContext:self.managedObjectContext]]) {
        activeParticipants = [[NSMutableSet alloc] initWithSet:[self.lastServerSyncedActiveParticipants set]];
        [activeParticipants addObject:[ZMUser selfUserInContext:self.managedObjectContext]];
    }
    else
    {
        return [self.lastServerSyncedActiveParticipants set];
    }
    return activeParticipants;
}


-(NSArray <ZMUser *> *)sortedActiveParticipants
{
    return [self sortedUsers:[self localParticipants]];
}

- (NSArray *)sortedUsers:(NSSet *)users
{
    NSSortDescriptor *nameDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"normalizedName" ascending:YES];
    NSArray *sortedUser = [users sortedArrayUsingDescriptors:@[nameDescriptor]];
    
    return sortedUser;
}

- (ZMUser *)connectedUser
{
    ZMConversationType internalConversationType = self.internalConversationType;
    
    if (internalConversationType == ZMConversationTypeOneOnOne || internalConversationType == ZMConversationTypeConnection) {
        return self.connection.to;
    } else if (self.conversationType == ZMConversationTypeOneOnOne && self.lastServerSyncedActiveParticipants.count > 0) {
        return self.localParticipantsExcludingSelf.anyObject;
    }
    
    return nil;
}

+ (NSSet *)keyPathsForValuesAffectingConnectedUser
{
    return [NSSet setWithObject:ZMConversationConversationTypeKey];
}


- (ZMConnectionStatus)relatedConnectionState
{
    if(self.connection != nil) {
        return self.connection.status;
    }
    return ZMConnectionStatusInvalid;
}

+ (NSSet *)keyPathsForValuesAffectingRelatedConnectionState
{
    return [NSSet setWithObject:@"connection.status"];
}

- (NSSet *)ignoredKeys;
{
    static NSSet *ignoredKeys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSSet *keys = [super ignoredKeys];
        NSString * const KeysIgnoredForTrackingModifications[] = {
            ZMConversationConnectionKey,
            ZMConversationConversationTypeKey,
            DraftMessageDataKey,
            LastModifiedDateKey,
            DisableSendLastModifiedDateKey,
            ZMNormalizedUserDefinedNameKey,
            ZMConversationParticipantRolesKey,
            ZMConversationNonTeamRolesKey,
            VoiceChannelKey,
            ZMConversationHasUnreadMissedCallKey,
            ZMConversationHasUnreadUnsentMessageKey,
            ZMConversationAllMessagesKey,
            ZMConversationHiddenMessagesKey,
            ZMConversationMembersAliasnameKey,
            ZMConversationMembersSendMsgStatusesKey,
            ZMConversationLastServerTimeStampKey,
            SecurityLevelKey,
            ZMConversationLastUnreadKnockDateKey,
            ZMConversationLastUnreadMissedCallDateKey,
            ZMConversationLastReadLocalTimestampKey,
            ZMConversationInternalEstimatedUnreadCountKey,
            ZMConversationInternalEstimatedUnreadSelfMentionCountKey,
            ZMConversationInternalEstimatedUnreadSelfReplyCountKey,
            ZMConversationIsArchivedKey,
            ZMConversationMutedStatusKey,
            LocalMessageDestructionTimeoutKey,
            SyncedMessageDestructionTimeoutKey,
            DownloadedMessageIDsDataKey,
            LastEventIDDataKey,
            ClearedEventIDDataKey,
            ArchivedEventIDDataKey,
            LastReadEventIDDataKey,
            TeamKey,
            TeamRemoteIdentifierKey,
            TeamRemoteIdentifierDataKey,
            AccessModeStringsKey,
            AccessRoleStringKey,
            LanguageKey,
            //、 新增
            ZMConversationAutoReplyFromOtherKey,
            ZMConversationAppsKey,
            @"isServiceNotice",
            HasReadReceiptsEnabledKey,
            ZMConversationLegalHoldStatusKey,
            ZMConversationNeedsToVerifyLegalHoldKey,
            ZMConversationLabelsKey,
            ZMConversationNeedsToDownloadRolesKey,
            @"isSelfAnActiveMember", // DEPRECATED
            @"lastServerSyncedActiveParticipants" // DEPRECATED
        };
        
        NSSet *additionalKeys = [NSSet setWithObjects:KeysIgnoredForTrackingModifications count:(sizeof(KeysIgnoredForTrackingModifications) / sizeof(*KeysIgnoredForTrackingModifications))];
        ignoredKeys = [keys setByAddingObjectsFromSet:additionalKeys];
    });
    return ignoredKeys;
}

- (BOOL)isReadOnly
{
    return
    (self.conversationType == ZMConversationTypeInvalid) ||
    (self.conversationType == ZMConversationTypeSelf) ||
    (self.conversationType == ZMConversationTypeConnection) ||
    (self.conversationType == ZMConversationTypeGroup && !self.isSelfAnActiveMember) ||
    (self.conversationType == ZMConversationTypeHugeGroup && !self.isSelfAnActiveMember);
}

+ (NSSet *)keyPathsForValuesAffectingIsReadOnly;
{
    return [NSSet setWithObjects:ZMConversationConversationTypeKey, ZMConversationIsSelfAnActiveMemberKey, ZMConversationParticipantRolesKey, nil];
}

+ (NSSet *)keyPathsForValuesAffectingDisplayName;
{
    return [NSSet setWithObjects:ZMConversationConversationTypeKey, ZMConversationLastServerSyncedActiveParticipantsKey, @"lastServerSyncedActiveParticipants.name", @"connection.to.name", @"connection.to.availability", ZMConversationUserDefinedNameKey, nil];
}

+ (nonnull instancetype)insertGroupConversationIntoUserSession:(nonnull id<ZMManagedObjectContextProvider> )session
                                              withParticipants:(nonnull NSArray<ZMUser *> *)participants
                                                        inTeam:(nullable Team *)team;
{

    return [self insertGroupConversationIntoUserSession:session withParticipants:participants name:nil inTeam:team];
}

+ (nonnull instancetype)insertGroupConversationIntoUserSession:(nonnull id<ZMManagedObjectContextProvider> )session
                                              withParticipants:(nonnull NSArray<ZMUser *> *)participants
                                                          name:(nullable NSString*)name
                                                        inTeam:(nullable Team *)team
{
    return [self insertGroupConversationIntoUserSession:session
                                       withParticipants:participants
                                                   name:name
                                                 inTeam:team
                                            allowGuests:YES];
}

+ (nonnull instancetype)insertGroupConversationIntoUserSession:(nonnull id<ZMManagedObjectContextProvider> )session
                                              withParticipants:(nonnull NSArray<ZMUser *> *)participants
                                                          name:(nullable NSString*)name
                                                        inTeam:(nullable Team *)team
                                                   allowGuests:(BOOL)allowGuests
{
    return [self insertGroupConversationIntoUserSession:session
                                       withParticipants:participants
                                                   name:name
                                                 inTeam:team
                                            allowGuests:allowGuests
                                                topapps:nil];
}

+ (nonnull instancetype)insertGroupConversationIntoUserSession:(nonnull id<ZMManagedObjectContextProvider> )session
                                              withParticipants:(nonnull NSArray<ZMUser *> *)participants
                                                          name:(nullable NSString*)name
                                                        inTeam:(nullable Team *)team
                                                   allowGuests:(BOOL)allowGuests
                                                       topapps:(NSArray *)topapps
{
    VerifyReturnNil(session != nil);
    return [self insertGroupConversationIntoManagedObjectContext:session.managedObjectContext
                                                withParticipants:participants
                                                            name:name
                                                          inTeam:team
                                                     allowGuests:allowGuests
                                                         topapps:topapps];
}

+ (nonnull instancetype)insertHugeGroupConversationIntoUserSession:(nonnull id<ZMManagedObjectContextProvider> )session
                                                  withParticipants:(nonnull NSArray<ZMUser *> *)participants
                                                              name:(nullable NSString*)name
                                                            inTeam:(nullable Team *)team
                                                       allowGuests:(BOOL)allowGuests
{
    VerifyReturnNil(session != nil);
    return [self insertHugeGroupConversationIntoManagedObjectContext:session.managedObjectContext
                                                    withParticipants:participants
                                                                name:name
                                                              inTeam:team
                                                         allowGuests:allowGuests];
}

+ (instancetype)existingOneOnOneConversationWithUser:(ZMUser *)otherUser inUserSession:(id<ZMManagedObjectContextProvider>)session;
{
    NOT_USED(session);
    return otherUser.connection.conversation;
}

- (void)setClearedTimeStamp:(NSDate *)clearedTimeStamp
{
    [self willChangeValueForKey:ZMConversationClearedTimeStampKey];
    [self setPrimitiveValue:clearedTimeStamp forKey:ZMConversationClearedTimeStampKey];
    [self didChangeValueForKey:ZMConversationClearedTimeStampKey];
    if (self.managedObjectContext.zm_isSyncContext) {
        [self deleteOlderMessages];
    }
}

- (void)setLastReadServerTimeStamp:(NSDate *)lastReadServerTimeStamp
{
    [self willChangeValueForKey:ZMConversationLastReadServerTimeStampKey];
    [self setPrimitiveValue:lastReadServerTimeStamp forKey:ZMConversationLastReadServerTimeStampKey];
    [self didChangeValueForKey:ZMConversationLastReadServerTimeStampKey];
    
    if (self.managedObjectContext.zm_isSyncContext) {
        [self calculateLastUnreadMessages];
    }
}

- (NSUUID *)remoteIdentifier;
{
    return [self transientUUIDForKey:RemoteIdentifierKey];
}

- (void)setRemoteIdentifier:(NSUUID *)remoteIdentifier;
{
    [self setTransientUUID:remoteIdentifier forKey:RemoteIdentifierKey];
}

- (NSUUID *)teamRemoteIdentifier;
{
    return [self transientUUIDForKey:TeamRemoteIdentifierKey];
}

- (void)setTeamRemoteIdentifier:(NSUUID *)teamRemoteIdentifier;
{
    [self setTransientUUID:teamRemoteIdentifier forKey:TeamRemoteIdentifierKey];
}


+ (NSSet *)keyPathsForValuesAffectingRemoteIdentifier
{
    return [NSSet setWithObject:ZMConversationRemoteIdentifierDataKey];
}

- (void)setUserDefinedName:(NSString *)aName {
    
    [self willChangeValueForKey:ZMConversationUserDefinedNameKey];
    [self setPrimitiveValue:[[aName copy] stringByRemovingExtremeCombiningCharacters] forKey:ZMConversationUserDefinedNameKey];
    [self didChangeValueForKey:ZMConversationUserDefinedNameKey];
    
    self.normalizedUserDefinedName = [self.userDefinedName normalizedString];
}

//增加conversationType的set方法，当conversationType被设置成了万人群，那么在界面上取消阅后即焚的按钮
//这里需要改变localMessageDestructionTimeout和syncedMessageDestructionTimeout除了能通知到页面，还因为页面上的阅后即焚由这些参数共同决定，所以需要置为0
- (void)setConversationType:(ZMConversationType)aType {
    [self willChangeValueForKey:ZMConversationConversationTypeKey];
    [self setPrimitiveValue:@(aType) forKey:ZMConversationConversationTypeKey];
    [self didChangeValueForKey:ZMConversationConversationTypeKey];
    if (aType == ZMConversationTypeHugeGroup) {
        if (self.localMessageDestructionTimeout > 0) {
            self.localMessageDestructionTimeout = 0;
        }
        if (self.syncedMessageDestructionTimeout > 0) {
            self.syncedMessageDestructionTimeout = 0;
        }
    }
}

- (ZMConversationType)conversationType
{
    ZMConversationType conversationType = [self internalConversationType];
    
    // Exception: the group conversation is considered a 1-1 if:
    // 1. Belongs to the team.
    // 2. Has no name given.
    // 3. Conversation has only one other participant.
    // 4. This participant is not a service user (bot).
    if ((conversationType == ZMConversationTypeGroup ||
         conversationType == ZMConversationTypeHugeGroup) &&
        self.teamRemoteIdentifier != nil &&
        self.localParticipantsExcludingSelf.count == 1 &&
        !self.localParticipantsExcludingSelf.anyObject.isServiceUser &&
        self.userDefinedName.length == 0) {
        conversationType = ZMConversationTypeOneOnOne;
    }
    
    return conversationType;
}

- (BOOL)isSelfConversation {
    return self.conversationType == ZMConversationTypeSelf;
}

+ (NSArray *)defaultSortDescriptors
{
    return @[[NSSortDescriptor sortDescriptorWithKey:ZMConversationIsPlacedTopKey ascending:NO],
             [NSSortDescriptor sortDescriptorWithKey:LastModifiedDateKey ascending:NO],
             [NSSortDescriptor sortDescriptorWithKey:ZMConversationRemoteIdentifierDataKey ascending:YES],];
}

- (BOOL)isPendingConnectionConversation;
{
    return self.connection != nil && self.connection.status == ZMConnectionStatusPending;
}

+ (NSSet *)keyPathsForValuesAffectingIsPendingConnectionConversation
{
    return [NSSet setWithObjects:ZMConversationConnectionKey, @"connection.status", nil];
}

- (ZMConversationListIndicator)conversationListIndicator;
{
    if (self.connectedUser.isPendingApprovalByOtherUser) {
        return ZMConversationListIndicatorPending;
    }
    else if (self.isCallDeviceActive) {
        return ZMConversationListIndicatorActiveCall;
    }
    else if (self.isIgnoringCall) {
        return ZMConversationListIndicatorInactiveCall;        
    }
    
    return [self unreadListIndicator];
}

+ (NSSet *)keyPathsForValuesAffectingConversationListIndicator
{
    return [[ZMConversation keyPathsForValuesAffectingUnreadListIndicator] union:[NSSet setWithObject: @"voiceChannelState"]];
}


- (BOOL)hasDraftMessage
{
    return (0 < self.draftMessage.text.length);
}

+ (NSSet *)keyPathsForValuesAffectingHasDraftMessage
{
    return [NSSet setWithObject:DraftMessageDataKey];
}

- (ZMMessage *)lastEditableMessage;
{
    __block ZMMessage *result;
    [[self lastMessagesWithLimit:50] enumerateObjectsUsingBlock:^(ZMMessage * _Nonnull message, NSUInteger idx, BOOL * _Nonnull stop) {
        NOT_USED(idx);
        if ([message isEditableMessage]) {
            result = message;
            *stop = YES;
        }
    }];
    return result;
}

+ (NSSet *)keyPathsForValuesAffectingFirstUnreadMessage
{
    return [NSSet setWithObjects:ZMConversationAllMessagesKey, ZMConversationLastReadServerTimeStampKey, nil];
}

- (NSSet<NSString *> *)filterUpdatedLocallyModifiedKeys:(NSSet<NSString *> *)updatedKeys
{
    NSMutableSet *newKeys = [super filterUpdatedLocallyModifiedKeys:updatedKeys].mutableCopy;
    
    // Don't sync the conversation name if it was set before inserting the conversation
    // as it will already get synced when inserting the conversation on the backend.
    if (self.isInserted && nil != self.userDefinedName && [newKeys containsObject:ZMConversationUserDefinedNameKey]) {
        [newKeys removeObject:ZMConversationUserDefinedNameKey];
    }
    
    return newKeys;
}

- (BOOL)canMarkAsUnread
{
    if (self.estimatedUnreadCount > 0) {
        return NO;
    }
    
    if (nil == [self lastMessageCanBeMarkedUnread]) {
        return NO;
    }
    
    return YES;
}

- (ZMMessage *)lastMessageCanBeMarkedUnread
{
    for (ZMMessage *message in [self lastMessagesWithLimit:50]) {
        if (message.canBeMarkedUnread) {
            return message;
        }
    }
    
    return nil;
}

- (void)markAsUnread
{
    ZMMessage *lastMessageCanBeMarkedUnread = [self lastMessageCanBeMarkedUnread];
    
    if (lastMessageCanBeMarkedUnread == nil) {
        ZMLogError(@"Cannot mark as read: no message to mark in %@", self);
        return;
    }
    
    [lastMessageCanBeMarkedUnread markAsUnread];
}

- (void)deleteConversation {
    ZMConversation *existingConversation = [ZMConversation conversationWithRemoteID:self.remoteIdentifier createIfNeeded:NO inContext:self.managedObjectContext];
    [self.managedObjectContext deleteObject:existingConversation];
    [self.managedObjectContext saveOrRollback];
}

@end



@implementation ZMConversation (Internal)

@dynamic connection;
@dynamic creator;
@dynamic lastModifiedDate;
@dynamic normalizedUserDefinedName;
@dynamic hiddenMessages;

+ (NSSet *)keyPathsForValuesAffectingIsArchived
{
    return [NSSet setWithObject:ZMConversationIsArchivedKey];
}

+ (NSString *)entityName;
{
    return @"Conversation";
}

- (NSMutableSet<ZMMessage *> *)mutableMessages;
{
    return [self mutableSetValueForKey:ZMConversationAllMessagesKey];
}

+ (ZMConversationList *)conversationsIncludingArchivedInContext:(NSManagedObjectContext *)moc;
{
    return moc.conversationListDirectory.conversationsIncludingArchived;
}

+ (ZMConversationList *)archivedConversationsInContext:(NSManagedObjectContext *)moc;
{
    return moc.conversationListDirectory.archivedConversations;
}

+ (ZMConversationList *)clearedConversationsInContext:(NSManagedObjectContext *)moc;
{
    return moc.conversationListDirectory.clearedConversations;
}

+ (ZMConversationList *)conversationsExcludingArchivedInContext:(NSManagedObjectContext *)moc;
{
    return moc.conversationListDirectory.unarchivedConversations;
}

+ (ZMConversationList *)pendingConversationsInContext:(NSManagedObjectContext *)moc;
{
    return moc.conversationListDirectory.pendingConnectionConversations;
}

+ (ZMConversationList *)hugeGroupConversationsInContext:(NSManagedObjectContext *)moc
{
    return moc.conversationListDirectory.hugeGroupConversations;
}



- (ZMConversationType)internalConversationType
{
    [self willAccessValueForKey:ZMConversationConversationTypeKey];
    ZMConversationType conversationType =  (ZMConversationType)[[self primitiveConversationType] shortValue];
    [self didAccessValueForKey:ZMConversationConversationTypeKey];
    return conversationType;
}


- (void)mergeWithExistingConversationWithRemoteID:(NSUUID *)remoteID;
{
    ZMConversation *existingConversation = [ZMConversation conversationWithRemoteID:remoteID createIfNeeded:NO inContext:self.managedObjectContext];
    if ((existingConversation != nil) && ![existingConversation isEqual:self]) {
        Require(self.remoteIdentifier == nil);
        [self.mutableMessages unionSet:existingConversation.allMessages];
        // Just to be on the safe side, force update:
        self.needsToBeUpdatedFromBackend = YES;
        // This is a duplicate. Delete the other one
        [self.managedObjectContext deleteObject:existingConversation];
    }
    self.remoteIdentifier = remoteID;
}

+ (instancetype)conversationWithRemoteID:(NSUUID *)UUID createIfNeeded:(BOOL)create inContext:(NSManagedObjectContext *)moc
{
    return [self conversationWithRemoteID:UUID createIfNeeded:create inContext:moc created:NULL];
}

+ (instancetype)conversationWithRemoteID:(NSUUID *)UUID createIfNeeded:(BOOL)create inContext:(NSManagedObjectContext *)moc created:(BOOL *)created
{
    VerifyReturnNil(UUID != nil);
    
    // We must only ever call this on the sync context. Otherwise, there's a race condition
    // where the UI and sync contexts could both insert the same conversation (same UUID) and we'd end up
    // having two duplicates of that conversation, and we'd have a really hard time recovering from that.
    //
    RequireString(! create || moc.zm_isSyncContext, "Race condition!");
    
    ZMConversation *result = [self fetchObjectWithRemoteIdentifier:UUID inManagedObjectContext:moc];
    
    if (result != nil) {
        if (nil != created) {
            *created = NO;
        }
        return result;
    } else if (create) {
        ZMConversation *conversation = [ZMConversation insertNewObjectInManagedObjectContext:moc];
        conversation.remoteIdentifier = UUID;
        conversation.lastServerTimeStamp = [NSDate dateWithTimeIntervalSince1970:0];
        if (nil != created) {
            *created = YES;
        }
        return conversation;
    }
    return nil;
}


+ (NSPredicate *)predicateForSearchQuery:(NSString *)searchQuery team:(Team *)team moc:(NSManagedObjectContext *)moc
{
    NSPredicate *teamPredicate = [NSPredicate predicateWithFormat:@"(%K == %@)", TeamKey, team];
    
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[[ZMConversation predicateForSearchQuery:searchQuery selfUser: [ZMUser selfUserInContext:moc]], teamPredicate]];
}

+ (NSPredicate *)userDefinedNamePredicateForSearchString:(NSString *)searchString;
{
    NSPredicate *predicate = [NSPredicate predicateWithFormatDictionary:@{ZMNormalizedUserDefinedNameKey: @"%K MATCHES %@"}
                                                   matchingSearchString:searchString];
    return predicate;
}


+ (NSUUID *)selfConversationIdentifierInContext:(NSManagedObjectContext *)context;
{
    // remoteID of self-conversation is guaranteed to be the same as remoteID of self-user
    ZMUser *selfUser = [ZMUser selfUserInContext:context];
    return selfUser.remoteIdentifier;
}

+ (ZMConversation *)selfConversationInContext:(NSManagedObjectContext *)managedObjectContext
{
    NSUUID *selfUserID = [ZMConversation selfConversationIdentifierInContext:managedObjectContext];
    return [ZMConversation conversationWithRemoteID:selfUserID createIfNeeded:NO inContext:managedObjectContext];
}

- (void)appendMessage:(ZMMessage *)message;
{
    Require(message != nil);
    [message updateNormalizedText];
    message.visibleInConversation = self;
    
    [self addAllMessagesObject:message];
    [self updateTimestampsAfterInsertingMessage:message];
}

- (void)unarchiveIfNeeded
{
    if (self.isArchived) {
        self.isArchived = NO;
    }
}

@end


@implementation ZMConversation (KeyValueValidation)

- (BOOL)validateUserDefinedName:(NSString **)ioName error:(NSError **)outError
{
    BOOL result = [ExtremeCombiningCharactersValidator validateValue:ioName error:outError];
    if (!result || (outError != nil && *outError != nil)) {
        return NO;
    }
    
    result &= *ioName == nil || [StringLengthValidator validateValue:ioName
                                                 minimumStringLength:1
                                                 maximumStringLength:64
                                                   maximumByteLength:INT_MAX
                                                               error:outError];

    return result;
}

@end


@implementation ZMConversation (Connections)

- (NSString *)connectionMessage;
{
    return self.connection.message.stringByRemovingExtremeCombiningCharacters;
}

@end


@implementation NSUUID (ZMSelfConversation)

- (BOOL)isSelfConversationRemoteIdentifierInContext:(NSManagedObjectContext *)moc;
{
    // The self conversation has the same remote ID as the self user:
    return [self isSelfUserRemoteIdentifierInContext:moc];
}

@end


@implementation ZMConversation (Optimization)

+ (void)refreshObjectsThatAreNotNeededInSyncContext:(NSManagedObjectContext *)managedObjectContext;
{
    NSMutableArray *conversationsToKeep = [NSMutableArray array];
    NSMutableSet *usersToKeep = [NSMutableSet set];
    NSMutableSet *messagesToKeep = [NSMutableSet set];
    
    // make sure that the Set is not mutated while being enumerated
    NSSet *registeredObjects = managedObjectContext.registeredObjects;
    
    // gather objects to keep
    for(NSManagedObject *obj in registeredObjects) {
        if (!obj.isFault) {
            if ([obj isKindOfClass:ZMConversation.class]) {
                ZMConversation *conversation = (ZMConversation *)obj;
                
                if(conversation.shouldNotBeRefreshed) {
                    [conversationsToKeep addObject:conversation];
                    [usersToKeep unionSet:conversation.participantRoles];
                }
            } else if ([obj isKindOfClass:ZMOTRMessage.class]) {
                ZMOTRMessage *message = (ZMOTRMessage *)obj;
                if (![message hasFaultForRelationshipNamed:ZMMessageMissingRecipientsKey] && !message.missingRecipients.isEmpty) {
                    [messagesToKeep addObject:obj];
                }
            }
        }
    }
    [usersToKeep addObject:[ZMUser selfUserInContext:managedObjectContext]];
    
    // turn into a fault
    for(NSManagedObject *obj in registeredObjects) {
        if(!obj.isFault) {
            
            const BOOL isUser = [obj isKindOfClass:ZMUser.class];
            const BOOL isMessage = [obj isKindOfClass:ZMMessage.class];
            const BOOL isConversation = [obj isKindOfClass:ZMConversation.class];
            
            const BOOL isOfTypeToBeRefreshed = isUser || isMessage || isConversation;
            
            if ((isConversation && [conversationsToKeep indexOfObjectIdenticalTo:obj] != NSNotFound) ||
                (isUser && [usersToKeep.allObjects indexOfObjectIdenticalTo:obj] != NSNotFound) ||
                (isMessage && [messagesToKeep.allObjects indexOfObjectIdenticalTo:obj] != NSNotFound) ||
                !isOfTypeToBeRefreshed) {
                continue;
            }
            [managedObjectContext refreshObject:obj mergeChanges:obj.hasChanges];
        }
    }
}

- (BOOL)shouldNotBeRefreshed
{
    static const int HOUR_IN_SEC = 60 * 60;
    static const NSTimeInterval STALENESS = -36 * HOUR_IN_SEC;
    return (self.isFault) || (self.lastModifiedDate == nil) || (self.lastModifiedDate.timeIntervalSinceNow > STALENESS);
}

@end


@implementation ZMConversation (History)


- (void)clearMessageHistory
{
    self.isArchived = YES;
    self.clearedTimeStamp = self.lastServerTimeStamp; // the setter of this deletes all messages
    self.lastReadServerTimeStamp = self.lastServerTimeStamp;
}

- (void)revealClearedConversation
{
    self.isArchived = NO;
}

@end
