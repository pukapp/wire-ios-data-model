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


@import WireImages;
@import WireProtos;
@import WireTransport;

#import "ZMMessage.h"
#import "ZMManagedObject+Internal.h"
#import "ZMFetchRequestBatch.h"

@class ZMUser;
@class Reaction;
@class Operation;
@class ZMConversation;
@class ZMUpdateEvent;
@class ZMMessageConfirmation;
@class ZMReaction;
@class ZMClientMessage;
@class ServiceMessage;
@class ZMGenericMessageData;

@protocol UserClientType;

extern NSString * _Nonnull const ZMMessageIsExpiredKey;
extern NSString * _Nonnull const ZMMessageMissingRecipientsKey;
extern NSString * _Nonnull const ZMMessageImageTypeKey;
extern NSString * _Nonnull const ZMMessageIsAnimatedGifKey;
extern NSString * _Nonnull const ZMMessageMediumRemoteIdentifierDataKey;
extern NSString * _Nonnull const ZMMessageMediumRemoteIdentifierKey;
extern NSString * _Nonnull const ZMMessageOriginalDataProcessedKey;
extern NSString * _Nonnull const ZMMessageOriginalSizeDataKey;
extern NSString * _Nonnull const ZMMessageOriginalSizeKey;
extern NSString * _Nonnull const ZMMessageConversationKey;
extern NSString * _Nonnull const ZMMessageHiddenInConversationKey;
extern NSString * _Nonnull const ZMMessageExpirationDateKey;
extern NSString * _Nonnull const ZMMessageNameKey;
extern NSString * _Nonnull const ZMMessageNeedsToBeUpdatedFromBackendKey;
extern NSString * _Nonnull const ZMMessageNonceDataKey;
extern NSString * _Nonnull const ZMMessageSenderKey;
extern NSString * _Nonnull const ZMMessageSystemMessageTypeKey;
extern NSString * _Nonnull const ZMMessageTextKey;
extern NSString * _Nonnull const ZMMessageUserIDsKey;
extern NSString * _Nonnull const ZMMessageUsersKey;
extern NSString * _Nonnull const ZMMessageClientsKey;
extern NSString * _Nonnull const ZMMessageConfirmationKey;
extern NSString * _Nonnull const ZMMessageCachedCategoryKey;
extern NSString * _Nonnull const ZMMessageSystemMessageClientsKey;
extern NSString * _Nonnull const ZMMessageDeliveryStateKey;
extern NSString * _Nonnull const ZMMessageRepliesKey;
extern NSString * _Nonnull const ZMMessageQuoteKey;
extern NSString * _Nonnull const ZMMessageConfirmationKey;
extern NSString * _Nonnull const ZMMessageLinkAttachmentsKey;
extern NSString * _Nonnull const ZMMessageNeedsLinkAttachmentsUpdateKey;

extern NSString * _Nonnull const ZMMessageJsonTextKey;

// 币币兑换状态
// 0 :  没有兑换
// 1 :  已兑换
// 2 :  已兑完
typedef NS_ENUM(int16_t, ZMBiBiCashType) {
    ZMBiBiCashTypeNone = 0,
    ZMBiBiCashTypeGotten,
    ZMBiBiCashTypeGottenAll,
    ZMBiBiCashTypeExpired
};

@interface ZMMessage : ZMManagedObject

+(instancetype _Nonnull )insertNewObjectInManagedObjectContext:(NSManagedObjectContext *_Nonnull)moc NS_UNAVAILABLE;
- (instancetype _Nonnull)initWithNonce:(NSUUID * _Nonnull)nonce managedObjectContext:(NSManagedObjectContext * _Nonnull)managedObjectContext;
+ (nonnull NSSet <ZMMessage *> *)messagesWithRemoteIDs:(nonnull NSSet <NSUUID *>*)UUIDs inContext:(nonnull NSManagedObjectContext *)moc;

// Use these for sorting:
+ (NSArray<NSSortDescriptor *> * _Nonnull)defaultSortDescriptors;
- (NSComparisonResult)compare:(ZMMessage * _Nonnull)other;
- (NSUUID * _Nullable)nonceFromPostPayload:(NSDictionary * _Nonnull)payload;
- (void)updateWithPostPayload:(NSDictionary * _Nonnull)payload updatedKeys:(__unused NSSet * _Nullable)updatedKeys;
- (void)resend;
- (BOOL)shouldGenerateUnreadCount;
- (BOOL)shouldGenerateFirstUnread;
///是否需要被赋值为conversation的lastMessage,即是否被展示在conversationList上
- (BOOL)shouldGenerateLastVisibleMessage;
///这是改变当前群LastModified属性，由于conversation的排序条件是LastModified，所以此处需要判断是否刷新当前群
- (BOOL)shouldUpdateLastModified;

@property (nonatomic) BOOL delivered;

/// Removes the message and deletes associated content
/// @param clearingSender Whether information about the sender should be removed or not
- (void)removeMessageClearingSender:(BOOL)clearingSender;

/// Removes the message only for clients of the selfUser
+ (void)removeMessageWithRemotelyHiddenMessage:(ZMMessageHide * _Nonnull)hiddenMessage
                        inManagedObjectContext:(NSManagedObjectContext * _Nonnull)moc;

/// Removes the message for all participants of the message's conversation
/// Clients that don't belong to the selfUser will see a system message indicating the deletion
+ (void)removeMessageWithRemotelyDeletedMessage:(ZMMessageDelete * _Nonnull)deletedMessage
                                 inConversation:(ZMConversation * _Nonnull)conversation
                                       senderID:(NSUUID * _Nonnull)senderID
                         inManagedObjectContext:(NSManagedObjectContext * _Nonnull)moc;


+ (void)addReaction:(ZMReaction * _Nonnull)reaction
           senderID:(NSUUID * _Nonnull)senderID
       conversation:(ZMConversation * _Nonnull)conversation
inManagedObjectContext:(NSManagedObjectContext * _Nonnull)moc;
+ (void)addReaction:(ZMReaction * _Nonnull)reaction
           sender:(ZMUser * _Nonnull)sender
       conversation:(ZMConversation * _Nonnull)conversation
inManagedObjectContext:(NSManagedObjectContext * _Nonnull)moc;


+ (void)addOperation:(ZMForbid * _Nonnull)operation
             sender:(ZMUser * _Nonnull)sender
       conversation:(ZMConversation * _Nonnull)conversation
inManagedObjectContext:(NSManagedObjectContext * _Nonnull)moc;

@end



@interface ZMTextMessage : ZMMessage <ZMTextMessageData>

@property (nonatomic, readonly, copy) NSString * _Nullable text;

@end

@interface ZMJsonTextMessage : ZMMessage <ZMJsonTextMessageData>

@property (nonatomic, readonly, copy) NSString * _Nullable text;

@end



@interface ZMImageMessage : ZMMessage <ZMImageMessageData>

@property (nonatomic, readonly) BOOL mediumDataLoaded;
@property (nonatomic, readonly) BOOL originalDataProcessed;
@property (nonatomic, readonly) NSData * _Nullable mediumData; ///< N.B.: Will go away from public header
@property (nonatomic, readonly) NSData * _Nullable imageData; ///< This will either returns the mediumData or the original image data. Usefull only for newly inserted messages.
@property (nonatomic, readonly) NSString * _Nullable imageDataIdentifier; /// This can be used as a cache key for @c -imageData

@property (nonatomic, readonly) NSData * _Nullable previewData;
@property (nonatomic, readonly) NSString * _Nullable imagePreviewDataIdentifier; /// This can be used as a cache key for @c -previewData
@property (nonatomic, readonly) BOOL isAnimatedGIF; // If it is GIF and has more than 1 frame
@property (nonatomic, readonly) NSString * _Nullable imageType; // UTI e.g. kUTTypeGIF

@property (nonatomic, readonly) CGSize originalSize;

@end



@interface ZMKnockMessage : ZMMessage <ZMKnockMessageData>

@end



@interface ZMSystemMessage : ZMMessage <ZMSystemMessageData>

@property (nonatomic) ZMSystemMessageType systemMessageType;
@property (nonatomic) NSSet<ZMUser *> * _Nonnull users;
@property (nonatomic) NSSet <id<UserClientType>>* _Nonnull clients;
@property (nonatomic) NSSet<ZMUser *> * _Nonnull addedUsers; // Only filled for ZMSystemMessageTypePotentialGap and ZMSystemMessageTypeIgnoredClient
@property (nonatomic) NSSet<ZMUser *> * _Nonnull removedUsers; // Only filled for ZMSystemMessageTypePotentialGap
@property (nonatomic, copy) NSString * _Nullable text;
@property (nonatomic) BOOL needsUpdatingUsers;
@property (nonatomic) BOOL isService;

@property (nonatomic) NSTimeInterval duration; // Only filled for .performedCall
@property (nonatomic) id <ZMSystemMessageData> _Nullable parentMessage; // Only filled for .performedCall & .missedCall

@property (nonatomic, readonly) BOOL userIsTheSender; // Set to true if sender is the only user in users array. E.g. when a wireless user joins conversation
@property (nonatomic) NSNumber * _Nullable messageTimer;

@property (nonatomic) NSNumber * _Nullable blockTime;
@property (nonatomic) NSNumber * _Nullable blockDuration;
@property (nonatomic) NSString * _Nullable opt_id;
@property (nonatomic) NSString * _Nullable add_friend;
@property (nonatomic) NSString * _Nullable messageVisible;
@property (nonatomic) NSString * _Nullable changeCreatorId;

@property (nonatomic) ServiceMessage * _Nullable serviceMessage;

@property (nonatomic) NSString * _Nullable blockUser;
@property (nonatomic) ZMSystemManagerMessageType managerType;
// Only filled for .messageTimerUpdate
@property (nonatomic) BOOL relevantForConversationStatus; // If true (default), the message is considered to be shown inside the conversation list

///新增属性，当群内收到加人，删人推送时，根据此属性就可在会话页面显示系统消息，不需要在本地创建user，并从后台获取user数据了（主要针对于万人群）
@property (nonatomic) NSOrderedSet<NSString *> * _Nonnull userIDs;
@property (nonatomic) NSArray<NSString *> * _Nonnull userNames;
    
+ (ZMSystemMessage * _Nullable)fetchLatestPotentialGapSystemMessageInConversation:(ZMConversation * _Nonnull)conversation;
- (void)updateNeedsUpdatingUsersIfNeeded;

@end



@interface ZMMessage ()
// 新增是否需要回复标记,默认为false
@property (nonatomic) BOOL isNeedReply;
// 新增是否需要上传,默认为false
@property (nonatomic) BOOL isNeedUpload;
// 新增自己当前设备发送消息标记,默认为false
@property (nonatomic) BOOL isSelfSend;
// 标记红包是否已领取,默认为false
@property (nonatomic) BOOL  isGet;
// 标记币币兑换状态
@property (nonatomic) ZMBiBiCashType bibiCashType;
// 用户是否确认拒绝被邀请
@property (nonatomic) BOOL isRefuse;
// 此消息是否强制不被禁言
@property (nonatomic) BOOL unblock;
// 是否需要群助手回复
@property (nonatomic) BOOL isNeedAssistantBotReply;
//是否违规
@property (nonatomic) BOOL isillegal;
//违规操作者名字
@property (nonatomic) NSString * _Nullable illegalUserName;
//是否已送达
@property (nonatomic) BOOL isSendDelivered;
//是否已读
@property (nonatomic) BOOL isSendRead;
//翻译后的文本
@property (nonatomic) NSString * _Nullable translationText;

@property (nonatomic) NSSet <ZMUser *> * _Nullable recipientUsers;

@property (nonatomic) NSString * _Nullable senderClientID;
@property (nonatomic) NSUUID * _Nullable nonce;
@property (nonatomic) NSDate * _Nullable destructionDate;

@property (nonatomic, readonly) BOOL isUnreadMessage;
@property (nonatomic) BOOL isExpired;
@property (nonatomic, readonly) NSDate * _Nullable expirationDate;
@property (nonatomic) BOOL isObfuscated;
@property (nonatomic, readonly) BOOL needsReadConfirmation;
@property (nonatomic) NSString * _Nullable normalizedText;

@property (nonatomic) NSSet <Reaction *> * _Nonnull reactions;
@property (nonatomic) NSSet <Operation *> * _Nonnull operations;
@property (nonatomic, readonly) NSSet<ZMMessageConfirmation*> * _Nonnull confirmations;

@property (nonatomic) NSSet * _Nullable missingRecipients;
@property (nonatomic, nullable) ZMGenericMessage *genericMessage;
@property (nonatomic) NSOrderedSet * _Nonnull dataSet;
@property (nonatomic) ZMMessage * _Nullable quote;
/// Link Preview state
@property (nonatomic) NSDate * _Nullable updatedTimestamp;

- (void)setExpirationDate;
- (void)removeExpirationDate;
- (void)expire;

/// Sets a flag to mark the message as being delivered to the backend
- (void)markAsSent;

+ (instancetype _Nullable)fetchMessageWithNonce:(NSUUID * _Nullable)nonce
                      forConversation:(ZMConversation * _Nullable)conversation
               inManagedObjectContext:(NSManagedObjectContext * _Nonnull)moc;

+ (instancetype _Nullable)fetchMessageWithNonce:(NSUUID * _Nonnull)nonce
                      forConversation:(ZMConversation * _Nullable)conversation
               inManagedObjectContext:(NSManagedObjectContext * _Nonnull)moc
                       prefetchResult:(ZMFetchRequestBatchResult * _Nullable)prefetchResult;

- (NSString * _Nonnull)shortDebugDescription;

- (void)updateWithPostPayload:(NSDictionary * _Nonnull)payload updatedKeys:(NSSet * _Nonnull)updatedKeys;
+ (BOOL)doesEventTypeGenerateMessage:(ZMUpdateEventType)type;

/// Returns a predicate that matches messages that might expire if they are not sent in time
+ (NSPredicate * _Nonnull)predicateForMessagesThatWillExpire;


+ (void)setDefaultExpirationTime:(NSTimeInterval)defaultExpiration;
+ (NSTimeInterval)defaultExpirationTime;
+ (void)resetDefaultExpirationTime;

+ (ZMConversation * _Nullable)conversationForUpdateEvent:(ZMUpdateEvent * _Nonnull)event inContext:(NSManagedObjectContext * _Nonnull)moc prefetchResult:(ZMFetchRequestBatchResult * _Nullable)prefetchResult;

/// Returns the message represented in this update event
/// @param prefetchResult Contains a mapping from message nonce to message and `remoteIdentifier` to `ZMConversation`,
/// which should be used to avoid premature fetchRequests. If the class needs messages or conversations to be prefetched
/// and passed into this method it should conform to `ZMObjectStrategy` and return them in
/// `-messageNoncesToPrefetchToProcessEvents:` or `-conversationRemoteIdentifiersToPrefetchToProcessEvents`
+ (ZMMessage * _Nullable)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent * _Nonnull)updateEvent
                              inManagedObjectContext:(NSManagedObjectContext * _Nonnull)moc
                                      prefetchResult:(ZMFetchRequestBatchResult * _Nullable)prefetchResult;

- (void)removePendingDeliveryReceipts;
- (void)updateWithUpdateEvent:(ZMUpdateEvent * _Nonnull)updateEvent forConversation:(ZMConversation * _Nonnull)conversation;
- (void)updateWithSender:(ZMUser * _Nonnull)sender forConversation:(ZMConversation * _Nonnull)conversation;
- (void)updateAssistantbotWithUpdateEvent:(ZMUpdateEvent * _Nonnull)updateEvent
                          forConversation:(ZMConversation * _Nonnull)conversation jsonText: (NSString *_Nonnull)text;
/// Returns whether the data represents animated GIF
+ (BOOL)isDataAnimatedGIF:(NSData * _Nonnull)data;

/// Predicate to select messages that are part of a conversation
+ (NSPredicate * _Nonnull)predicateForMessageInConversation:(ZMConversation * _Nonnull)conversation withNonces:(NSSet <NSUUID *>*  _Nonnull)nonces;

/// Predicate to select messages whose link attachments need to be updated.
+ (NSPredicate * _Nonnull)predicateForMessagesThatNeedToUpdateLinkAttachments;

- (ZMGenericMessage * _Nullable)genericMessageFromDataSet;
- (void)deleteContent;
- (ZMGenericMessageData * _Nullable)mergeWithExistingData:(NSData * _Nonnull)data;
- (void)addData:(NSData * _Nonnull)data;
@end



@interface ZMTextMessage (Internal)

@property (nonatomic, copy) NSString * _Nullable text;

+ (instancetype _Nullable)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent * _Nonnull)updateEvent
                               decodedGenericMessage:(ZMGenericMessage * _Nonnull)genericMessage
                              inManagedObjectContext:(NSManagedObjectContext * _Nonnull)moc;

@end

@interface ZMJsonTextMessage (Internal)

@property (nonatomic, copy) NSString * _Nullable text;

+ (instancetype _Nullable)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent * _Nonnull)updateEvent
                                         decodedGenericMessage:(ZMGenericMessage * _Nonnull)genericMessage
                                        inManagedObjectContext:(NSManagedObjectContext * _Nonnull)moc;

@end



extern NSString *  _Nonnull const ZMImageMessagePreviewNeedsToBeUploadedKey;
extern NSString *  _Nonnull const ZMImageMessageMediumNeedsToBeUploadedKey;
extern NSString *  _Nonnull const ZMMessageServerTimestampKey;

@interface ZMImageMessage (Internal) <ZMImageOwner>

@property (nonatomic) BOOL mediumDataLoaded;
@property (nonatomic) BOOL originalDataProcessed;
@property (nonatomic) NSUUID * _Nullable mediumRemoteIdentifier;
@property (nonatomic) NSData * _Nullable mediumData;
@property (nonatomic) NSData * _Nullable  previewData;
@property (nonatomic) CGSize originalSize;
@property (nonatomic) NSData * _Nullable originalImageData;

- (NSData * _Nullable)imageDataForFormat:(ZMImageFormat)format;

@end



@interface ZMKnockMessage (Internal)

@end


@interface ZMSystemMessage (Internal)

+ (BOOL)doesEventTypeGenerateSystemMessage:(ZMUpdateEventType)type;
+ (instancetype _Nullable)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent * _Nonnull)updateEvent inManagedObjectContext:(NSManagedObjectContext * _Nonnull)moc;
+ (NSPredicate * _Nonnull)predicateForSystemMessagesInsertedLocally;

@end




@interface ZMMessage (Ephemeral)


/// Sets the destruction date to the current date plus the timeout
/// After this date the message "self-destructs", e.g. gets deleted from all sender & receiver devices or obfuscated if the sender is the selfUser
- (BOOL)startDestructionIfNeeded;

/// Obfuscates the message which means, it deletes the genericMessage content
- (void)obfuscate;

/// Inserts a delete message for the ephemeral and sets the destruction timeout to nil
- (void)deleteEphemeral;

/// Restarts the deletion timer with the given time interval. If a timer already
/// exists, it will be stopped first.
- (void)restartDeletionTimer:(NSTimeInterval)remainingTime;

/// Restarts the deletion timer with the given time interval. If a timer already
/// exists, it will be stopped first.
- (void)restartObfuscationTimer:(NSTimeInterval)remainingTime;

/// When we restart, we might still have messages that had a timer, but whose timer did not fire before killing the app
/// To delete those messages immediately use this method on startup (e.g. in the init of the ZMClientMessageTranscoder) to fetch and delete those messages
+ (void)deleteOldEphemeralMessages:(NSManagedObjectContext * _Nonnull)context;

@end

