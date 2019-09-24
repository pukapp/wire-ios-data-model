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


@import WireSystem;

#import "ZMManagedObject.h"
#import "ZMMessage.h"
#import "ZMManagedObjectContextProvider.h"


@class ZMUser;
@class ZMMessage;
@class ZMTextMessage;
@class ZMImageMessage;
@class ZMKnockMessage;
@class ZMConversationList;
@class ZMFileMetadata;
@class ZMLocationData;
@class LinkMetadata;
@class Team;
@class UserAliasname;
@class ZMWebApp;
@class UserDisableSendMsgStatus;

@protocol ZMConversationMessage;

typedef NS_CLOSED_ENUM(int16_t, ZMConversationType) {
    ZMConversationTypeInvalid = 0,

    ZMConversationTypeSelf,
    ZMConversationTypeOneOnOne,
    ZMConversationTypeGroup,
    ZMConversationTypeConnection, // Incoming & outgoing connection request
    ZMConversationTypeHugeGroup, // 万人群 type=5
};

/// The current indicator to be shown for a conversation in the conversation list.
typedef NS_ENUM(int16_t, ZMConversationListIndicator) {
    ZMConversationListIndicatorInvalid = 0,
    ZMConversationListIndicatorNone,
    ZMConversationListIndicatorUnreadSelfMention,
    ZMConversationListIndicatorUnreadSelfReply,
    ZMConversationListIndicatorUnreadMessages,
    ZMConversationListIndicatorKnock,
    ZMConversationListIndicatorMissedCall,
    ZMConversationListIndicatorExpiredMessage,
    ZMConversationListIndicatorActiveCall, ///< Ringing or talking in call.
    ZMConversationListIndicatorInactiveCall, ///< Other people are having a call but you are not in it.
    ZMConversationListIndicatorPending
};

// 智能回复模式
// 0 : 关闭
// 1 :  智能达尔文托管
// 2 :  智能小天使托管
// 3 :  智能校花托管
// 4 : 人工训练模式
typedef NS_ENUM(int16_t, ZMAutoReplyType) {
    ZMAutoReplyTypeClosed = 0,
    ZMAutoReplyTypeDarwin,
    ZMAutoReplyTypeAngel,
    ZMAutoReplyTypeCampusBelle,
    ZMAutoReplyTypeAI, // Incoming & outgoing connection request
    ZMAutoReplyTypeZuChongZhi
};


extern NSString * _Null_unspecified const ZMIsDimmedKey; ///< Specifies that a range in an attributed string should be displayed dimmed.

@interface ZMConversation : ZMManagedObject

@property (nonatomic, copy, nullable) NSString *userDefinedName;

@property (readonly, nonatomic) ZMConversationType conversationType;
@property (readonly, nonatomic, nullable) NSDate *lastModifiedDate;
@property (nonatomic, nullable) NSDate *disableSendLastModifiedDate;
@property (readonly, nonatomic, nonnull) NSOrderedSet *messages;
@property (readonly, nonatomic, nonnull) NSOrderedSet *messagesFilterService;
@property (readonly, nonatomic, nonnull) NSSet<ZMUser *> *activeParticipants;
//新增群昵称
@property (readonly, nonatomic, nonnull) NSSet<UserAliasname *> *membersAliasname;
//群禁言
@property (readonly, nonatomic, nonnull) NSSet<UserDisableSendMsgStatus *> *membersSendMsgStatuses;
@property (nonatomic) ServiceMessage * _Nullable lastServiceMessage;
@property (readonly, nonatomic, nonnull) NSSet<ZMMessage *> *allMessages;
@property (readonly, nonatomic, nonnull) NSArray<ZMUser *> *sortedActiveParticipants;
@property (readonly, nonatomic, nonnull) ZMUser *creator;
@property (nonatomic, readonly) BOOL isPendingConnectionConversation;
@property (nonatomic, readonly) NSUInteger estimatedUnreadCount;
@property (nonatomic, readonly) NSUInteger estimatedUnreadSelfMentionCount;
@property (nonatomic, readonly) NSUInteger estimatedUnreadSelfReplyCount;
@property (nonatomic, readonly) ZMConversationListIndicator conversationListIndicator;
@property (nonatomic, readonly) BOOL hasDraftMessage;
@property (nonatomic, nullable) Team *team;

/// This will return @c nil if the last added by self user message has not yet been sync'd to this device, or if the conversation has no self editable message.
@property (nonatomic, readonly, nullable) ZMMessage *lastEditableMessage;

@property (nonatomic) BOOL isArchived;

/// returns whether the user is allowed to write to this conversation
@property (nonatomic, readonly) BOOL isReadOnly;

/// For group conversation this will be nil, for one to one or connection conversation this will be the other user
@property (nonatomic, readonly, nullable) ZMUser *connectedUser;
/// 新增
/// 我对单人聊天里好友的智能回复状态
@property (nonatomic) ZMAutoReplyType autoReply;
/// 单人聊天里好友对我的智能回复状态
@property (nonatomic) ZMAutoReplyType autoReplyFromOther;
// 是否开启群二维码链接邀请
@property (nonatomic) BOOL isOpenUrlJoin;
// 群二维码链接
@property (nonatomic, copy, nullable) NSString *joinGroupUrl;
// 群应用icon组(逗号分割)
@property (nonatomic, copy, nullable) NSString *appletsIcon;
//群昵称
@property (nonatomic, copy, nullable)NSString *selfRemark;
//是否开启群主验证邀请
@property (nonatomic) BOOL isOpenCreatorInviteVerify;
//是否开启仅限群主邀请
@property (nonatomic) BOOL isOnlyCreatorInvite;
//是否开启成员被邀请确认
@property (nonatomic) BOOL isOpenMemberInviteVerify;
//群成员数量
@property (nonatomic) NSInteger membersCount;
// 允许查看群成员
@property (nonatomic) BOOL isAllowViewMembers;
/// 群头像
@property (nullable, nonatomic, copy) NSString *groupImageMediumKey;
@property (nullable, nonatomic, copy) NSString *groupImageSmallKey;
@property (nullable, nonatomic, copy) NSData *imageMediumData;
@property (nullable, nonatomic, copy) NSData *imageSmallProfileData;
//群应用
@property (nullable, nonatomic, copy) NSString *apps;///群内添加的所有应用
@property (nullable, nonatomic) NSOrderedSet<ZMWebApp *> *topWebApps;///群内置顶的应用
///绑定的社区ID
@property (nullable, nonatomic, copy) NSString *communityID;
// 置顶聊天
@property (nonatomic) BOOL isPlacedTop;
// 成员是否可以互相添加好友
@property (nonatomic) BOOL isAllowMemberAddEachOther;
// 成员变动其他群成员是否可见
@property (nonatomic) BOOL isVisibleForMemberChange;
//全员禁言
@property (nonatomic) BOOL isDisableSendMsg;

@property (nonatomic) NSSet<NSString *> * _Nullable orator;

@property (nonatomic) NSSet<NSString *> * _Nullable manager;
@property (nonatomic) NSSet<NSString *> * _Nullable managerAdd;
@property (nonatomic) NSSet<NSString *> * _Nullable managerDel;

/// 邀请人列表是否可见，默认NO 不可见
@property (nonatomic) BOOL isVisitorsVisible;

/// 消息可见性，默认NO
/// YES: 管理员发消息所有人可见，群成员发消息只有管理和群主可见
/// NO: 所有人可见
@property (nonatomic) BOOL isMessageVisibleOnlyManagerAndCreator;

/// 群公告
@property (nullable, nonatomic, copy) NSString *announcement;

@property (nonatomic) BOOL isReadAnnouncement;

@property (nonatomic) NSDate * _Nullable lastServiceMessageTimeStamp;

// 是否公众号
@property (nonatomic) BOOL isServiceNotice;

///群主更换监听属性
@property (nonatomic, nullable) NSDate *creatorChangeTimestamp;

///群内最后一条可见消息
@property (nonatomic, nullable) ZMMessage *lastVisibleMessage;

- (BOOL)canMarkAsUnread;
- (void)markAsUnread;

///// Insert a new group conversation into the user session
+ (nonnull instancetype)insertGroupConversationIntoUserSession:(nonnull id<ZMManagedObjectContextProvider> )session
                                              withParticipants:(nonnull NSArray<ZMUser *> *)participants
                                                        inTeam:(nullable Team *)team;

/// Insert a new group conversation with name into the user session
+ (nonnull instancetype)insertGroupConversationIntoUserSession:(nonnull id<ZMManagedObjectContextProvider> )session
                                              withParticipants:(nonnull NSArray<ZMUser *> *)participants
                                                          name:(nullable NSString*)name
                                                        inTeam:(nullable Team *)team;

/// Insert a new group conversation with name into the user session
+ (nonnull instancetype)insertGroupConversationIntoUserSession:(nonnull id<ZMManagedObjectContextProvider> )session
                                              withParticipants:(nonnull NSArray<ZMUser *> *)participants
                                                          name:(nullable NSString*)name
                                                        inTeam:(nullable Team *)team
                                                   allowGuests:(BOOL)allowGuests;


+ (nonnull instancetype)insertGroupConversationIntoUserSession:(nonnull id<ZMManagedObjectContextProvider> )session
                                              withParticipants:(nonnull NSArray<ZMUser *> *)participants
                                                          name:(nullable NSString*)name
                                                        inTeam:(nullable Team *)team
                                                   allowGuests:(BOOL)allowGuests
                                                topapps:(nullable NSArray *)topapps;

/// 创建万人群
+ (nonnull instancetype)insertHugeGroupConversationIntoUserSession:(nonnull id<ZMManagedObjectContextProvider> )session
                                                  withParticipants:(nonnull NSArray<ZMUser *> *)participants
                                                              name:(nullable NSString*)name
                                                            inTeam:(nullable Team *)team
                                                       allowGuests:(BOOL)allowGuests;


/// 删除群
- (void)deleteConversation;

/// If that conversation exists, it is returned, @c nil otherwise.
+ (nullable instancetype)existingOneOnOneConversationWithUser:(nonnull ZMUser *)otherUser inUserSession:(nonnull id<ZMManagedObjectContextProvider> )session;

@end

@interface ZMConversation (History)

/// This will reset the message history to the last message in the conversation.
- (void)clearMessageHistory;

/// UI should call this method on opening cleared conversation.
- (void)revealClearedConversation;

@end

@interface ZMConversation (Connections)

/// The message that was sent as part of the connection request.
@property (nonatomic, copy, readonly, nonnull) NSString *connectionMessage;

@end

