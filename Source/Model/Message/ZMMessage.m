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


@import WireUtilities;
@import WireProtos;
@import MobileCoreServices;
@import ImageIO;


#import "ZMMessage+Internal.h"
#import "ZMConversation.h"
#import "ZMUser+Internal.h"
#import "NSManagedObjectContext+zmessaging.h"
#import "ZMConversation+Internal.h"
#import "ZMConversation+Transport.h"

#import "ZMConversation+UnreadCount.h"
#import "ZMUpdateEvent+WireDataModel.h"
#import "ZMClientMessage.h"

#import <WireDataModel/WireDataModel-Swift.h>


static NSString *ZMLogTag ZM_UNUSED = @"ephemeral";

static NSTimeInterval ZMDefaultMessageExpirationTime = 30;

NSString * const ZMMessageEventIDDataKey = @"eventID_data";
NSString * const ZMMessageIsExpiredKey = @"isExpired";
NSString * const ZMMessageMissingRecipientsKey = @"missingRecipients";
NSString * const ZMMessageServerTimestampKey = @"serverTimestamp";
NSString * const ZMMessageImageTypeKey = @"imageType";
NSString * const ZMMessageIsAnimatedGifKey = @"isAnimatedGIF";
NSString * const ZMMessageMediumRemoteIdentifierDataKey = @"mediumRemoteIdentifier_data";
NSString * const ZMMessageMediumRemoteIdentifierKey = @"mediumRemoteIdentifier";
NSString * const ZMMessageOriginalDataProcessedKey = @"originalDataProcessed";
NSString * const ZMMessageMediumDataLoadedKey = @"mediumDataLoaded";
NSString * const ZMMessageOriginalSizeDataKey = @"originalSize_data";
NSString * const ZMMessageOriginalSizeKey = @"originalSize";
NSString * const ZMMessageConversationKey = @"visibleInConversation";
NSString * const ZMMessageHiddenInConversationKey = @"hiddenInConversation";
NSString * const ZMMessageExpirationDateKey = @"expirationDate";
NSString * const ZMMessageNameKey = @"name";
NSString * const ZMMessageNeedsToBeUpdatedFromBackendKey = @"needsToBeUpdatedFromBackend";
NSString * const ZMMessageNonceDataKey = @"nonce_data";
NSString * const ZMMessageSenderKey = @"sender";
NSString * const ZMMessageSystemMessageTypeKey = @"systemMessageType";
NSString * const ZMMessageSystemMessageClientsKey = @"clients";
NSString * const ZMMessageTextKey = @"text";
NSString * const ZMMessageUserIDsKey = @"users_ids";
NSString * const ZMMessageUsersKey = @"users";
NSString * const ZMMessageClientsKey = @"clients";
NSString * const ZMMessageAddedUsersKey = @"addedUsers";
NSString * const ZMMessageRemovedUsersKey = @"removedUsers";
NSString * const ZMMessageNeedsUpdatingUsersKey = @"needsUpdatingUsers";
NSString * const ZMMessageSenderClientIDKey = @"senderClientID";
NSString * const ZMMessageReactionKey = @"reactions";
NSString * const ZMMessageOperationKey = @"operations";
NSString * const ZMMessageConfirmationKey = @"confirmations";
NSString * const ZMMessageDestructionDateKey = @"destructionDate";
NSString * const ZMMessageIsObfuscatedKey = @"isObfuscated";
NSString * const ZMMessageCachedCategoryKey = @"cachedCategory";
NSString * const ZMMessageNormalizedTextKey = @"normalizedText";
NSString * const ZMMessageDeliveryStateKey = @"deliveryState";
NSString * const ZMMessageDurationKey = @"duration";
NSString * const ZMMessageChildMessagesKey = @"childMessages";
NSString * const ZMMessageParentMessageKey = @"parentMessage";
NSString * const ZMSystemMessageMessageTimerKey = @"messageTimer";
NSString * const ZMSystemMessageRelevantForConversationStatusKey = @"relevantForConversationStatus";
NSString * const ZMSystemMessageAllTeamUsersAddedKey = @"allTeamUsersAdded";
NSString * const ZMSystemMessageNumberOfGuestsAddedKey = @"numberOfGuestsAdded";
NSString * const ZMMessageRepliesKey = @"replies";
NSString * const ZMMessageQuoteKey = @"quote";
NSString * const ZMMessageExpectReadConfirmationKey = @"expectsReadConfirmation";
NSString * const ZMMessageLinkAttachmentsKey = @"linkAttachments";
NSString * const ZMMessageNeedsLinkAttachmentsUpdateKey = @"needsLinkAttachmentsUpdate";
NSString * const ZMMessageDiscoveredClientsKey = @"discoveredClients";

NSString * const ZMMessageJsonTextKey = @"jsonText";


@interface ZMMessage ()

+ (ZMConversation *)conversationForUpdateEvent:(ZMUpdateEvent *)event inContext:(NSManagedObjectContext *)context prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult;

- (void)updateWithUpdateEvent:(ZMUpdateEvent *)event forConversation:(ZMConversation *)conversation;

@property (nonatomic) NSSet *missingRecipients;

@end;



@interface ZMMessage (CoreDataForward)

@property (nonatomic) BOOL isExpired;
@property (nonatomic) NSDate *expirationDate;
@property (nonatomic) NSDate *destructionDate;
@property (nonatomic) BOOL isObfuscated;

@end


@interface ZMImageMessage (CoreDataForward)

@property (nonatomic) NSData *primitiveMediumData;

@end



@implementation ZMMessage

@dynamic missingRecipients;
@dynamic isExpired;
@dynamic expirationDate;
@dynamic destructionDate;
@dynamic senderClientID;
@dynamic reactions;
@dynamic operations;
@dynamic confirmations;
@dynamic isObfuscated;
@dynamic normalizedText;
@dynamic delivered;

@dynamic isNeedReply;
@dynamic isNeedUpload;
@dynamic isSelfSend;
@dynamic isGet;
@dynamic bibiCashType;
@dynamic isRefuse;
@dynamic unblock;
@dynamic recipientUsers;
@dynamic isNeedAssistantBotReply;

- (instancetype)initWithNonce:(NSUUID *)nonce managedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:[self.class entityName] inManagedObjectContext:managedObjectContext];
    self = [super initWithEntity:entity insertIntoManagedObjectContext:managedObjectContext];
    
    if (self != nil) {
        self.nonce = nonce;
    }
    
    return self;
}

+ (instancetype)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent
                              inManagedObjectContext:(NSManagedObjectContext *)moc
{
    ZMMessage *message = [self createOrUpdateMessageFromUpdateEvent:updateEvent inManagedObjectContext:moc prefetchResult:nil];
    [message updateCategoryCache];
    return message;
}

+ (BOOL)isDataAnimatedGIF:(NSData *)data
{
    if(data.length == 0) {
        return NO;
    }
    BOOL isAnimated = NO;
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef) data, NULL);
    VerifyReturnValue(source != NULL, NO);
    NSString *type = CFBridgingRelease(CGImageSourceGetType(source));
    if(UTTypeConformsTo((__bridge CFStringRef) type, kUTTypeGIF)) {
        isAnimated = CGImageSourceGetCount(source) > 1;
    }
    CFRelease(source);
    return isAnimated;
}

- (BOOL)isUnreadMessage
{
    NSDate *lastReadTimeStamp = self.conversation.lastReadServerTimeStamp;
    
    // has conversation && (no last read timestamp || last read timstamp is earlier than msg timestamp)
    return self.conversation != nil &&
            (lastReadTimeStamp == nil ||
             (self.serverTimestamp != nil && [self.serverTimestamp compare:lastReadTimeStamp] == NSOrderedDescending));
}

- (BOOL)shouldGenerateUnreadCount
{
    return YES;
}

- (BOOL)shouldGenerateFirstUnread {
    return YES;
}

- (BOOL)shouldGenerateLastVisibleMessage {
    return YES;
}

- (BOOL)shouldUpdateLastModified
{
    return YES;
}

+ (NSPredicate *)predicateForObjectsThatNeedToBeUpdatedUpstream;
{
    return [NSPredicate predicateWithValue:NO];
}

+ (NSString *)remoteIdentifierKey;
{
    return ZMMessageNonceDataKey;
}

+ (NSString *)entityName;
{
    return @"Message";
}

+ (NSString *)sortKey;
{
    return ZMMessageNonceDataKey;
}

+ (void)setDefaultExpirationTime:(NSTimeInterval)defaultExpiration
{
    ZMDefaultMessageExpirationTime = defaultExpiration;
}

+ (NSTimeInterval)defaultExpirationTime
{
    return ZMDefaultMessageExpirationTime;
}

+ (void)resetDefaultExpirationTime
{
    ZMDefaultMessageExpirationTime = ZMTransportRequestDefaultExpirationInterval;
}

- (void)resend;
{
    self.isExpired = NO;
    [self setExpirationDate];
    [self prepareToSend];
}

- (void)setExpirationDate
{
    self.expirationDate = [NSDate dateWithTimeIntervalSinceNow:[self.class defaultExpirationTime]];
}

- (void)removeExpirationDate;
{
    self.expirationDate = nil;
}

- (void)markAsSent
{
    self.isExpired = NO;
    [self removeExpirationDate];
}

- (BOOL)needsReadConfirmation {
    return NO;
}

- (void)expire;
{
    self.isExpired = YES;
    [self removeExpirationDate];
    self.conversation.hasUnreadUnsentMessage = YES;
}

+ (NSSet *)keyPathsForValuesAffectingDeliveryState;
{
    return [NSMutableSet setWithObjects: ZMMessageIsExpiredKey, ZMMessageConfirmationKey, nil];
}

- (void)awakeFromInsert;
{
    [super awakeFromInsert];
    self.serverTimestamp = [self dateIgnoringNanoSeconds];
}

- (NSDate *)dateIgnoringNanoSeconds
{
    double currentMilliseconds = floor([[NSDate date] timeIntervalSince1970]*1000);
    return [NSDate dateWithTimeIntervalSince1970:(currentMilliseconds/1000)];
}


- (NSUUID *)nonce;
{
    return [self transientUUIDForKey:@"nonce"];
}

- (void)setNonce:(NSUUID *)nonce;
{
    [self setTransientUUID:nonce forKey:@"nonce"];
}

+ (NSArray *)defaultSortDescriptors;
{
    static NSArray *sd;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSSortDescriptor *serverTimestamp = [NSSortDescriptor sortDescriptorWithKey:ZMMessageServerTimestampKey ascending:YES];
        sd = @[serverTimestamp];
    });
    return sd;
}

- (NSComparisonResult)compare:(ZMMessage *)other;
{
    for (NSSortDescriptor *sd in [[self class] defaultSortDescriptors]) {
        NSComparisonResult r = [sd compareObject:self toObject:other];
        if (r != NSOrderedSame) {
            return r;
        }
    }
    return NSOrderedSame;
}

- (void)updateWithUpdateEvent:(ZMUpdateEvent *)event forConversation:(ZMConversation *)conversation
{
    if (self.managedObjectContext != conversation.managedObjectContext) {
        conversation = [ZMConversation conversationWithRemoteID:conversation.remoteIdentifier createIfNeeded:NO inContext:self.managedObjectContext];
    }
    
    self.visibleInConversation = conversation;
    ZMUser *sender = [ZMUser userWithRemoteID:event.senderUUID createIfNeeded:YES inConversation: conversation inContext:self.managedObjectContext];
    if (sender != nil && !sender.isZombieObject && self.managedObjectContext == sender.managedObjectContext) {
        self.sender = sender;
    } else {
        ZMLogError(@"Sender is nil or from a different context than message. \n Sender is zombie %@: %@ \n Message: %@", @(sender.isZombieObject), sender, self);
    }
    
    [self updateQuoteRelationships];
    // 暂时注释掉，暂时解决重复计算未读的系统消息数量
//    [conversation updateTimestampsAfterUpdatingMessage:self];
}

// 优化user查询效率,用于替代func"[clientMessage updateWithUpdateEvent:updateEvent forConversation:conversation]"
- (void)updateWithSender:(ZMUser *)sender forConversation:(ZMConversation *)conversation
{
    if (self.managedObjectContext != conversation.managedObjectContext) {
        conversation = [ZMConversation conversationWithRemoteID:conversation.remoteIdentifier createIfNeeded:NO inContext:self.managedObjectContext];
    }
    
    self.visibleInConversation = conversation;
    if (sender != nil && !sender.isZombieObject && self.managedObjectContext == sender.managedObjectContext) {
        self.sender = sender;
    } else {
        ZMLogError(@"Sender is nil or from a different context than message. \n Sender is zombie %@: %@ \n Message: %@", @(sender.isZombieObject), sender, self);
    }
    
    [self updateQuoteRelationships];
    [conversation updateTimestampsAfterUpdatingMessage:self];
}

- (void)updateAssistantbotWithUpdateEvent:(ZMUpdateEvent * _Nonnull)updateEvent
                          forConversation:(ZMConversation * _Nonnull)conversation jsonText: (NSString *_Nonnull)text {
    if (self.managedObjectContext != conversation.managedObjectContext) {
        conversation = [ZMConversation conversationWithRemoteID:conversation.remoteIdentifier createIfNeeded:NO inContext:self.managedObjectContext];
    }
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:[text dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
    NSString *msgType = jsonDict[@"msgType"];
    if ([msgType isEqualToString: @"23"]) {
        NSString *fromUserId = jsonDict[@"msgData"][@"fromUserId"];
        ZMUser *user = [ZMUser userWithRemoteID:[NSUUID uuidWithTransportString:fromUserId] createIfNeeded:NO inContext:self.managedObjectContext];
        self.sender = user;
    }
    
}

+ (ZMConversation *)conversationForUpdateEvent:(ZMUpdateEvent *)event inContext:(NSManagedObjectContext *)moc prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult
{
    NSUUID *conversationUUID = event.conversationUUID;
    
    VerifyReturnNil(conversationUUID != nil);
    
    if (nil != prefetchResult.conversationsByRemoteIdentifier[conversationUUID]) {
        return prefetchResult.conversationsByRemoteIdentifier[conversationUUID];
    }
    
    return [ZMConversation conversationWithRemoteID:conversationUUID createIfNeeded:YES inContext:moc];
}

- (void)removeMessageClearingSender:(BOOL)clearingSender
{
    self.hiddenInConversation = self.conversation;
    self.visibleInConversation = nil;
    self.replies = [[NSSet alloc] init];
    [self clearAllReactions];
    [self clearConfirmations];
    
    if (clearingSender) {
        self.sender = nil;
        self.senderClientID = nil;
    }
}

+ (void)removeMessageWithRemotelyHiddenMessage:(ZMMessageHide *)hiddenMessage inManagedObjectContext:(NSManagedObjectContext *)moc;
{
    NSUUID *conversationID = [NSUUID uuidWithTransportString:hiddenMessage.conversationId];
    ZMConversation *conversation = [ZMConversation conversationWithRemoteID:conversationID createIfNeeded:NO inContext:moc];
    
    NSUUID *messageID = [NSUUID uuidWithTransportString:hiddenMessage.messageId];
    ZMMessage *message = [ZMMessage fetchMessageWithNonce:messageID forConversation:conversation inManagedObjectContext:moc];
    
    // To avoid reinserting when receiving an edit we delete the message locally
    if (message != nil) {
        [message removeMessageClearingSender:YES];
        [moc deleteObject:message];
    }
}

+ (void)addReaction:(ZMReaction *)reaction senderID:(NSUUID *)senderID conversation:(ZMConversation *)conversation inManagedObjectContext:(NSManagedObjectContext *)moc;
{
//    ZMUser *user = [ZMUser fetchObjectWithRemoteIdentifier:senderID inManagedObjectContext:moc];
    // 修复通过消息sendID获取user为nil导致crash的问题，即在本地数据库中查不到该user
    ZMUser *user = [ZMUser userWithRemoteID:senderID createIfNeeded:YES inConversation:conversation inContext:moc];
    NSUUID *nonce = [NSUUID uuidWithTransportString:reaction.messageId];
    ZMMessage *localMessage = [ZMMessage fetchMessageWithNonce:nonce
                                               forConversation:conversation
                                        inManagedObjectContext:moc];
    
    [localMessage addReaction:reaction.emoji forUser:user];
    [localMessage updateCategoryCache];
}

+ (void)addReaction:(ZMReaction *)reaction sender:(ZMUser *)sender conversation:(ZMConversation *)conversation inManagedObjectContext:(NSManagedObjectContext *)moc;
{
    TransportReaction transportReaction = [Reaction transportReactionFrom:reaction.emoji];
    
    //    ZMUser *user = [ZMUser fetchObjectWithRemoteIdentifier:senderID inManagedObjectContext:moc];
    // 修复通过消息sendID获取user为nil导致crash的问题，即在本地数据库中查不到该user
    NSUUID *nonce = [NSUUID uuidWithTransportString:reaction.messageId];
    
    ZMMessage *localMessage;
    
    switch (transportReaction) {
        case TransportReactionHeart:
        case TransportReactionNone:
            localMessage = [ZMMessage fetchMessageWithNonce:nonce
                                            forConversation:conversation
                                     inManagedObjectContext:moc];
            break;
            
        case TransportReactionAudioPlayed:
            localMessage = [ZMMessage fetchObjectWithRemoteIdentifier:nonce
                                               inManagedObjectContext:moc];
            break;
    }
    
    [localMessage addReaction:reaction.emoji forUser:sender];
    [localMessage updateCategoryCache];
}

+ (void)addOperation:(ZMForbid * _Nonnull)operation
              sender:(ZMUser * _Nonnull)sender
        conversation:(ZMConversation * _Nonnull)conversation
inManagedObjectContext:(NSManagedObjectContext * _Nonnull)moc
{
    //    ZMUser *user = [ZMUser fetchObjectWithRemoteIdentifier:senderID inManagedObjectContext:moc];
    // 修复通过消息sendID获取user为nil导致crash的问题，即在本地数据库中查不到该user
    NSUUID *nonce = [NSUUID uuidWithTransportString:operation.messageId];
    ZMMessage *localMessage = [ZMMessage fetchMessageWithNonce:nonce
                                               forConversation:conversation
                                        inManagedObjectContext:moc];
    [localMessage addOperation:MessageOperationTypeIllegal status:MessageOperationStatusOn byOperator:sender];
    [localMessage updateCategoryCache];
}

+ (void)removeMessageWithRemotelyDeletedMessage:(ZMMessageDelete *)deletedMessage inConversation:(ZMConversation *)conversation senderID:(NSUUID *)senderID inManagedObjectContext:(NSManagedObjectContext *)moc;
{
    NSUUID *messageID = [NSUUID uuidWithTransportString:deletedMessage.messageId];
    ZMMessage *message = [ZMMessage fetchMessageWithNonce:messageID forConversation:conversation inManagedObjectContext:moc];

    // We need to cascade delete the pending delivery confirmation messages for the message being deleted
    // 耗时操作，暂时注释
//    [message removePendingDeliveryReceipts];
    if (message.hasBeenDeleted) {
        ZMLogError(@"Attempt to delete the deleted message: %@, existing: %@", deletedMessage, message);
        return;
    }
    
    // Only the sender of the original message can delete it
    if (![senderID isEqual:message.sender.remoteIdentifier] && !message.isEphemeral) {
        return;
    }

    ZMUser *selfUser = [ZMUser selfUserInContext:moc];

    // Only clients other than self should see the system message
    if (nil != message && ![senderID isEqual:selfUser.remoteIdentifier] && !message.isEphemeral) {
        [conversation appendDeletedForEveryoneSystemMessageAt:message.serverTimestamp sender:message.sender];
    }
    // If we receive a delete for an ephemeral message that was not originally sent by the selfUser, we need to stop the deletion timer
    if (nil != message && message.isEphemeral && ![message.sender.remoteIdentifier isEqual:selfUser.remoteIdentifier]) {
        [message removeMessageClearingSender:YES];
        [self stopDeletionTimerForMessage:message];
    } else {
        [message removeMessageClearingSender:YES];
        [message updateCategoryCache];
    }
    // 耗时操作，暂时注释（触发重新统计未读消息数量操作）
//    [conversation updateTimestampsAfterDeletingMessage];
}

+ (void)stopDeletionTimerForMessage:(ZMMessage *)message
{
    NSManagedObjectContext *uiMOC = message.managedObjectContext;
    if (!uiMOC.zm_isUserInterfaceContext) {
        uiMOC = uiMOC.zm_userInterfaceContext;
    }
    NSManagedObjectID *messageID = message.objectID;
    [uiMOC performGroupedBlock:^{
        NSError *error;
        ZMMessage *uiMessage = [uiMOC existingObjectWithID:messageID error:&error];
        if (error != nil || uiMessage == nil) {
            return;
        }
        [uiMOC.zm_messageDeletionTimer stopTimerForMessage:uiMessage];
    }];
}

- (void)removePendingDeliveryReceipts
{
    // Pending receipt can exist only in new inserted messages since it is deleted locally after it is sent to the backend
    NSFetchRequest *requestForInsertedMessages = [ZMClientMessage sortedFetchRequestWithPredicate:[ZMClientMessage predicateForObjectsThatNeedToBeInsertedUpstream]];
    NSArray *possibleMatches = [self.managedObjectContext executeFetchRequestOrAssert:requestForInsertedMessages];
    
    NSArray *confirmationReceipts = [possibleMatches filterWithBlock:^BOOL(ZMClientMessage *candidateConfirmationReceipt) {
        if (candidateConfirmationReceipt.genericMessage.hasConfirmation &&
            candidateConfirmationReceipt.genericMessage.confirmation.hasFirstMessageId &&
            [candidateConfirmationReceipt.genericMessage.confirmation.firstMessageId isEqual:self.nonce.transportString]) {
            return YES;
        }
        return NO;
    }];
    
    // TODO: Re-enable
//    NSAssert(confirmationReceipts.count <= 1, @"More than one confirmation receipt");
    
    for (ZMClientMessage *confirmationReceipt in confirmationReceipts) {
        [self.managedObjectContext deleteObject:confirmationReceipt];
    }
}

- (NSUUID *)nonceFromPostPayload:(NSDictionary *)payload
{
    ZMUpdateEventType eventType = [ZMUpdateEvent updateEventTypeForEventTypeString:[payload optionalStringForKey:@"type"]];
    switch (eventType) {
            
        case ZMUpdateEventTypeConversationMessageAdd:
        case ZMUpdateEventTypeConversationKnock:
            return [[payload dictionaryForKey:@"data"] uuidForKey:@"nonce"];

        case ZMUpdateEventTypeConversationBgpMessageAdd:
        {
            NSString *base64Content = [[payload dictionaryForKey:@"data"] stringForKey: @"text"];
            ZMGenericMessage *message;
            @try {
                message = [ZMGenericMessage messageWithBase64String:base64Content];
            }
            @catch(NSException *e) {
                ZMLogError(@"Cannot create message from protobuffer: %@ event payload: %@", e, payload);
                return nil;
            }
            return [NSUUID uuidWithTransportString:message.messageId];
        }

        case ZMUpdateEventTypeConversationClientMessageAdd:
        case ZMUpdateEventTypeConversationOtrMessageAdd:
        {
            //if event is otr message then payload should be already decrypted and should contain generic message data
            NSString *base64Content = [payload stringForKey:@"data"];
            ZMGenericMessage *message;
            @try {
                message = [ZMGenericMessage messageWithBase64String:base64Content];
            }
            @catch(NSException *e) {
                ZMLogError(@"Cannot create message from protobuffer: %@ event payload: %@", e, payload);
                return nil;
            }
            return [NSUUID uuidWithTransportString:message.messageId];
        }
            
        default:
            return nil;
    }
}

- (void)updateWithPostPayload:(NSDictionary *)payload updatedKeys:(__unused NSSet *)updatedKeys
{
    NSUUID *nonce = [self nonceFromPostPayload:payload];
    if (nonce != nil && ![self.nonce isEqual:nonce]) {
        ZMLogWarn(@"send message response nonce does not match");
        return;
    }
    
    NSDate *timestamp = [payload dateFor:@"time"];
    if (timestamp == nil) {
        ZMLogWarn(@"No time in message post response from backend.");
    } else {
        self.serverTimestamp = timestamp;
    }
    
    [self.conversation updateTimestampsAfterUpdatingMessage:self];
}

- (NSString *)shortDebugDescription;
{
    // This will make "seconds since" easier to read:
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
    formatter.numberStyle = NSNumberFormatterDecimalStyle;
    formatter.usesGroupingSeparator = YES;
    
    return [NSString stringWithFormat:@"<%@: %p> id: %@, conversation: %@, nonce: %@, sender: %@, server timestamp: %@",
            self.class, self,
            self.objectID.URIRepresentation.lastPathComponent,
            self.conversation.objectID.URIRepresentation.lastPathComponent,
            [self.nonce.UUIDString.lowercaseString substringToIndex:4],
            self.sender.objectID.URIRepresentation.lastPathComponent,
            [formatter stringFromNumber:@(self.serverTimestamp.timeIntervalSinceNow)]
            ];
}

+ (instancetype)fetchMessageWithNonce:(NSUUID *)nonce
                      forConversation:(ZMConversation *)conversation
               inManagedObjectContext:(NSManagedObjectContext *)moc
{
    return [self fetchMessageWithNonce:nonce
                       forConversation:conversation
                inManagedObjectContext:moc
                        prefetchResult:nil];
}


+ (instancetype)fetchMessageWithNonce:(NSUUID *)nonce
                      forConversation:(ZMConversation *)conversation
               inManagedObjectContext:(NSManagedObjectContext *)moc
                       prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult
{
    NSSet <ZMMessage *>* prefetchedMessages = prefetchResult.messagesByNonce[nonce];
    
    if (nil != prefetchedMessages) {
        for (ZMMessage *prefetchedMessage in prefetchedMessages) {
            if ([prefetchedMessage isKindOfClass:[self class]]) {
                return prefetchedMessage;
            }
        }
    }
    
    NSEntityDescription *entity = moc.persistentStoreCoordinator.managedObjectModel.entitiesByName[self.entityName];
    NSPredicate *noncePredicate = [NSPredicate predicateWithFormat:@"%K == %@", ZMMessageNonceDataKey, [nonce data]];
    
    BOOL checkedAllHiddenMessages = NO;
    BOOL checkedAllVisibleMessage = NO;

    if (![conversation hasFaultForRelationshipNamed:ZMConversationAllMessagesKey]) {
        checkedAllVisibleMessage = YES;
        for (ZMMessage *message in conversation.allMessages) {
            if (message.isFault) {
                checkedAllVisibleMessage = NO;
            } else if ([message.entity isKindOfEntity:entity] && [noncePredicate evaluateWithObject:message]) {
                return (id) message;
            }
        }
    }
    
    if (![conversation hasFaultForRelationshipNamed:ZMConversationHiddenMessagesKey]) {
        checkedAllHiddenMessages = YES;
        for (ZMMessage *message in conversation.hiddenMessages) {
            if (message.isFault) {
                checkedAllHiddenMessages = NO;
            } else if ([message.entity isKindOfEntity:entity] && [noncePredicate evaluateWithObject:message]) {
                return (id) message;
            }
        }
    }

    if (checkedAllVisibleMessage && checkedAllHiddenMessages) {
        return nil;
    }

    NSPredicate *conversationPredicate = [NSPredicate predicateWithFormat:@"%K == %@ OR %K == %@", ZMMessageConversationKey, conversation.objectID, ZMMessageHiddenInConversationKey, conversation.objectID];
    
    NSPredicate *predicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[noncePredicate, conversationPredicate]];
    NSFetchRequest *fetchRequest = [self.class sortedFetchRequestWithPredicate:predicate];
    fetchRequest.fetchLimit = 2;
    fetchRequest.includesSubentities = YES;
    
    NSArray* fetchResult = [moc executeFetchRequestOrAssert:fetchRequest];
    VerifyString([fetchResult count] <= 1, "More than one message with the same nonce in the same conversation");
    return fetchResult.firstObject;
}


+ (NSPredicate *)predicateForMessagesThatWillExpire;
{
    return [NSPredicate predicateWithFormat:@"%K > %@ && %K == 0",
            ZMMessageExpirationDateKey,
            [NSDate dateWithTimeIntervalSince1970:0],
            ZMMessageIsExpiredKey];
}


+ (BOOL)doesEventTypeGenerateMessage:(ZMUpdateEventType)type;
{
    return
        (type == ZMUpdateEventTypeConversationAssetAdd) ||
        (type == ZMUpdateEventTypeConversationMessageAdd) ||
        (type == ZMUpdateEventTypeConversationClientMessageAdd) ||
        (type == ZMUpdateEventTypeConversationOtrMessageAdd) ||
        (type == ZMUpdateEventTypeConversationOtrAssetAdd) ||
        (type == ZMUpdateEventTypeConversationKnock) ||
        [ZMSystemMessage doesEventTypeGenerateSystemMessage:type];
}


+ (instancetype)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent *__unused)updateEvent
                              inManagedObjectContext:(NSManagedObjectContext *__unused)moc
                                      prefetchResult:(__unused ZMFetchRequestBatchResult *)prefetchResult
{
    NSAssert(FALSE, @"Subclasses should override this method: [%@ %@]", NSStringFromClass(self), NSStringFromSelector(_cmd));
    return nil;
}

+ (NSPredicate *)predicateForMessageInConversation:(ZMConversation *)conversation withNonces:(NSSet<NSUUID *> *)nonces;
{
    NSPredicate *conversationPredicate = [NSPredicate predicateWithFormat:@"%K == %@ OR %K == %@", ZMMessageConversationKey, conversation.objectID, ZMMessageHiddenInConversationKey, conversation.objectID];
    NSSet *noncesData = [nonces mapWithBlock:^NSData*(NSUUID *uuid) {
        return uuid.data;
    }];
    NSPredicate *noncePredicate = [NSPredicate predicateWithFormat:@"%K IN %@", noncesData];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[conversationPredicate, noncePredicate]];
}

+ (NSPredicate *)predicateForMessagesThatNeedToUpdateLinkAttachments
{
    return [NSPredicate predicateWithFormat:@"(%K == YES)", ZMMessageNeedsLinkAttachmentsUpdateKey];
}

+ (NSSet <ZMMessage *> *)messagesWithRemoteIDs:(NSSet <NSUUID *>*)UUIDs inContext:(NSManagedObjectContext *)moc;
{
    return [self fetchObjectsWithRemoteIdentifiers:UUIDs inManagedObjectContext:moc];
}

+(NSString *)remoteIdentifierDataKey {
    return ZMMessageNonceDataKey;
}

@end



@implementation ZMMessage (PersistentChangeTracking)

+ (NSPredicate *)predicateForObjectsThatNeedToBeInsertedUpstream;
{
    return [NSPredicate predicateWithValue:NO];
}

- (NSSet *)ignoredKeys;
{
    static NSSet *ignoredKeys;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSSet *keys = [super ignoredKeys];
        NSArray *newKeys = @[
                             ZMMessageConversationKey,
                             ZMMessageExpirationDateKey,
                             ZMMessageImageTypeKey,
                             ZMMessageIsAnimatedGifKey,
                             ZMMessageMediumRemoteIdentifierDataKey,
                             ZMMessageNameKey,
                             ZMMessageNonceDataKey,
                             ZMMessageOriginalDataProcessedKey,
                             ZMMessageOriginalSizeDataKey,
                             ZMMessageSenderKey,
                             ZMMessageServerTimestampKey,
                             ZMMessageSystemMessageTypeKey,
                             ZMMessageTextKey,
                             ZMMessageJsonTextKey,
                             ZMMessageUserIDsKey,
                             ZMMessageEventIDDataKey,
                             ZMMessageUsersKey,
                             ZMMessageClientsKey,
                             ZMMessageHiddenInConversationKey,
                             ZMMessageMissingRecipientsKey,
                             ZMMessageMediumDataLoadedKey,
                             ZMMessageAddedUsersKey,
                             ZMMessageRemovedUsersKey,
                             ZMMessageNeedsUpdatingUsersKey,
                             ZMMessageSenderClientIDKey,
                             ZMMessageConfirmationKey,
                             ZMMessageReactionKey,
                             ZMMessageOperationKey,
                             ZMMessageDestructionDateKey,
                             ZMMessageIsObfuscatedKey,
                             ZMMessageCachedCategoryKey,
                             ZMMessageNormalizedTextKey,
                             ZMMessageDurationKey,
                             ZMMessageChildMessagesKey,
                             ZMMessageParentMessageKey,
                             ZMMessageRepliesKey,
                             ZMMessageQuoteKey,
                             ZMSystemMessageMessageTimerKey,
                             ZMSystemMessageRelevantForConversationStatusKey,
                             ZMSystemMessageAllTeamUsersAddedKey,
                             ZMSystemMessageNumberOfGuestsAddedKey,
                             DeliveredKey,
                             ZMMessageExpectReadConfirmationKey,
                             ZMMessageLinkAttachmentsKey,
                             ZMMessageNeedsLinkAttachmentsUpdateKey,
                             ZMMessageDiscoveredClientsKey
                             ];
        ignoredKeys = [keys setByAddingObjectsFromArray:newKeys];
    });
    return ignoredKeys;
}

@end



#pragma mark - Text message

@implementation ZMTextMessage

@dynamic text;

+ (NSString *)entityName;
{
    return @"TextMessage";
}

- (NSString *)shortDebugDescription;
{
    return [[super shortDebugDescription] stringByAppendingFormat:@", \'%@\'", self.text];
}

+ (instancetype)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent __unused *)updateEvent
                              inManagedObjectContext:(NSManagedObjectContext __unused *)moc
                                      prefetchResult:(ZMFetchRequestBatchResult __unused *)prefetchResult
{
    return nil;
}

- (NSString *)messageText
{
    return self.text;
}

- (LinkMetadata *)linkPreview
{
    return nil;
}

- (id<ZMTextMessageData>)textMessageData
{
    return self;
}

- (NSData *)linkPreviewImageData
{
    return nil;
}

- (BOOL)linkPreviewHasImage
{
    return NO;
}

- (NSString *)linkPreviewImageCacheKey
{
    return nil;
}

- (NSArray<Mention *> *)mentions
{
    return @[];
}

- (ZMMessage *)quote
{
    return nil;
}

-(NSSet<ZMMessage *> *)replies
{
    return [NSSet set];
}

-(BOOL)hasQuote
{
    return NO;
}

-(BOOL)isQuotingSelf
{
    return NO;
}

- (void)removeMessageClearingSender:(BOOL)clearingSender
{
    self.text = nil;
    [super removeMessageClearingSender:clearingSender];
}

- (void)fetchLinkPreviewImageDataWithQueue:(dispatch_queue_t)queue completionHandler:(void (^)(NSData *))completionHandler
{
    NOT_USED(queue);
    NOT_USED(completionHandler);
}

- (void)requestLinkPreviewImageDownload
{
    
}

- (void)editText:(NSString *)text mentions:(NSArray<Mention *> *)mentions fetchLinkPreview:(BOOL)fetchLinkPreview
{
    NOT_USED(text);
    NOT_USED(mentions);
    NOT_USED(fetchLinkPreview);
}

@end

#pragma mark - JsonText message

@implementation ZMJsonTextMessage

@dynamic text;


+ (NSString *)entityName;
{
    return @"JsonTextMessage";
}

- (NSString *)shortDebugDescription;
{
    return [[super shortDebugDescription] stringByAppendingFormat:@", \'%@\'", self.text];
}

+ (instancetype)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent  __unused *)updateEvent
                              inManagedObjectContext:(NSManagedObjectContext  __unused *)moc
                                      prefetchResult:(ZMFetchRequestBatchResult  __unused *)prefetchResult
{
    return nil;
}

- (NSString *)jsonMessageText
{
    return self.text;
}

- (id<ZMJsonTextMessageData>)jsonTextMessageData
{
    return self;
}

- (void)removeMessageClearingSender:(BOOL)clearingSender
{
    self.text = nil;
    [super removeMessageClearingSender:clearingSender];
}

- (ZMDeliveryState)deliveryState
{
    return ZMDeliveryStateDelivered;
}

@end



# pragma mark - Knock message

@implementation ZMKnockMessage

+ (NSString *)entityName;
{
    return @"KnockMessage";
}

+ (instancetype)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent __unused *)updateEvent
                              inManagedObjectContext:(NSManagedObjectContext __unused *)moc
                                      prefetchResult:(ZMFetchRequestBatchResult __unused *)prefetchResult
{
    return nil;
}

- (id<ZMKnockMessageData>)knockMessageData
{
    return self;
}

@end



# pragma mark - System message

@implementation ZMSystemMessage

@dynamic text;

+ (NSString *)entityName;
{
    return @"SystemMessage";
}

@dynamic systemMessageType;
@dynamic users;
@dynamic clients;
@dynamic addedUsers;
@dynamic removedUsers;
@dynamic needsUpdatingUsers;
@dynamic isService;
@dynamic duration;
@dynamic childMessages;
@dynamic parentMessage;
@dynamic messageTimer;
@dynamic blockTime;
@dynamic blockDuration;
@dynamic opt_id;
@dynamic serviceMessage;
@dynamic blockUser;
@dynamic add_friend;
@dynamic messageVisible;
@dynamic managerType;
@dynamic relevantForConversationStatus;
@dynamic userIDs;
@dynamic userNames;

- (instancetype)initWithNonce:(NSUUID *)nonce managedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:[self.class entityName] inManagedObjectContext:managedObjectContext];
    self = [super initWithEntity:entity insertIntoManagedObjectContext:managedObjectContext];
    
    if (self != nil) {
        self.nonce = nonce;
        self.relevantForConversationStatus = YES; //default value
    }
    
    return self;
}
    
+(BOOL)vertifyIfCanCreateSystemMessageWithType:(ZMSystemMessageType)type
                                          updateEvent:(ZMUpdateEvent *)updateEvent
                                          inConversation:(ZMConversation *)conversation
                                          inManagedObjectContext:(NSManagedObjectContext *)moc {
    BOOL isSelfSend = [[[updateEvent.payload optionalDictionaryForKey:@"data"] optionalStringForKey:@"from"] isEqualToString:[ZMUser selfUserInContext:moc].remoteIdentifier.transportString];
    switch (type) {
        case ZMSystemMessageTypeServiceMessage:
        case ZMUpdateEventTypeConversationAppMessageAdd:
        {
            return !isSelfSend;
        }
        case ZMSystemMessageTypeCreatorChangeMsg:
        {
            NSString * opt_id = [[updateEvent.payload optionalDictionaryForKey:@"data"] optionalStringForKey:@"opt_id"];
            NSString * new_creator = [[updateEvent.payload optionalDictionaryForKey:@"data"] optionalStringForKey:@"new_creator"];
            return ![opt_id isEqualToString:new_creator];
        }
        case ZMSystemMessageTypeParticipantsAdded:
        case ZMSystemMessageTypeParticipantsRemoved:
        {
            // 由于万人群会多推送一条加减人消息，此处取消请求返回的系统消息
            if (updateEvent.source == ZMUpdateEventSourceDownload && conversation.conversationType == ZMConversationTypeHugeGroup) {
                return false;
            }
            NSArray * userids = [[updateEvent.payload dictionaryForKey:@"data"] optionalArrayForKey:@"user_ids"];
            // 当添加或者删除成员是，若群变动不可见，也不是群主和管理员，且加人信息里不包含自己。该系统消息不需要入库
            if (!conversation.isVisibleForMemberChange &&
                !conversation.creator.isSelfUser &&
                ![conversation.manager containsObject:[ZMUser selfUserInContext: moc].remoteIdentifier.transportString] &&
                ![userids containsObject:[ZMUser selfUserInContext: moc].remoteIdentifier.transportString]) {
                return false;
            }
        }
        default:
            return true;
    }
}
    
+(void)fillSystemMessageWithSystemMessage:(ZMSystemMessage *)systemMessage
                            updateEvent:(ZMUpdateEvent *)updateEvent
                            inConversation:(ZMConversation *)conversation
                            inManagedObjectContext:(NSManagedObjectContext *)moc {
    
    switch (systemMessage.systemMessageType) {
        case ZMSystemMessageTypeAllDisableSendMsg:
        case ZMSystemMessageTypeMemberDisableSendMsg:
        {
            systemMessage.blockTime = [[updateEvent.payload optionalDictionaryForKey:@"data"] optionalNumberForKey:ZMConversationInfoBlockTimeKey];
            systemMessage.blockUser = [[updateEvent.payload optionalDictionaryForKey:@"data"] optionalStringForKey:ZMConversationInfoBlockUserKey];
            systemMessage.blockDuration = [[updateEvent.payload optionalDictionaryForKey:@"data"] optionalNumberForKey:ZMConversationInfoBlockDurationKey];
            systemMessage.opt_id = [[updateEvent.payload optionalDictionaryForKey:@"data"] optionalStringForKey:ZMConversationInfoOpt_idKey];
            break;
        }
        case ZMSystemMessageTypeAllowAddFriend:
        {
            systemMessage.add_friend = [[[updateEvent.payload optionalDictionaryForKey:@"data"] optionalNumberForKey:ZMConversationInfoIsAllowMemberAddEachOtherKey] stringValue];
            break;
        }
        case ZMSystemMessageTypeMessageVisible:
        {
            systemMessage.messageVisible = [[[updateEvent.payload optionalDictionaryForKey:@"data"] optionalNumberForKey:ZMConversationInfoIsMessageVisibleOnlyManagerAndCreatorKey] stringValue];
            break;
        }
        case ZMSystemMessageTypeServiceMessage:
        {
            ServiceMessage *serviceMessage = [ServiceMessage insertNewObjectInManagedObjectContext:moc];
            [serviceMessage configDataWith:[updateEvent.payload optionalDictionaryForKey:@"data"]];
            if ([serviceMessage.type isEqualToString:@"20009"]) {
                if (conversation.blockWarningMessage != nil) {
                    ///将之前的消息从表中删除
                    ZMSystemMessage * sysMessage = conversation.blockWarningMessage.systemMessage;
                    if (sysMessage != NULL) {
                        [moc deleteObject:sysMessage];
                        [moc deleteObject:conversation.blockWarningMessage];
                    }
                }
                conversation.blockWarningMessage = serviceMessage;
                ///这里的时间戳是用来监听 blockWarningMessage 属性改变用的
                conversation.blockWarningMessageTimeStamp = [updateEvent.payload dateFor:@"time"];
            } else {
                if (conversation.lastServiceMessage != nil) {
                    ///将之前的消息从表中删除
                    ZMSystemMessage * sysMessage = conversation.lastServiceMessage.systemMessage;
                    if (sysMessage != NULL) {
                        [moc deleteObject:sysMessage];
                        [moc deleteObject:conversation.lastServiceMessage];
                    }
                }
                conversation.lastServiceMessage = serviceMessage;
                ///这里的时间戳是用来监听 lastServiceMessage 属性改变用的
                conversation.lastServiceMessageTimeStamp = [updateEvent.payload dateFor:@"time"];
            }
            systemMessage.serviceMessage = serviceMessage;
            systemMessage.isService = YES;
            systemMessage.hiddenInConversation = conversation;
            systemMessage.visibleInConversation = nil;
            break;
        }
        case ZMSystemMessageTypeParticipantsAdded:
        case ZMSystemMessageTypeParticipantsRemoved:
        {
            NSArray * userNamesSet = [[updateEvent.payload dictionaryForKey:@"data"] optionalArrayForKey:@"user_names"];
            systemMessage.userNames = userNamesSet;
            NSOrderedSet * userIDsSet = [[updateEvent.payload dictionaryForKey:@"data"] optionalArrayForKey:@"user_ids"].orderedSet;
            systemMessage.userIDs = userIDsSet;
            ///万人群加人删人都不需要走到最后对user赋值那里
            if (conversation.conversationType == ZMConversationTypeHugeGroup) {
                return;
            }
            break;
        }
        default:
            break;
    }
    
    ///对user进行赋值
    NSMutableSet *usersSet = [NSMutableSet set];
    for(NSString *userId in [[updateEvent.payload dictionaryForKey:@"data"] optionalArrayForKey:@"user_ids"]) {
        ZMUser *user = [ZMUser userWithRemoteID:[NSUUID uuidWithTransportString:userId] createIfNeeded:YES inConversation:conversation inContext:moc];
        [usersSet addObject:user];
    }
    systemMessage.users = usersSet;
}

+ (instancetype)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent
                              inManagedObjectContext:(NSManagedObjectContext *)moc
                                      prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult
{
    ZMSystemMessageType type = [self.class systemMessageTypeFromEvent:updateEvent];
    if (type == ZMSystemMessageTypeInvalid) {
        return nil;
    }
    
    ZMConversation *conversation = [self conversationForUpdateEvent:updateEvent inContext:moc prefetchResult:prefetchResult];
    VerifyReturnNil(conversation != nil);
    
    // Only create connection request system message if conversation type is valid.
    // Note: if type is not connection request, then it relates to group conversations (see first line of this method).
    // We don't explicitly check for group conversation type b/c if this is the first time we were added to the conversation,
    // then the default conversation type is `invalid` (b/c we haven't fetched from BE yet), so we assume BE sent the
    // update event for a group conversation.
    if (conversation.conversationType == ZMConversationTypeConnection && type != ZMSystemMessageTypeConnectionRequest) {
        return nil;
    }
    
    ///创建系统消息之前先进行校验
    if (![self vertifyIfCanCreateSystemMessageWithType:type updateEvent:updateEvent inConversation:conversation inManagedObjectContext:moc]) {
        return nil;
    }
    
    ///创建系统消息并配置基本信息
    ZMSystemMessage *message = [[ZMSystemMessage alloc] initWithNonce:NSUUID.UUID managedObjectContext:moc];
    message.systemMessageType = type;
    message.visibleInConversation = conversation;
    message.serverTimestamp = updateEvent.timeStamp;
    NSString *messageText = [[[updateEvent.payload dictionaryForKey:@"data"] optionalStringForKey:@"message"] stringByRemovingExtremeCombiningCharacters];
    NSString *name = [[[updateEvent.payload dictionaryForKey:@"data"] optionalStringForKey:@"name"] stringByRemovingExtremeCombiningCharacters];
    message.text = messageText != nil ? messageText : name;
    
    [message updateWithUpdateEvent:updateEvent forConversation:conversation];
    
    ///针对特殊系统消息类型填充不同的数据
    [self fillSystemMessageWithSystemMessage:message updateEvent:updateEvent inConversation:conversation inManagedObjectContext:moc];
    
    [conversation updateTimestampsAfterUpdatingMessage:message];
    return message;
}

- (NSDictionary<NSString *,NSArray<ZMUser *> *> *)usersReaction
{
    return [NSDictionary dictionary];
}

+ (ZMSystemMessage *)fetchLatestPotentialGapSystemMessageInConversation:(ZMConversation *)conversation
{
    NSFetchRequest *request = [NSFetchRequest fetchRequestWithEntityName:[self entityName]];
    request.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:ZMMessageServerTimestampKey ascending:NO]];
    request.fetchBatchSize = 1;
    request.predicate = [self predicateForPotentialGapSystemMessagesNeedingUpdatingUsersInConversation:conversation];
    NSArray *result = [conversation.managedObjectContext executeFetchRequestOrAssert:request];
    return result.firstObject;
}

+ (NSPredicate *)predicateForPotentialGapSystemMessagesNeedingUpdatingUsersInConversation:(ZMConversation *)conversation
{
    NSPredicate *conversationPredicate = [NSPredicate predicateWithFormat:@"%K == %@", ZMMessageConversationKey, conversation];
    NSPredicate *missingMessagesTypePredicate = [NSPredicate predicateWithFormat:@"%K == %@", ZMMessageSystemMessageTypeKey, @(ZMSystemMessageTypePotentialGap)];
    NSPredicate *needsUpdatingUsersPredicate = [NSPredicate predicateWithFormat:@"%K == YES", ZMMessageNeedsUpdatingUsersKey];
    return [NSCompoundPredicate andPredicateWithSubpredicates:@[conversationPredicate, missingMessagesTypePredicate, needsUpdatingUsersPredicate]];
}

+ (NSPredicate *)predicateForSystemMessagesInsertedLocally
{
    return [NSPredicate predicateWithBlock:^BOOL(ZMSystemMessage *msg, id ZM_UNUSED bindings) {
        if (![msg isKindOfClass:[ZMSystemMessage class]]){
            return NO;
        }
        switch (msg.systemMessageType) {
            case ZMSystemMessageTypeNewClient:
            case ZMSystemMessageTypePotentialGap:
            case ZMSystemMessageTypeIgnoredClient:
            case ZMSystemMessageTypePerformedCall:
            case ZMSystemMessageTypeUsingNewDevice:
            case ZMSystemMessageTypeDecryptionFailed:
            case ZMSystemMessageTypeReactivatedDevice:
            case ZMSystemMessageTypeConversationIsSecure:
            case ZMSystemMessageTypeMessageDeletedForEveryone:
            case ZMSystemMessageTypeDecryptionFailed_RemoteIdentityChanged:
            case ZMSystemMessageTypeTeamMemberLeave:
            case ZMSystemMessageTypeMissedCall:
            case ZMSystemMessageTypeReadReceiptsEnabled:
            case ZMSystemMessageTypeReadReceiptsDisabled:
            case ZMSystemMessageTypeReadReceiptsOn:
            case ZMSystemMessageTypeLegalHoldEnabled:
            case ZMSystemMessageTypeLegalHoldDisabled:
                return YES;
            case ZMSystemMessageTypeInvalid:
            case ZMSystemMessageTypeConversationNameChanged:
            case ZMSystemMessageTypeConnectionRequest:
            case ZMSystemMessageTypeConnectionUpdate:
            case ZMSystemMessageTypeNewConversation:
            case ZMSystemMessageTypeParticipantsAdded:
            case ZMSystemMessageTypeParticipantsRemoved:
            case ZMSystemMessageTypeMessageTimerUpdate:
            case ZMSystemMessageTypeAllDisableSendMsg:
            case ZMSystemMessageTypeMemberDisableSendMsg:
            case ZMSystemMessageTypeManagerMsg:
            case ZMSystemMessageTypeCreatorChangeMsg:
            case ZMSystemMessageTypeServiceMessage:
            case ZMSystemMessageTypeAllowAddFriend:
            case ZMSystemMessageTypeMessageVisible:
                return NO;
        }
    }];
}

- (void)updateNeedsUpdatingUsersIfNeeded
{
    if (self.systemMessageType == ZMSystemMessageTypePotentialGap && self.needsUpdatingUsers == YES) {
        BOOL (^matchUnfetchedUserBlock)(ZMUser *) = ^BOOL(ZMUser *user) {
            return user.name == nil;
        };
        
        self.needsUpdatingUsers = [self.addedUsers anyObjectMatchingWithBlock:matchUnfetchedUserBlock] ||
                                  [self.removedUsers anyObjectMatchingWithBlock:matchUnfetchedUserBlock];
    }
}

+ (ZMSystemMessageType)systemMessageTypeFromEvent:(ZMUpdateEvent *)event
{
    ZMUpdateEventType type = event.type;
    NSNumber *number = self.eventTypeToSystemMessageTypeMap[@(type)];
    if (type == ZMUpdateEventTypeConversationUpdate && [[event.payload optionalDictionaryForKey:@"data"].allKeys containsObject:ZMConversationInfoBlockTimeKey]) {
        number = @(ZMSystemMessageTypeAllDisableSendMsg);
    }
    if (type == ZMUpdateEventTypeConversationUpdateBlockTime && [[event.payload optionalDictionaryForKey:@"data"].allKeys containsObject:ZMConversationInfoBlockTimeKey]) {
        number = @(ZMSystemMessageTypeMemberDisableSendMsg);
    }
    if (type == ZMUpdateEventTypeConversationUpdate && [[event.payload optionalDictionaryForKey:@"data"].allKeys containsObject:ZMConversationInfoManagerKey]) {
        number = @(ZMSystemMessageTypeManagerMsg);
    }
    if (type == ZMUpdateEventTypeConversationUpdate && [[event.payload optionalDictionaryForKey:@"data"].allKeys containsObject:ZMConversationInfoOTRCreatorChangeKey]) {
        number = @(ZMSystemMessageTypeCreatorChangeMsg);
    }
    if (type == ZMUpdateEventTypeConversationUpdate && [[event.payload optionalDictionaryForKey:@"data"].allKeys containsObject:ZMConversationInfoIsAllowMemberAddEachOtherKey]) {
        number = @(ZMSystemMessageTypeAllowAddFriend);
    }
    if (type == ZMUpdateEventTypeConversationUpdate && [[event.payload optionalDictionaryForKey:@"data"].allKeys containsObject:ZMConversationInfoIsMessageVisibleOnlyManagerAndCreatorKey]) {
        number = @(ZMSystemMessageTypeMessageVisible);
    }
    if(number == nil) {
        return ZMSystemMessageTypeInvalid;
    }
    else {
        return (ZMSystemMessageType) number.integerValue;
    }
}

+ (BOOL)doesEventTypeGenerateSystemMessage:(ZMUpdateEventType)type;
{
    return [self.eventTypeToSystemMessageTypeMap.allKeys containsObject:@(type)];
}

+ (NSDictionary *)eventTypeToSystemMessageTypeMap   
{
    return @{
             @(ZMUpdateEventTypeConversationMemberJoin) : @(ZMSystemMessageTypeParticipantsAdded),
             @(ZMUpdateEventTypeConversationMemberLeave) : @(ZMSystemMessageTypeParticipantsRemoved),
             @(ZMUpdateEventTypeConversationRename) : @(ZMSystemMessageTypeConversationNameChanged),
             @(ZMUpdateEventTypeConversationAppMessageAdd) : @(ZMSystemMessageTypeServiceMessage)
             };
}

- (id<ZMSystemMessageData>)systemMessageData
{
    return self;
}

///这是改变当前群LastModified属性，由于conversation的排序条件是LastModified，所以此处需要判断是否刷新当前群
- (BOOL)shouldUpdateLastModified;
{
    switch (self.systemMessageType) {
        case ZMSystemMessageTypeParticipantsRemoved:
        case ZMSystemMessageTypeParticipantsAdded:
        {
            ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
            return [self.users containsObject:selfUser] && !self.sender.isSelfUser;
        }
        case ZMSystemMessageTypeNewConversation:
            return !self.sender.isSelfUser;
        case ZMSystemMessageTypeMissedCall:
        case ZMSystemMessageTypeServiceMessage:
            return YES;
        default:
            return NO;
    }
}

- (BOOL)shouldGenerateUnreadCount;
{
    switch (self.systemMessageType) {
        case ZMSystemMessageTypeParticipantsRemoved:
        case ZMSystemMessageTypeParticipantsAdded:
        {
            ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
            return [self.users containsObject:selfUser] && !self.sender.isSelfUser;
        }
        case ZMSystemMessageTypeNewConversation:
            return !self.sender.isSelfUser;
        case ZMSystemMessageTypeMissedCall:
        case ZMSystemMessageTypeServiceMessage:
            return YES;
        default:
            return NO;
    }
}

- (BOOL)shouldGenerateFirstUnread;
{
    switch (self.systemMessageType) {
        case ZMSystemMessageTypeParticipantsRemoved:
        case ZMSystemMessageTypeParticipantsAdded:
        {
            ZMUser *selfUser = [ZMUser selfUserInContext:self.managedObjectContext];
            return [self.users containsObject:selfUser] && !self.sender.isSelfUser;
        }
        case ZMSystemMessageTypeMissedCall:
            return YES;
        default:
            return NO;
    }
}

- (BOOL)shouldGenerateLastVisibleMessage;
{
    switch (self.systemMessageType) {
        case ZMSystemMessageTypePotentialGap:
        case ZMSystemMessageTypeServiceMessage:
            return NO;
        default:
            return YES;
    }
}

- (BOOL)userIsTheSender
{
    ///在万人群加人删人的时候，users不会被赋值，只保存userIDs
    if (self.conversation.conversationType == ZMConversationTypeHugeGroup && self.userIDs) {
        BOOL onlyOneUser = self.userIDs.count == 1;
        BOOL isSender = [self.userIDs containsObject:self.sender.remoteIdentifier.transportString];
        return onlyOneUser && isSender;
    } else {
        BOOL onlyOneUser = self.users.count == 1;
        BOOL isSender = [self.users containsObject:self.sender];
        return onlyOneUser && isSender;
    }
}

- (void)updateQuoteRelationships
{
    // System messages don't support quotes at the moment
}

@end




@implementation ZMMessage (Ephemeral)


- (BOOL)startDestructionIfNeeded
{
    if (self.destructionDate != nil || !self.isEphemeral) {
        return NO;
    }
    BOOL isSelfUser = self.sender.isSelfUser;
    if (isSelfUser && self.managedObjectContext.zm_isSyncContext) {
        self.destructionDate = [NSDate dateWithTimeIntervalSinceNow:self.deletionTimeout];
        ZMMessageDestructionTimer *timer = self.managedObjectContext.zm_messageObfuscationTimer;
        if (timer != nil) { 
            [timer startObfuscationTimerWithMessage:self timeout:self.deletionTimeout];
            return YES;
        } else {
            return NO;
        }
    }
    else if (!isSelfUser && self.managedObjectContext.zm_isUserInterfaceContext){
        ZMMessageDestructionTimer *timer = self.managedObjectContext.zm_messageDeletionTimer;
        if (timer != nil) { 
            NSTimeInterval matchedTimeInterval = [timer startDeletionTimerWithMessage:self timeout:self.deletionTimeout];
            self.destructionDate = [NSDate dateWithTimeIntervalSinceNow:matchedTimeInterval];
            return YES;
        } else {
            return NO;
        }
    }
    return NO;
}

- (void)obfuscate;
{
    ZMLogDebug(@"obfuscating message %@", self.nonce.transportString);
    self.isObfuscated = YES;
    self.destructionDate = nil;
}

- (void)deleteEphemeral;
{
    ZMLogDebug(@"deleting ephemeral %@", self.nonce.transportString);
    if (self.conversation.conversationType != ZMConversationTypeGroup &&
        self.conversation.conversationType != ZMConversationTypeHugeGroup) {
        self.destructionDate = nil;
    }
    [ZMMessage deleteForEveryone:self];
    self.isObfuscated = NO;
}

+ (NSFetchRequest *)fetchRequestForEphemeralMessagesThatNeedToBeDeleted
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:self.entityName];
    fetchRequest.predicate = [NSPredicate predicateWithFormat:@"%K != nil AND %K != nil AND %K == FALSE AND (hiddenInConversation.conversationType != 5 OR visibleInConversation.conversationType != 5)",
                              ZMMessageDestructionDateKey,          // If it has a destructionDate, the timer did not fire in time
                              ZMMessageSenderKey,                   // As soon as the message is deleted, we would delete the sender
                              ZMMessageIsObfuscatedKey];            // If the message is obfuscated, we don't need to obfuscate it again
    
    // We add a sort descriptor to force core data to scan the table using the destructionDate index.
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:ZMMessageDestructionDateKey ascending:NO]];
    return fetchRequest;
}

+ (void)deleteOldEphemeralMessages:(NSManagedObjectContext *)context
{
    ZMLogDebug(@"deleting old ephemeral messages");
    NSFetchRequest *request = [self fetchRequestForEphemeralMessagesThatNeedToBeDeleted];
    NSArray *messages = [context executeFetchRequestOrAssert:request];
    
    for (ZMMessage *message in messages) {
        NSTimeInterval timeToDeletion = [message.destructionDate timeIntervalSinceNow];
        if (timeToDeletion > 0) {
            // The timer has not run out yet, we want to start a timer with the remaining time
            if (message.sender.isSelfUser) {
                [message restartObfuscationTimer:timeToDeletion];
            } else {
                [message restartDeletionTimer:timeToDeletion];
            }
        } else {
            // The timer has run out, we want to delete the message or obfuscate if we are the sender
            if (message.sender.isSelfUser) {
                // message needs to be obfuscated
                [message obfuscate];
            } else {
                [message deleteEphemeral];
            }
        }
    }
}

- (void)restartDeletionTimer:(NSTimeInterval)remainingTime
{
    NSManagedObjectContext *uiContext = self.managedObjectContext;
    if (!uiContext.zm_isUserInterfaceContext) {
        uiContext = self.managedObjectContext.zm_userInterfaceContext;
    }
    [uiContext performGroupedBlock:^{
        NSError *error;
        ZMMessage *message = [uiContext existingObjectWithID:self.objectID error:&error];
        if (error == nil && message != nil) {
            [uiContext.zm_messageDeletionTimer stopTimerForMessage:message];
            NOT_USED([uiContext.zm_messageDeletionTimer startDeletionTimerWithMessage:message timeout:remainingTime]);
        }
    }];
}

- (void)restartObfuscationTimer:(NSTimeInterval)remainingTime
{
    NSManagedObjectContext *syncContext = self.managedObjectContext;
    if (!syncContext.zm_isSyncContext) {
        syncContext = self.managedObjectContext.zm_syncContext;
    }
    [syncContext performGroupedBlock:^{
        NSError *error;
        ZMMessage *message = [syncContext existingObjectWithID:self.objectID error:&error];
        if (error == nil && message != nil) {
            [syncContext.zm_messageObfuscationTimer stopTimerForMessage:message];
            NOT_USED([syncContext.zm_messageObfuscationTimer startObfuscationTimerWithMessage:message timeout:remainingTime]);
        }
    }];
}

@end

