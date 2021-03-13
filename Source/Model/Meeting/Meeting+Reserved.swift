//
//  Meeting+Reserved.swift
//  WireDataModel
//
//  Created by 老西瓜 on 2021/3/11.
//  Copyright © 2021 Wire Swiss GmbH. All rights reserved.
//

import Foundation

//预约会议相关model
public struct MeetingReserved {
    
    //提醒时间类型
    public enum RemindTimeType: String {
        case none    = ""             //不提醒
        case start   = "meet_start"   // 1-会议开始时间
        case t5mAgo  = "meet_5m_ago"  // 2-会议开始时间5分钟前
        case t15mAgo = "meet_15m_ago" // 3-会议开始时间15分钟前
        case t30mAgo = "meet_30m_ago" // 4-会议开始时间30分钟前
        case t1hAgo  = "meet_1h_ago"  // 5-会议开始时间1小时前
        case t1dAgo  = "meet_1d_ago"  // 6-会议开始时间1天前
    }
    
    public struct RepeatInfo: Equatable {
        //重复方式
        public enum RepeatType: String {
            case none       = ""             //不重复
            case weekday    = "weekday"
            case daily      = "daily"
            case weekly     = "weekly"
            case two_weekly = "two_weekly"
            case monthly    = "monthly"
            case yearly     = "yearly"
        }
        
        //限定结束方式
        public enum RepeatEndCategory: Equatable {
            case endDate(Date?)//结束于某天
            case endTimes(Int?)//限定会议次数
        }
        
        public var type: RepeatType
        public var category: RepeatEndCategory?
        
        public var dictionaryData: [String: Any] {
            switch self.category {
            case .endDate(let stopTime):
                return ["method": type.rawValue,
                        "category": 1,
                        "stop_time": stopTime!.transportString()]
            case .endTimes(let count):
                return ["method": type.rawValue,
                        "category": 2,
                        "count": count!]
            case .none:
                return ["method": type.rawValue]
            }
        }
        
        public init(type: RepeatType, category: RepeatEndCategory?) {
            self.type = type
            self.category = category
        }
        
        public init?(data: [String: Any]?) {
            guard let data = data,
                let type = data["method"] as? String,
                let category = data["category"] as? Int else {
                return nil
            }
            self.type = RepeatType(rawValue: type)!
            if category == 1 {
                let date = NSDate(transport: (data["stop_time"] as! String))! as Date
                self.category = .endDate(date)
            } else if category == 2 {
                self.category = .endTimes((data["count"] as! Int))
            }
        }
        
    }
    
    //成员的邀请状态
    public enum InviteState: String {
        case accepted
        case pending
        case rejected
        case removed
    }
    
    public enum AppointState: String {
        case normal
        case cancel
    }
    
    //预约会议所绑定的单次会议室相关信息
    public struct Meeting: Equatable {
        public let meetingId: String
        public let roomId: String?
        public let title: String
        public let startTime: Date
        public let holder: User
        public let state: MeetingState
        public let onlineUserNum: Int?
        
        public var dictionaryData: [String: Any] {
            var dic: [String : Any] = ["meet_id": meetingId,
                                       "title": title,
                                       "start_time": startTime.transportString(),
                                       "holder": holder.dictionaryData,
                                       "state": state.rawValue]
            if let roomId = roomId {
                dic["room_id"] = roomId
            }
            if let onlineUserNum = onlineUserNum {
                dic["user_online_num"] = onlineUserNum
            }
            return dic
        }
        
        public init(data: [String: Any]) {
            self.meetingId = data["meet_id"] as! String
            self.roomId = data["room_id"] as? String
            self.title = data["title"] as! String
            self.startTime = NSDate(transport: data["start_time"] as! String)! as Date
            self.holder = User(data: data["holder"] as! [String: Any])
            self.state = MeetingState(rawValue: (data["state"] as! String)) ?? .wait
            self.onlineUserNum = data["user_online_num"] as? Int
        }
        
        public init(meetingId: String, roomId: String, title: String, startTime: Date, holder: User, state: MeetingState, onlineUserNum: Int? = nil) {
            self.meetingId = meetingId
            self.roomId = roomId
            self.title = title
            self.startTime = startTime
            self.holder = holder
            self.state = state
            self.onlineUserNum = onlineUserNum
        }
        
        public static func == (lhs: MeetingReserved.Meeting, rhs: MeetingReserved.Meeting) -> Bool {
            return lhs.meetingId == rhs.meetingId &&
            lhs.roomId == rhs.roomId &&
            lhs.title == rhs.title &&
            lhs.startTime == rhs.startTime &&
            lhs.holder == rhs.holder &&
            lhs.state == rhs.state
        }

    }
    
    //预约会议相关信息
    public struct Info: Equatable {
        public let appointId: String
        public let state: AppointState
        public let roomId: String
        public var password: String?
        public var title: String
        public var intro: String?
        public var startTime: Date
        public var endTime: Date
        public var reminderType: [RemindTimeType]
        public let owner: User
        public var repeatInfo: RepeatInfo?
        public var inviteUsers: [User]
        public var inviteUserCount: Int
        
        public let meeting: Meeting
        
        public var dictionaryData: [String: Any] {
            var dic: [String: Any] = ["appoint_id": appointId,
                                      "state": state.rawValue,
                                      "room_id": roomId,
                                      "title": title,
                                      "start_time": startTime.transportString(),
                                      "end_time": endTime.transportString(),
                                      "remind_times": reminderType.map(\.rawValue),
                                      "owner": owner.dictionaryData,
                                      "invite_users": inviteUsers.map(\.dictionaryData),
                                      "invite_user_count": inviteUserCount,
                                      "last_record": meeting.dictionaryData]
            if let password = password {
                dic["password"] = password
            }
            if let intro = intro {
                dic["intro"] = intro
            }
            if let repeatInfo = repeatInfo {
                dic["repeat"] = repeatInfo.dictionaryData
            }
            return dic
        }
        
        public init(data: [String: Any]) {
            self.appointId = data["appoint_id"] as! String
            self.state = AppointState(rawValue: data["state"] as! String) ?? .normal
            self.roomId = data["room_id"] as! String
            self.password = data["password"] as? String
            self.title = data["title"] as! String
            self.intro = data["intro"] as? String
            self.startTime = NSDate(transport: data["start_time"] as! String)! as Date
            self.endTime = NSDate(transport: data["end_time"] as! String)! as Date
            let reminderTypeData = data["remind_times"] as! [String]
            self.reminderType = reminderTypeData.map({ return RemindTimeType(rawValue: $0)! })
            self.owner = User(data: data["owner"] as! [String: Any])
            self.repeatInfo = RepeatInfo(data: data["repeat"] as? [String: Any])
            if let invite_users = data["invite_users"] as? [[String : Any]] {
                self.inviteUsers = invite_users.map({ return User(data: $0) })
            } else {
                self.inviteUsers = []
            }
            if let invite_user_count = data["invite_user_count"] as? Int {
                self.inviteUserCount = invite_user_count
            } else {
                self.inviteUserCount = inviteUsers.count
            }
            self.meeting = Meeting(data: data["last_record"] as! [String: Any])
        }
        
        public init(appointID: String, state: AppointState, roomId: String, password: String?, title: String,
             intro: String?, startTime: Date, endTime: Date, reminderType: [RemindTimeType],
             owner: User, repeatInfo: RepeatInfo?, inviteUsers: [User], meeting: Meeting) {
            self.appointId = appointID
            self.state = state
            self.roomId = roomId
            self.password = password
            self.title = title
            self.intro = intro
            self.startTime = startTime
            self.endTime = endTime
            self.reminderType = reminderType
            self.owner = owner
            self.repeatInfo = repeatInfo
            self.inviteUsers = inviteUsers
            self.inviteUserCount = inviteUsers.count
            self.meeting = meeting
        }
        
        public static func == (lhs: MeetingReserved.Info, rhs: MeetingReserved.Info) -> Bool {
            return lhs.appointId == rhs.appointId &&
            lhs.roomId == rhs.roomId &&
            lhs.password == rhs.password &&
            lhs.title == rhs.title &&
            lhs.intro == rhs.intro &&
            lhs.startTime == rhs.startTime &&
            lhs.endTime == rhs.endTime &&
            lhs.reminderType == rhs.reminderType &&
            lhs.owner == rhs.owner &&
            lhs.repeatInfo == rhs.repeatInfo &&
            lhs.inviteUsers == rhs.inviteUsers &&
            lhs.meeting == rhs.meeting
        }
        
    }
    
    //预约会议的成员相关信息
    public struct User: Equatable {
        public let userID: String
        public let nickname: String
        public let avatarKey: String?
        public var inviteState: InviteState = .pending
            
        public var dictionaryData: [String: Any] {
            return ["user_id": userID,
                    "nickname": nickname,
                    "avatar": avatarKey ?? "",
                    "invite_state": inviteState.rawValue]
        }
        
        public init(userID: String, nickname: String, avatarKey: String?) {
            self.userID = userID
            self.nickname = nickname
            self.avatarKey = avatarKey
        }
        
        public init(data: [String: Any]) {
            self.userID         = data["user_id"] as! String
            self.nickname       = data["nickname"] as! String
            self.avatarKey      = data["avatar"] as? String
            if let inviteState = data["invite_state"] as? String {
                self.inviteState  = InviteState(rawValue: inviteState) ?? .pending
            }
        }
    
        func hash(into hasher: inout Hasher) {
            hasher.combine(userID)
        }
        
        public static func == (lhs: MeetingReserved.User, rhs: MeetingReserved.User) -> Bool {
            return lhs.userID == rhs.userID
        }
    }
}
