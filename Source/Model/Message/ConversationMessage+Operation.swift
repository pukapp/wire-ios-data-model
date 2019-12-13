////  ConversationMessage+Operation.swift
//  WireDataModel
//
//  Created by DBH on 2019/12/13.
//  Copyright © 2019 Wire Swiss GmbH. All rights reserved.
//

import Foundation

extension ZMMessage {
    
    @discardableResult
    @objc public static func addOperation(_ operation: MessageOperationType, toMessage message: ZMConversationMessage) -> ZMClientMessage? {
        guard
            let message = message as? ZMMessage,
            let context = message.managedObjectContext,
            let messageID = message.nonce,
            message.isSent
            else { return nil }
        // TODO: ZMForibid
        let genericMessage = ZMGenericMessage.message(content: ZMReaction(emoji: "", messageID: messageID))
        let clientMessage = message.conversation?.appendClientMessage(with: genericMessage, expires: false, hidden: true)
        message.addOperation(operation, byOperator: .selfUser(in: context))
        return clientMessage
    }
    
    
    @objc public func addOperation(_ operation: MessageOperationType, byOperator user: ZMUser) {
        Operation.insertOperation(operation, byOperator: user, onMessage: self)
//        removeReaction(forUser:user)
//        if let unicodeValue = unicodeValue , unicodeValue.count > 0 {
//            for reaction in self.reactions {
//                if reaction.unicodeValue! == unicodeValue {
//                    reaction.mutableSetValue(forKey: ZMReactionUsersValueKey).add(user)
//                    return
//                }
//            }
//
//            //we didn't find a reaction, need to add a new one
//            let newReaction = Reaction.insertReaction(unicodeValue, users: [user], inMessage: self)
//            self.mutableSetValue(forKey: "reactions").add(newReaction)
//        }
//        updateCategoryCache()
    }
}
