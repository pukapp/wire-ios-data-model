//
//  ZMClientMessage+JsonTextMessageData.swift
//  WireDataModel
//
//  Created by JohnLee on 2019/1/11.
//  Copyright © 2019 Wire Swiss GmbH. All rights reserved.
//

import Foundation

@objc
extension ZMClientMessage: ZMJsonTextMessageData {

    public var jsonMessageText: String? {
        return genericMessage?.jsonTextData?.content
    }
}
