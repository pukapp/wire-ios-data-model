//
//  ZMConversation+SecretHouse.swift
//  WireDataModel
//
//  Created by 刘超 on 2021/7/9.
//  Copyright © 2021 Wire Swiss GmbH. All rights reserved.
//

import Foundation

@objc public enum AudioHouseNotificationStatus: Int16 {
    case none // 默认状态
    case show // 房间开启之后
    case hide // 房间关闭
    case close // 用户手动关闭了通知
}

// MARK: SecretHouse 通知逻辑
extension ZMConversation {

    @NSManaged private var primitiveHouseNotificationStatus: NSNumber

    /// Whether the conversation is under legal hold.
    @objc public var houseNotificationStatus: AudioHouseNotificationStatus {
        get {
            willAccessValue(forKey: #keyPath(houseNotificationStatus))
            defer { didAccessValue(forKey: #keyPath(houseNotificationStatus)) }

            if let status = AudioHouseNotificationStatus(rawValue: primitiveHouseNotificationStatus.int16Value) {
                return status
            } else {
                return .none
            }
        }
        set {
            willChangeValue(forKey: #keyPath(houseNotificationStatus))
            primitiveHouseNotificationStatus = NSNumber(value: newValue.rawValue)
            didChangeValue(forKey: #keyPath(houseNotificationStatus))
        }
    }

}
