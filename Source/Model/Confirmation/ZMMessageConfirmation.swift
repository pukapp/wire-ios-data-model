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

import Foundation
import CoreData


@objc public enum MessageConfirmationType : Int16 {
    case delivered, read
    
    static func convert(_ zmConfirmationType: ZMConfirmationType) -> MessageConfirmationType {
        //TODO: change ZMConfirmationType to NS_CLOSED_ENUM
        switch zmConfirmationType {
        case .DELIVERED:
            return .delivered
        case .READ:
            return .read
        @unknown default:
            fatalError()
        }
    }
}

@objc(ZMMessageConfirmation) @objcMembers
open class ZMMessageConfirmation : NSObject {
    
    /// Creates a ZMMessageConfirmation objects that holds a reference to a message that was confirmed and the user who confirmed it.
    /// It can have 2 types: Delivered and Read depending on the confirmation type
    @objc
    public static func createMessageConfirmations(_ confirmation: ZMConfirmation, conversation: ZMConversation, updateEvent: ZMUpdateEvent) {
        
        let type = MessageConfirmationType.convert(confirmation.type)
        
        guard let managedObjectContext = conversation.managedObjectContext,
              let firstMessageId = confirmation.firstMessageId else { return }
        
        let moreMessageIds = confirmation.moreMessageIds as? [String] ?? []
        let confirmedMesssageIds = ([firstMessageId] + moreMessageIds).compactMap({ UUID(uuidString: $0) })
        
        for confirmedMessageId in confirmedMesssageIds {
            guard let message = ZMMessage.fetch(withNonce: confirmedMessageId, for: conversation, in: managedObjectContext) else { return }
            message.isSendDelivered = type == .delivered
            message.isSendRead = type == .read
        }
        
    }
    
}
