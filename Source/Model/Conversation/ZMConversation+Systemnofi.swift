//
//  ZMConversation+Systemnofi.swift
//  WireDataModel
//
//  Created by 王杰 on 2019/3/6.
//  Copyright © 2019 Wire Swiss GmbH. All rights reserved.
//

extension ZMConversation {
    
    @objc public var isSystemNofi: Bool {
        get {
            return self.remoteIdentifier?.transportString() == ZMPayConversationRemoteID
        }
    }
    
}
