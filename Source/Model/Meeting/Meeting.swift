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
public let ZMMeetingStateKey = "stateRawValue"
public let ZMMeetingNotificationStateKey = "notificationStateRawValue"

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
    @NSManaged private var muteAllRawValue: String
    public var muteAll: MeetingMuteState {
        get {
            return MeetingMuteState(rawValue: muteAllRawValue)!
        }
        set {
            muteAllRawValue = newValue.rawValue
        }
    }
    @NSManaged private var stateRawValue: String
    public var state: MeetingState {
        get {
            return MeetingState(rawValue: stateRawValue)!
        }
        set {
            stateRawValue = newValue.rawValue
        }
    }
    @NSManaged public var notificationStateRawValue: String
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
    
    @NSManaged public var onlyHosterCanShareScreen: Bool
    @NSManaged public var isInternal: Bool
    @NSManaged public var isLocked: Bool
    
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
        guard let meetingId = payload["meet_id"] as? String,
            let title = payload["title"] as? String,
            let startDate = payload["start_time"] as? String,
            let stateRawValue = payload["state"] as? String else { return nil }
        
        let fetchedMeeting = fetchExistingMeeting(with: meetingId, in: context)
        let meeting = fetchedMeeting ?? ZMMeeting.insertNewObject(in: context)
        
        meeting.meetingId = meetingId
        meeting.title = title
        meeting.startDate = startDate
        meeting.stateRawValue = stateRawValue
        
        let needSetDefaultValues: () -> Void = {
            print("MeetingNotification--createMeeting--\(meeting.meetingId)")
            //下面字段为初始默认值
            meeting.createDate = Date()
            meeting.mode = .video
            meeting.notificationState = .show
            meeting.muteAll = .no
            meeting.onlineUserNum = 0
            meeting.allUserNum = 1
            meeting.isInternal = false
            meeting.isLocked = false
            meeting.onlyHosterCanShareScreen = false
        }
        //只有是刚创建的meeting，才需要设置默认值
        if fetchedMeeting == nil { needSetDefaultValues() }
        
        return meeting
    }
    
    
    static func fetchExistingMeeting(with meetingId: String, in context: NSManagedObjectContext) -> ZMMeeting? {
        let fetchRequest = NSFetchRequest<ZMMeeting>(entityName: ZMMeeting.entityName())
        fetchRequest.predicate = NSPredicate(format: "%K == %@", ZMMeetingIdentifierKey, meetingId)
        fetchRequest.fetchLimit = 2
         
        let result = context.fetchOrAssert(request: fetchRequest)
        for meeting in result {
            print("MeetingNotification--fetchExistingMeeting--\(meeting.meetingId)--\(meeting.notificationStateRawValue)")
        }
        if result.count == 2 {
            print("MeetingNotification--fetchExistingMeeting--2 same id meeting")
            context.delete(result.last!)
            context.saveOrRollback()
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
        if result.count > 0 {
            print("MeetingNotification--fetchNeedNotificationMeeting--\(result.first!.notificationStateRawValue)")
            return result.first
        }
        return nil
    }
}
