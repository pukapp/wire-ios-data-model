//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

import Foundation


public extension ZMConversationMessage {

    /// Returns YES, if the message has text to display.
    /// This also includes linkPreviews or links to soundcloud, youtube or vimeo
    public var isText: Bool {
        return textMessageData != nil
    }
    
    public var isJsonText: Bool {
        return jsonTextMessageData != nil
    }

    public var isImage: Bool {
        return imageMessageData != nil || (fileMessageData != nil && fileMessageData!.v3_isImage)
    }

    public var isKnock: Bool {
        return knockMessageData != nil
    }

    /// Returns YES, if the message is a file transfer message
    /// This also includes audio messages and video messages
    public var isFile: Bool {
        return fileMessageData != nil && !fileMessageData!.v3_isImage
    }

    public var isPass: Bool {
        return isFile && fileMessageData!.isPass
    }

    public var isVideo: Bool {
        return isFile && fileMessageData!.isVideo
    }

    public var isAudio: Bool {
        return isFile && fileMessageData!.isAudio
    }

    public var isLocation: Bool {
        return locationMessageData != nil
    }

    public var isSystem: Bool {
        return systemMessageData != nil
    }
    /// 新增的系统通知消息
    public var isNewSystem: Bool {
        guard let jsonMessageData = jsonTextMessageData?.jsonMessageText?.data(using: .utf8),
            let jsonObject = try? JSONSerialization.jsonObject(with: jsonMessageData, options: JSONSerialization.ReadingOptions.mutableContainers),
            let dict = jsonObject as? [String: Any] else {
            return false
        }
        // 红包领取消息和币币兑付领取消息
        if dict["msgType"] as? String == "4" || dict["msgType"] as? String == "6" {
            return true
        } else {
            return false
        }
    }

    public var isNormal: Bool {
        return isText
            || isImage
            || isKnock
            || isFile
            || isVideo
            || isAudio
            || isLocation
            || (isJsonText && !isNewSystem)
    }

    public var isConnectionRequest: Bool {
        guard isSystem else { return false }
        return systemMessageData!.systemMessageType == .connectionRequest
    }

    public var isMissedCall: Bool {
        guard isSystem else { return false }
        return systemMessageData!.systemMessageType == .missedCall
    }

    public var isPerformedCall: Bool {
        guard isSystem else { return false }
        return systemMessageData!.systemMessageType == .performedCall
    }

    public var isDeletion: Bool {
        guard isSystem else { return false }
        return systemMessageData!.systemMessageType == .messageDeletedForEveryone
    }

}

/// The `ZMConversationMessage` protocol can not be extended in Objective-C,
/// thus this helper class provides access to commonly used properties.
public class Message: NSObject {

    /// Returns YES, if the message has text to display.
    /// This also includes linkPreviews or links to soundcloud, youtube or vimeo
    @objc(isTextMessage:)
    public class func isText(_ message: ZMConversationMessage) -> Bool {
        return message.isText
    }
    
    @objc(isJsonTextMessage:)
    public class func isJsonText(_ message: ZMConversationMessage) -> Bool {
        return message.isJsonText
    }

    @objc(isImageMessage:)
    public class func isImage(_ message: ZMConversationMessage) -> Bool {
        return message.isImage
    }

    @objc(isKnockMessage:)
    public class func isKnock(_ message: ZMConversationMessage) -> Bool {
        return message.isKnock
    }

    /// Returns YES, if the message is a file transfer message
    /// This also includes audio messages and video messages
    @objc(isFileTransferMessage:)
    public class func isFileTransfer(_ message: ZMConversationMessage) -> Bool {
        return message.isFile
    }

    @objc(isVideoMessage:)
    public class func isVideo(_ message: ZMConversationMessage) -> Bool {
        return message.isVideo
    }

    @objc(isAudioMessage:)
    public class func isAudio(_ message: ZMConversationMessage) -> Bool {
        return message.isAudio
    }

    @objc(isLocationMessage:)
    public class func isLocation(_ message: ZMConversationMessage) -> Bool {
        return message.isLocation
    }

    @objc(isSystemMessage:)
    public class func isSystem(_ message: ZMConversationMessage) -> Bool {
        return message.isSystem
    }

    @objc(isNormalMessage:)
    public class func isNormal(_ message: ZMConversationMessage) -> Bool {
        return message.isNormal
    }
    
    @objc(isNewSystemMessage:)
    public class func isNewSystem(_ message: ZMConversationMessage) -> Bool {
        return message.isNewSystem
    }

    @objc(isConnectionRequestMessage:)
    public class func isConnectionRequest(_ message: ZMConversationMessage) -> Bool {
        return message.isConnectionRequest
    }

    @objc(isMissedCallMessage:)
    public class func isMissedCall(_ message: ZMConversationMessage) -> Bool {
        return message.isMissedCall
    }

    @objc(isPerformedCallMessage:)
    public class func isPerformedCall(_ message: ZMConversationMessage) -> Bool {
        return message.isPerformedCall
    }

    @objc(isDeletedMessage:)
    public class func isDeleted(_ message: ZMConversationMessage) -> Bool {
        return message.isDeletion
    }

}
