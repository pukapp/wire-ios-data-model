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
        let operatorUser: ZMUser = .selfUser(in: context)
        let operaorName = operatorUser.name ?? operatorUser.displayName
        let genericMessage = ZMGenericMessage.message(content: ZMForbid(type: type.uniqueValue, messageID: messageID, operatorName: operaorName))
        let clientMessage = message.conversation?.appendClientMessage(with: genericMessage, expires: false, hidden: true)
        switch status {
        case .on: message.addOperation(type, status: status, byOperator: operatorUser)
        case .off: message.removeOperation(type)
        }
        return clientMessage
    }
    
    
    @objc public func addOperation(_ type: MessageOperationType, status: MessageOperationStatus, byOperator user: ZMUser) {
        let opt = Operation.insertOperation(type, status: status, byOperator: user, onMessage: self)
        mutableSetValue(forKey: "operations").add(opt)
        updateCategoryCache()
    }
    
    private func removeOperation(_ type: MessageOperationType) {
        guard let nonce = nonce else { return }
        let id = nonce.transportString()
        guard !id.isEmpty else { return }
        guard let opt = operations
            .filter({ $0.type == type.uniqueValue })
            .first(where: { $0.message?.nonce?.transportString() == id })
            else { return }
        operations.remove(opt)
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
    
    public static func operationUser(of message: ZMConversationMessage, type: MessageOperationType) -> ZMUser? {
        guard let message = message as? ZMMessage else { return nil }
        return message.operationUser(of: type)
    }
    
    public func operationUser(of type: MessageOperationType) -> ZMUser? {
        guard let opt = operation(of: type) else { return nil }
        return opt.operateUser
    }
    
    public func operationState(of type: MessageOperationType) -> MessageOperationStatus {
        guard let opt = operation(of: type) else { return .off }
        return opt.state ? .on : .off
    }
    
    private func operation(of type: MessageOperationType) -> Operation? {
        guard let nonce = nonce else { return nil }
        let nonceString = nonce.transportString()
        guard !nonceString.isEmpty else { return nil }
        return operations
            .filter({ $0.type == type.uniqueValue })
            .first(where: { $0.message?.nonce?.transportString() == nonceString })
    }
}
