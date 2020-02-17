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

@objc public enum MessageReaction: UInt16 {
    case like
    case audioPlayed

    public var unicodeValue: String {
        switch self {
        case .like: return "❤️"
        case .audioPlayed: return "audio_played"
        }
    }
}

extension ZMMessage {
    
    static func appendReaction(_ unicodeValue: String?, toMessage message: ZMConversationMessage) -> ZMClientMessage? {
        guard let message = message as? ZMMessage, let context = message.managedObjectContext, let messageID = message.nonce else { return nil }
        guard message.isSent else { return nil }
        
        let emoji = unicodeValue ?? ""
        let genericMessage = ZMGenericMessage.message(content: ZMReaction(emoji: emoji, messageID: messageID))    
        let clientMessage = message.conversation?.appendClientMessage(with: genericMessage, expires: false, hidden: true)
        message.addReaction(unicodeValue, forUser: .selfUser(in: context))
        return clientMessage
    }
    
    @discardableResult
    @objc public static func addReaction(_ reaction: MessageReaction, toMessage message: ZMConversationMessage) -> ZMClientMessage? {
        // confirmation that we understand the emoji
        // the UI should never send an emoji we dont handle
        if Reaction.transportReaction(from: reaction.unicodeValue) == .none{
            fatal("We can't append this reaction \(reaction.unicodeValue), this is a programmer error.")
        }
        
        return appendReaction(reaction.unicodeValue, toMessage: message)
    }
    
    @objc public static func removeReaction(onMessage message:ZMConversationMessage) -> ZMClientMessage? {
        return appendReaction(nil, toMessage: message)
    }
    
    @objc public func addReaction(_ unicodeValue: String?, forUser user:ZMUser) {
        removeReaction(forUser:user)
        if let unicodeValue = unicodeValue , unicodeValue.count > 0 {
            for reaction in self.reactions {
                if reaction.unicodeValue! == unicodeValue {
                    reaction.mutableSetValue(forKey: ZMReactionUsersValueKey).add(user)
                    return
                }
            }
            
            //we didn't find a reaction, need to add a new one
            let newReaction = Reaction.insertReaction(unicodeValue, users: [user], inMessage: self)
            self.mutableSetValue(forKey: "reactions").add(newReaction)
        }
        updateCategoryCache()
    }
    
    fileprivate func removeReaction(forUser user: ZMUser) {
        for reaction in self.reactions {
            if reaction.users.contains(user) {
                reaction.mutableSetValue(forKey: ZMReactionUsersValueKey).remove(user)
                break;
            }
        }
    }

    @objc public func clearAllReactions() {
        let oldReactions = self.reactions
        reactions.removeAll()
        guard let moc = managedObjectContext else { return }
        oldReactions.forEach(moc.delete)
    }
    
    @objc public func clearConfirmations() {
        let oldConfirmations = self.confirmations
        mutableSetValue(forKey: ZMMessageConfirmationKey).removeAllObjects()
        guard let moc = managedObjectContext else { return }
        oldConfirmations.forEach(moc.delete)
    }
}
