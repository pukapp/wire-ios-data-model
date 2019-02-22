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
        var info = "\(String(describing: genericMessage))"
        if let genericMessage = genericMessage, genericMessage.hasExternal() {
            info = "External message: " + info
        }
        return info
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
