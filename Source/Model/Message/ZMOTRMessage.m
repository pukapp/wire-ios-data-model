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


#import "ZMOTRMessage.h"
#import "ZMGenericMessage+UpdateEvent.h"
#import "ZMConversation+Internal.h"
#import "ZMConversation+Transport.h"
#import <WireDataModel/WireDataModel-Swift.h>
#import "ZMGenericMessageData.h"


@import WireTransport;


NSString * const DeliveredKey = @"delivered";


@implementation ZMOTRMessage

@dynamic dataSet;
@dynamic missingRecipients;

- (NSString *)entityName;
{
    NSAssert(FALSE, @"Subclasses should override this method: [%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    return nil;
}

- (NSSet *)ignoredKeys;
{
    NSSet *keys = [super ignoredKeys];
    return [keys setByAddingObjectsFromArray:@[DeliveredKey, ZMMessageIsExpiredKey]];
}

- (void)missesRecipient:(UserClient *)recipient
{
    [self missesRecipients:[NSSet setWithObject:recipient]];
}

- (void)missesRecipients:(NSSet<UserClient *> *)recipients
{
    [[self mutableSetValueForKey:ZMMessageMissingRecipientsKey] addObjectsFromArray:recipients.allObjects];
}

- (void)doesNotMissRecipient:(UserClient *)recipient
{
    [self doesNotMissRecipients:[NSSet setWithObject:recipient]];
}

- (void)doesNotMissRecipients:(NSSet<UserClient *> *)recipients
{
    [[self mutableSetValueForKey:ZMMessageMissingRecipientsKey] minusSet:recipients];
}

- (ZMDeliveryState)deliveryState
{
    //we set server time stamp in awake from insert to be able to sort messages
    //probably we need to store "deliveryTimestamp" separately and check it here
    if (self.isExpired) {
        return ZMDeliveryStateFailedToSend;
    }
    else if (self.delivered == NO) {
        return ZMDeliveryStatePending;
    }
    else if (self.readReceipts.count > 0) {
        return ZMDeliveryStateRead;
    }
    else if (self.confirmations.count > 0){
        return ZMDeliveryStateDelivered;
    }
    else {
        return ZMDeliveryStateSent;
    }
}

- (BOOL)isSent
{
    return self.delivered;
}

+ (NSSet *)keyPathsForValuesAffectingDeliveryState;
{
    return [[ZMMessage keyPathsForValuesAffectingValueForKey:ZMMessageDeliveryStateKey] setByAddingObject:DeliveredKey];
}

- (NSString *)dataSetDebugInformation
{
    return [[self.dataSet mapWithBlock:^NSString *(ZMGenericMessageData *msg) {
        return [NSString stringWithFormat:@"<%@>: %@", NSStringFromClass(ZMGenericMessageData.class), msg.genericMessage];
    }].array componentsJoinedByString:@"\n"];
}

- (void)markAsSent
{
    self.delivered = YES;
    [super markAsSent];
}

- (void)expire
{
    [super expire];
}

- (void)resend
{
    self.delivered = NO;
    [super resend];
}

- (ZMGenericMessage *)genericMessage
{
    NSAssert(FALSE, @"Subclasses should override this method: [%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
    return nil;
}

- (void)updateWithGenericMessage:(__unused ZMGenericMessage *)message updateEvent:(__unused ZMUpdateEvent *)updateEvent initialUpdate:(__unused BOOL)initialUpdate
{
    NSAssert(FALSE, @"Subclasses should override this method: [%@ %@]", NSStringFromClass([self class]), NSStringFromSelector(_cmd));
}
    
+ (instancetype)createOrUpdateMessageFromUpdateEvent:(ZMUpdateEvent *)updateEvent
                              inManagedObjectContext:(NSManagedObjectContext *)moc
                                      prefetchResult:(ZMFetchRequestBatchResult *)prefetchResult
{
    ZMGenericMessage *message;
    @try {
        message = [ZMGenericMessage genericMessageFromUpdateEvent:updateEvent];
    }
    @catch(NSException *e) {
        ZMLogError(@"Cannot create message from protobuffer: %@", e);
        message = nil;
    }
    
    // 与自己无关的币币兑换、红包消息不入库
    if (message.hasTextJson){
        NSString *jsonText = message.textJson.content;
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:[jsonText dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:nil];
        if ([@"4" isEqualToString:dic[@"msgType"]] || [@"6" isEqualToString:dic[@"msgType"]]){
            NSDictionary *data = dic[@"msgData"];
            NSString *sender = data[@"sendUserId"];
            NSString *receiver = data[@"receiveUserId"];
            ZMUser *user = [ZMUser selfUserInContext:moc];
            NSString *selfId = user.remoteIdentifier.transportString;
            if (![selfId isEqualToString:sender]  && ![selfId isEqualToString:receiver]){
                return nil;
            }
        }
        if ([@"4" isEqualToString:dic[@"msgType"]]) {
            NSDictionary *data = dic[@"msgData"];
            NSString *messageId = [data optionalStringForKey:@"messageId"];
            if (messageId && messageId.length > 0) {
                ZMMessage *mes = [ZMMessage fetchObjectWithRemoteIdentifier:[NSUUID uuidWithTransportString:messageId] inManagedObjectContext:moc];
                mes.bibiCashType = ZMBiBiCashTypeGotten;
            }
        }
    }

    ZMLogWithLevelAndTag(ZMLogLevelDebug, @"event-processing", @"processing:\n%@", [message debugDescription]);
    
    ZMConversation *conversation = [self.class conversationForUpdateEvent:updateEvent inContext:moc prefetchResult:prefetchResult];
    VerifyReturnNil(conversation != nil);
    ZMUser *selfUser = [ZMUser selfUserInContext:moc];

    if (conversation.conversationType == ZMConversationTypeSelf && ![updateEvent.senderUUID isEqual:selfUser.remoteIdentifier]) {
        return nil; // don't process messages in the self conversation not sent from the self user
    }

    // Update the legal hold state in the conversation
    [conversation updateSecurityLevelIfNeededAfterReceiving:message timestamp:updateEvent.timeStamp ?: [NSDate date]];

    if (!message.knownMessage) {
        [UnknownMessageAnalyticsTracker tagUnknownMessageWithAnalytics:moc.analytics];
    }

    // Check if the message is valid

    if (message == nil) {
        ZMUser *sender = [ZMUser userWithRemoteID:updateEvent.senderUUID createIfNeeded:NO inConversation:conversation inContext:moc];
        VerifyReturnNil(sender);
        [conversation appendInvalidSystemMessageAt:updateEvent.timeStamp sender:sender];
        return nil;
    }
    
    // Verify sender is part of conversation
    ZMUser * sender = [ZMUser userWithRemoteID:updateEvent.senderUUID createIfNeeded:YES inConversation:conversation inContext:moc];
    [conversation addParticipantIfMissing:sender date: [updateEvent.timeStamp dateByAddingTimeInterval:-0.01]];

    // Insert the message

    if (message.hasLastRead && conversation.conversationType == ZMConversationTypeSelf) {
        [ZMConversation updateConversationWithZMLastReadFromSelfConversation:message.lastRead inContext:moc];
    } else if (message.hasCleared && conversation.conversationType == ZMConversationTypeSelf) {
        [ZMConversation updateConversationWithZMClearedFromSelfConversation:message.cleared inContext:moc];
    } else if (message.hasHidden && conversation.conversationType == ZMConversationTypeSelf) {
        [ZMMessage removeMessageWithRemotelyHiddenMessage:message.hidden inManagedObjectContext:moc];
    } else if (message.hasDeleted) {
        [ZMMessage removeMessageWithRemotelyDeletedMessage:message.deleted inConversation:conversation senderID:updateEvent.senderUUID inManagedObjectContext:moc];
    } else if (message.hasReaction) {
        // if we don't understand the reaction received, discard it
        if (message.reaction.emoji.length > 0 && [Reaction transportReactionFrom:message.reaction.emoji] == TransportReactionNone) {
            return nil;
        }
        [ZMMessage addReaction:message.reaction sender:sender conversation:conversation inManagedObjectContext:moc];
    } else if (message.hasForbid) {
        [ZMMessage addOperation:message.forbid sender:sender conversation:conversation inManagedObjectContext:moc];
    } else if (message.hasConfirmation) {
        [ZMMessageConfirmation createMessageConfirmations:message.confirmation conversation:conversation updateEvent:updateEvent sender: sender];
    } else if (message.hasEdited) {
        NSUUID *editedMessageId = [NSUUID uuidWithTransportString:message.edited.replacingMessageId];
        ZMClientMessage *editedMessage = [ZMClientMessage fetchMessageWithNonce:editedMessageId forConversation:conversation inManagedObjectContext:moc prefetchResult:prefetchResult];
        if ([editedMessage processMessageEdit:message.edited from:updateEvent]) {
            [editedMessage updateCategoryCache];
            
            conversation.lastVisibleMessage = editedMessage;
            return editedMessage;
        }
    } else if ([conversation shouldAddEvent:updateEvent] && !(message.hasClientAction || message.hasCalling || message.hasAvailability)) {
        NSUUID *nonce = [NSUUID uuidWithTransportString:message.messageId];
        
        Class messageClass = [ZMGenericMessage entityClassForGenericMessage:message];
        ZMOTRMessage *clientMessage;
        // 优先通过新增conversation.messagesNonceSet，查询消息是否已存在本地，若存在，再去读取，不存在，则去新建
        BOOL isNewMessage = NO;
        if ([conversation.messagesNonceSet containsObject:nonce]) {
            clientMessage = [messageClass fetchMessageWithNonce:nonce
                                                forConversation:conversation
                                         inManagedObjectContext:moc
                                                 prefetchResult:prefetchResult];
            
            if (clientMessage.isZombieObject) {
                return nil;
            }
            ///万人群忽略送达的状态，具体什么原因等待以后修改注释
            if (conversation.conversationType == ZMConversationTypeHugeGroup) {
                clientMessage.delivered = YES;
            }
            // 有可能什么消息没有senderClientID，具体什么原因等待以后修改注释
            if (clientMessage.senderClientID && ![clientMessage.senderClientID isEqualToString:updateEvent.senderClientID]) {
                return nil;
            }
        } else {
            isNewMessage = YES;
            
            clientMessage = [[messageClass alloc] initWithNonce:nonce managedObjectContext:moc];
            clientMessage.senderClientID = updateEvent.senderClientID;
            clientMessage.serverTimestamp = updateEvent.timeStamp;
            // 收到新闻公众号的消息，主动去识别链接
//            if (updateEvent.type == ZMUpdateEventTypeConversationServiceMessageAdd && [clientMessage isKindOfClass:ZMClientMessage.class]) {
//                ((ZMClientMessage *)clientMessage).linkPreviewState = ZMLinkPreviewStateWaitingToBeProcessed;
//            }
            // 暂时屏蔽群消息的已读回执功能
//            if (![updateEvent.senderUUID isEqual:selfUser.remoteIdentifier] && conversation.conversationType == ZMConversationTypeGroup) {
//                clientMessage.expectsReadConfirmation = conversation.hasReadReceiptsEnabled;
//            }
        }
        
        // In case of AssetMessages: If the payload does not match the sha265 digest, calling `updateWithGenericMessage:updateEvent` will delete the object.
        // 群邀请已被确认消息需要强制设置为新消息，来达到强制更新消息内容的目的
        if (updateEvent.type == ZMUpdateEventTypeConversationMemberJoinask) {
            isNewMessage = true;
        }
        [clientMessage updateWithGenericMessage:message updateEvent:updateEvent initialUpdate:isNewMessage];
        
        // It seems that if the object was inserted and immediately deleted, the isDeleted flag is not set to true.
        // In addition the object will still have a managedObjectContext until the context is finally saved. In this
        // case, we need to check the nonce (which would have previously been set) to avoid setting an invalid
        // relationship between the deleted object and the conversation and / or sender
        if (clientMessage.isZombieObject || clientMessage.nonce == nil) {
            return nil;
        }
        
        // 优化user查询效率,用于替代func"[clientMessage updateWithUpdateEvent:updateEvent forConversation:conversation]"
        [clientMessage updateWithSender:sender forConversation:conversation];
//        [clientMessage updateWithUpdateEvent:updateEvent forConversation:conversation];
        [clientMessage unarchiveIfNeeded:conversation];
        [clientMessage updateCategoryCache];
        
        return clientMessage;
    }

    return nil;
}

-(void)updateWithPostPayload:(NSDictionary *)payload updatedKeys:(NSSet *)updatedKeys {

    NSDate *timestamp = [payload dateFor:@"time"];
    if (timestamp == nil) {
        ZMLogWarn(@"No time in message post response from backend.");
    } else if( ! [timestamp isEqualToDate:self.serverTimestamp]) {
        self.expectsReadConfirmation = self.conversation.hasReadReceiptsEnabled;
    }
    
    [super updateWithPostPayload:payload updatedKeys:updatedKeys];
}

@end
