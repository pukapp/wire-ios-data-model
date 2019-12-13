////  ConversationMessage+Operation.swift
//  WireDataModel
//
//  Created by DBH on 2019/12/13.
//  Copyright © 2019 Wire Swiss GmbH. All rights reserved.
//

import Foundation

extension ZMMessage {
    
    @discardableResult
    @objc public static func addOperation(
        _ type: MessageOperationType,
        status: MessageOperationStatus,
        onMessage message: ZMConversationMessage) -> ZMClientMessage? {
        
        guard
            let message = message as? ZMMessage,
            let context = message.managedObjectContext,
            let messageID = message.nonce,
            message.isSent
            else { return nil }
        let user: ZMUser = .selfUser(in: context)
        // TODO: ZMForbid operatorName: user.name!
        let genericMessage = ZMGenericMessage.message(content: ZMForbid(type: type.uniqueValue, messageID: messageID, operatorName: user.name!))
        let clientMessage = message.conversation?.appendClientMessage(with: genericMessage, expires: false, hidden: true)
        message.addOperation(type, status: status, byOperator: user)
        return clientMessage
    }
    
    
    @objc public func addOperation(_ type: MessageOperationType, status: MessageOperationStatus, byOperator user: ZMUser) {
        let opt = Operation.insertOperation(type, status: status, byOperator: user, onMessage: self)
        mutableSetValue(forKey: "operations").add(opt)
        updateCategoryCache()
    }
    
    private func removeOperation(_ type: MessageOperationType, forUser user: ZMUser) {
        guard let opt = operations
            .filter({ $0.type == type.uniqueValue })
            .first(where: { $0.operateUser?.remoteIdentifier == user.remoteIdentifier })
            else { return }
        operations.remove(opt)
    }
    
    @objc public func clearAllOperations() {
        guard let moc = managedObjectContext else { return }
        let ops = operations
        operations.removeAll()
        ops.forEach(moc.delete)
    }
}


extension ZMMessage {
    
    public static func operationState(of message: ZMConversationMessage, type: MessageOperationType) -> MessageOperationStatus {
        guard let message = message as? ZMMessage else { return .off }
        return message.operationState(of: type)
    }
    
    public func operationState(of type: MessageOperationType) -> MessageOperationStatus {
        guard let nonce = nonce else { return .off }
        guard let opt = operations
            .filter({ $0.type == type.uniqueValue })
            .first(where: { $0.message?.nonce == nonce }) else { return .off }
        return opt.state ? .on : .off
    }
}
