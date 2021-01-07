//
//  Meeting.swift
//  WireDataModel
//
//  Created by 老西瓜 on 2020/9/11.
//  Copyright © 2020 Wire Swiss GmbH. All rights reserved.
//

import Foundation

public enum MeetingState: String {
    case on = "on"
    case off = "off"
    case wait = "wait"
}

//会议模式，现在只有视频会议
public enum MeetingMode: Int64 {
    case voice = 0
    case video = 1
}

//会议通知状态，目前仅用来控制会话列表上方的横条的显示与否
public enum MeetingNotificationState: String {
    case show = "show"
    case hide = "hide"
}

public enum MeetingMuteState: String {
    case no   = "no"    //取消静音
    case soft = "soft"  //非强制全员静音
    case hard = "hard"  //强制全员静音
}

public let ZMMeetingIdentifierKey = "meetingId"
public let ZMMeetingRoomIdKey = "roomId"
public let ZMMeetingStateKey = "stateRawValue"
public let ZMMeetingNotificationStateKey = "notificationStateRawValue"
public let ZMMeetingCallingDateKey = "callingDate"

public class ZMMeeting: ZMManagedObject {
    
    @NSManaged public var meetingId: String
    @NSManaged public var title: String
    @NSManaged public var startDate: String
    @NSManaged public var createDate: Date
    
    @NSManaged public var roomId: String?
    
    @NSManaged private var modeRawValue: Int64
    public var mode: MeetingMode {
        get {
            return MeetingMode(rawValue: modeRawValue)!
        }
        set {
            modeRawValue = newValue.rawValue
        }
    }
    @NSManaged var muteAllRawValue: String
    public var muteAll: MeetingMuteState {
        get {
            return MeetingMuteState(rawValue: muteAllRawValue)!
        }
        set {
            muteAllRawValue = newValue.rawValue
        }
    }
    @NSManaged var stateRawValue: String
    public var state: MeetingState {
        get {
            return MeetingState(rawValue: stateRawValue)!
        }
        set {
            stateRawValue = newValue.rawValue
        }
    }
    @NSManaged var notificationStateRawValue: String
    public var notificationState: MeetingNotificationState {
        get {
            return MeetingNotificationState(rawValue: notificationStateRawValue)!
        }
        set {
            notificationStateRawValue = newValue.rawValue
        }
    }
    
    @NSManaged public var ownerId: String?
    
    @NSManaged public var onlineUserNum: Int
    @NSManaged public var allUserNum: Int
    @NSManaged public var holdId: String?
    @NSManaged public var holdName: String?
    @NSManaged public var holdAvatar: String?
    @NSManaged public var speakerId: String?
    @NSManaged public var screenShareUserId: String?
    @NSManaged public var watchUserId: String?
    
    @NSManaged public var currentIsScreenSharing: Bool //当前有人正在屏幕共享中
    @NSManaged public var onlyHosterCanShareScreen: Bool //仅主持人可以屏幕分享
    @NSManaged public var isInternal: Bool //是否内部会议
    @NSManaged public var isLocked: Bool //是否锁定会议
    
    //被呼叫的时间-收到推送时更新，用来显示滑动加入会议的成员被呼叫页面
    @NSManaged public var callingDate: Date?
    @NSManaged public var mediaServerToken: String? //加入媒体服务器所需要的token
    
    public var memberList: NSOrderedSet = NSOrderedSet(array: [])
    
    public override static func entityName() -> String {
        return "Meeting"
    }
    
    public override static func isTrackingLocalModifications() -> Bool {
        return false
    }
    
}

public extension ZMMeeting {
    
    @discardableResult
    static func createOrUpdateMeeting(with payload: [String: Any], context: NSManagedObjectContext) -> ZMMeeting? {
        guard let meetingId = payload["meet_id"] as? String else { return nil }
        
        print("createOrUpdateMeeting-\(payload)--\(context)---\(Thread.current)")
        
        var fetchedMeeting = fetchExistingMeeting(with: meetingId, in: context)
        if fetchedMeeting == nil {
            fetchedMeeting = ZMMeeting.createMeeting(with: payload, context: context)
        }
        fetchedMeeting!.updateMeeting(with: payload, context: context)
        return fetchedMeeting
    }
    
    /**
     * 更新会议
     */
    func updateMeeting(with payload: [String: Any], context: NSManagedObjectContext) {
        if let stateRawValue = payload["state"] as? String {
            self.state = MeetingState(rawValue: stateRawValue)!
        }
        if let roomId = payload["room_id"] as? String {
            self.roomId = roomId
        }
        if let owner = payload["owner"] as? [String: Any], let ownerId = owner["user_id"] as? String {
            self.ownerId = ownerId
        }
        if let startDate = payload["start_time"] as? String {
            self.startDate = startDate
        }
        if let muteAllRawValue = payload["mute_all"] as? String, let muteAll = MeetingMuteState(rawValue: muteAllRawValue) {
            self.muteAll = muteAll
        }
        if let onlineUserNum = payload["user_online_num"] as? Int {
            self.onlineUserNum = onlineUserNum
        }
        if let onlineUserNum = payload["user_online_num"] as? Int {
            self.onlineUserNum = onlineUserNum
        }
        if let allUserNum = payload["user_all_sum"] as? Int {
            self.allUserNum = allUserNum
        }
        if let holder = payload["holder"] as? [String: Any] {
            if let holderId = holder["user_id"] as? String, !holderId.isEmpty {
                self.holdId = holderId
            }
            if let holderName = holder["nickname"] as? String, !holderName.isEmpty {
                self.holdName = holderName
            }
            if let holderAvatar = holder["avatar"] as? String, !holderAvatar.isEmpty {
                self.holdAvatar = holderAvatar
            }
        }
        if let speaker = payload["speaker"] as? [String: Any],
            let speakerId = speaker["user_id"] as? String {
            self.speakerId = speakerId
        }
        if let screenShareUser = payload["screen_share_user"] as? [String: Any],
            let screenShareUserId = screenShareUser["user_id"] as? String {
            self.screenShareUserId = screenShareUserId
        }
        if let watcher = payload["watch_user"] as? [String: Any],
            let watcherId = watcher["user_id"] as? String {
            self.watchUserId = watcherId
        }
        if let internalValue = payload["internal"] as? String {
            self.isInternal = internalValue == "on"
        }
        if let isScreenSharingValue = payload["record"] as? String {
            self.currentIsScreenSharing = isScreenSharingValue == "on"
        }
        if let canScreenShareValue = payload["screen_share"] as? String {
            self.onlyHosterCanShareScreen = canScreenShareValue == "on"
        }
        if let lockMeetingValue = payload["lock_meeting"] as? String {
            self.isLocked = lockMeetingValue == "on"
        }
    }
    
    static func createMeeting(with payload: [String: Any], context: NSManagedObjectContext) -> ZMMeeting {
        print("createMeeting-\(payload)--\(context)---\(Thread.current)")
        require(context.zm_isSyncContext)
        guard let meetingId = payload["meet_id"] as? String,
            let title = payload["title"] as? String,
            let startDate = payload["start_time"] as? String,
            let stateRawValue = payload["state"] as? String else { fatal("wrong meeting msg") }
        
        let meeting = ZMMeeting.insertNewObject(in: context)
        meeting.meetingId = meetingId
        meeting.title = title
        meeting.startDate = startDate
        meeting.stateRawValue = stateRawValue
        //此两个属性与服务器不同步，仅用作本地业务需求
        meeting.createDate = Date()
        meeting.notificationState = .show
        
        return meeting
    }
    
    
    static func fetchExistingMeeting(with meetingId: String, in context: NSManagedObjectContext) -> ZMMeeting? {
        let fetchRequest = NSFetchRequest<ZMMeeting>(entityName: ZMMeeting.entityName())
        fetchRequest.predicate = NSPredicate(format: "%K == %@", ZMMeetingIdentifierKey, meetingId)
        fetchRequest.fetchLimit = 2
         
        let result = context.fetchOrAssert(request: fetchRequest)
        if result.count > 1 {
            fatal("wrong meeting")
        }
        if result.count > 0 {
            return result.first
        }
        return nil
    }
    
    static func fetchExistingMeetingByRoomId(_ roomId: String, in context: NSManagedObjectContext) -> ZMMeeting? {
        let fetchRequest = NSFetchRequest<ZMMeeting>(entityName: ZMMeeting.entityName())
        fetchRequest.predicate = NSPredicate(format: "%K == %@", ZMMeetingRoomIdKey, roomId)
        fetchRequest.fetchLimit = 2
         
        let result = context.fetchOrAssert(request: fetchRequest)
        if result.count > 1 {
            fatal("wrong meeting")
        }
        if result.count > 0 {
            return result.first
        }
        return nil
    }
    
    static func fetchNeedNotificationMeeting(in context: NSManagedObjectContext) -> ZMMeeting? {
        let fetchRequest = NSFetchRequest<ZMMeeting>(entityName: ZMMeeting.entityName())
        fetchRequest.predicate = NSPredicate(format: "%K == %@ AND %K == %@", ZMMeetingStateKey, MeetingState.on.rawValue,
                                             ZMMeetingNotificationStateKey, MeetingNotificationState.show.rawValue)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(ZMMeeting.createDate), ascending: false)]
        fetchRequest.fetchLimit = 2
        
        let result = context.fetchOrAssert(request: fetchRequest)
        result.forEach({
            print("test----needNotificationMeeting:\($0.meetingId)-\($0.title)")
        })
        if result.count > 0 {
            return result.first
        }
        return nil
    }
    
    static func fetchNeedShowCallingViewMeeting(in context: NSManagedObjectContext) -> ZMMeeting? {
        let fetchRequest = NSFetchRequest<ZMMeeting>(entityName: ZMMeeting.entityName())
        fetchRequest.predicate = NSPredicate(format: "%K == %@ AND %K != NULL", ZMMeetingStateKey, MeetingState.on.rawValue,
                                             ZMMeetingCallingDateKey)
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(ZMMeeting.callingDate), ascending: false)]
        fetchRequest.fetchLimit = 2
        let result = context.fetchOrAssert(request: fetchRequest)
        result.forEach({
            print("test----needShowCallingViewMeeting:\($0.meetingId)-\($0.title)")
        })
        if result.count > 0 {
            return result.first
        }
        return nil
    }
}
