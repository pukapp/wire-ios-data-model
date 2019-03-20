//
//  ZMClientMessage+NoEncryption.swift
//  WireDataModel
//
//  Created by kk on 2019/2/22.
//  Copyright © 2019 Wire Swiss GmbH. All rights reserved.
//

import Foundation

public protocol UnencryptedMessagePayloadGenerator {

    func unencryptedMessagePayload() -> [String: Any]?

    var unencryptedMessageDebugInfo: String { get }
}

extension ZMClientMessage: UnencryptedMessagePayloadGenerator {

    public func unencryptedMessagePayload() -> [String : Any]? {
        guard
            let genericMessage = genericMessage,
            let conversation = conversation,
            let moc = conversation.managedObjectContext
            else { return nil }
        let user = ZMUser.selfUser(in: moc)
        
        guard
            let sender = user.selfClient()?.remoteIdentifier,
            let name = user.name
            else { return nil }
        var params: [String: Any] = [:]
        var asset: [String: Any] = [:]
        asset["name"] = name
        if let imgId = user.previewProfileAssetIdentifier {
            asset["avatar_key"] = imgId
        }
        
        params = [
            "text": genericMessage.data().base64EncodedString(),
            "sender": sender,
            "asset": asset
        ]
        
        let sendUserIds = sendUserIdsOfRedBagOrBBCashGet(genericMessage)
        if !sendUserIds.isEmpty {
            params["recipients"] = sendUserIds
        }
        
        return params
    }

    public var unencryptedMessageDebugInfo: String {
        var info = "\(String(describing: genericMessage))"
        if let genericMessage = genericMessage, genericMessage.hasExternal() {
            info = "External message: " + info
        }
        return info
    }
}

extension ZMClientMessage {
    
    /// 获取红包领取/币币兑换领取消息中的 'sendUserId'
    /// A 发了红包
    /// B 领取了A的红包，此时B领取红包消息中的'sendUserId'即为A
    /// 在万人群中领取A的红包时需向告知A
    private func sendUserIdsOfRedBagOrBBCashGet(_ genericMessage: ZMGenericMessage) -> [String] {
        if  genericMessage.hasTextJson(),
            let data = genericMessage.textJson.content.data(using: .utf8),
            let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
            let msgType = json?["msgType"] as? String,
            ["4", "6"].contains(msgType),
            let msgData = json?["msgData"] as? [String: Any],
            let sendUserId = msgData["sendUserId"] as? String {
            return [sendUserId]
        }
        return []
    }
}

extension ZMAssetClientMessage: UnencryptedMessagePayloadGenerator {

    public func unencryptedMessagePayload() -> [String : Any]? {
        guard
            let genericMessage = genericAssetMessage,
            let conversation = conversation,
            let moc = conversation.managedObjectContext
            else { return nil }
        let user = ZMUser.selfUser(in: moc)
        guard
            let sender = user.selfClient()?.remoteIdentifier,
            let name = user.name
            else { return nil }
        var asset: [String: Any] = [:]
        asset["name"] = name
        if let imgId = user.previewProfileAssetIdentifier {
            asset["avatar_key"] = imgId
        }
        return [
            "text": genericMessage.data().base64EncodedString(),
            "sender": sender,
            "asset": asset
        ]
    }

    public var unencryptedMessageDebugInfo: String {
        return "\(String(describing: genericAssetMessage))"
    }
}
