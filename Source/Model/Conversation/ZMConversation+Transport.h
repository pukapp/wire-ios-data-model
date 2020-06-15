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


#import "ZMConversation.h"

@class ZMUpdateEvent;
typedef NS_ENUM(int, ZMBackendConversationType) {
    ZMConvTypeGroup = 0,
    ZMConvTypeSelf = 1,
    ZMConvOneToOne = 2,
    ZMConvConnection = 3,
    ZMConvTypeHugeGroup = 5, // 万人群
};

extern NSString *const ZMConversationInfoOTRMutedValueKey;
extern NSString *const ZMConversationInfoOTRMutedReferenceKey;
extern NSString *const ZMConversationInfoOTRMutedStatusValueKey;
extern NSString *const ZMConversationInfoOTRArchivedValueKey;
extern NSString *const ZMConversationInfoOTRArchivedReferenceKey;
//new add
extern NSString *const ZMConversationInfoOTRSelfRemarkBoolKey;
extern NSString *const ZMConversationInfoOTRSelfRemarkReferenceKey;
extern NSString *const ZMConversationInfoOTRSelfVerifyKey;
extern NSString *const ZMConversationInfoMemberInviteVerfyKey;
extern NSString *const ZMConversationInfoOTRCreatorChangeKey;
extern NSString *const ZMConversationInfoBlockTimeKey;
extern NSString *const ZMConversationInfoBlockDurationKey;
extern NSString *const ZMConversationInfoOpt_idKey;
extern NSString *const ZMConversationInfoBlockUserKey;
extern NSString *const ZMConversationInfoOratorKey;
extern NSString *const ZMConversationInfoManagerKey;
extern NSString *const ZMConversationInfoManagerAddKey;
extern NSString *const ZMConversationInfoManagerDelKey;
extern NSString *const ZMConversationInfoOTRCanAddKey;
extern NSString *const ZMCOnversationInfoOTROpenUrlJoinKey;
extern NSString *const ZMCOnversationInfoOTRAllowViewMembersKey;
extern NSString *const ZMConversationInfoAppsKey;
extern NSString *const ZMConversationInfoTopAppsKey;
extern NSString *const ZMConversationInfoTopWebAppsKey;
extern NSString *const ZMConversationInfoIsAllowMemberAddEachOtherKey;
extern NSString *const ZMConversationInfoIsVisibleForMemberChangeKey;
extern NSString *const ZMConversationInfoPlaceTopKey;
extern NSString *const ZMConversationInfoIsVisitorsVisibleKey;
extern NSString *const ZMConversationInfoIsMessageVisibleOnlyManagerAndCreatorKey;
extern NSString *const ZMConversationInfoAnnouncementKey;
extern NSString *const ZMConversationBlockedKey;
extern NSString *const ZMConversationShowMemsumKey;
extern NSString *const ZMConversationEnabledEditMsgKey;
extern NSString *const ZMConversationAssistantBotKey;
extern NSString *const ZMConversationAssistantBotOptKey;

@interface ZMConversation (Transport)

- (void)updateWithUpdateEvent:(ZMUpdateEvent *)updateEvent;
- (void)updateClearedFromPostPayloadEvent:(ZMUpdateEvent *)event;
- (void)updateWithTransportData:(NSDictionary *)transportData serverTimeStamp:(NSDate *)serverTimeStamp;
- (void)updatePotentialGapSystemMessagesIfNeededWithUsers:(NSSet <ZMUser *>*)users;

/// Pass timeStamp when the timeStamp equals the time of the lastRead / cleared event, otherwise pass nil
- (void)updateSelfStatusFromDictionary:(NSDictionary *)dictionary timeStamp:(NSDate *)timeStamp previousLastServerTimeStamp:(NSDate *)previousLastServerTimestamp;

+ (ZMConversationType)conversationTypeFromTransportData:(NSNumber *)transportType;

- (BOOL)shouldAddEvent:(ZMUpdateEvent *)event;

@end
