//
//  MeetingChangeInfo.swift
//  WireDataModel
//
//  Created by 老西瓜 on 2020/10/29.
//  Copyright © 2020 Wire Swiss GmbH. All rights reserved.
//

import Foundation

extension ZMMeeting : ObjectInSnapshot {
    
    static public var observableKeys : Set<String> {
        return [
            #keyPath(ZMMeeting.title),
            #keyPath(ZMMeeting.startDate),
            #keyPath(ZMMeeting.muteAllRawValue),
            #keyPath(ZMMeeting.stateRawValue),
            #keyPath(ZMMeeting.notificationStateRawValue),
            #keyPath(ZMMeeting.callingDate)
        ]
    }
    
    public var notificationName : Notification.Name {
        return .MeetingChange
    }
}

//监听单个meeting的改变
public final class MeetingChangeInfo : ObjectChangeInfo {

    private let meeting: ZMMeeting
    
    public required init(object: NSObject) {
        self.meeting = object as! ZMMeeting
        super.init(object: object)
    }
    
    static func changeInfo(for meeting: ZMMeeting, changes: Changes) -> MeetingChangeInfo? {
        guard changes.changedKeys.count > 0 || changes.originalChanges.count > 0 else { return nil }
        let changeInfo = MeetingChangeInfo(object: meeting)
        changeInfo.changeInfos = changes.originalChanges
        changeInfo.changedKeys = changes.changedKeys
        return changeInfo
    }
    
    public var titleChanged : Bool {
        return changedKeys.contains(#keyPath(ZMMeeting.title))
    }
    
    public var startDateChanged : Bool {
        return changedKeys.contains(#keyPath(ZMMeeting.startDate))
    }

    public var muteAllStateChanged : Bool {
        return changedKeys.contains(#keyPath(ZMMeeting.muteAllRawValue))
    }

    public var stateChanged : Bool {
        return changedKeys.contains(#keyPath(ZMMeeting.stateRawValue))
    }

    public var notificationStateChanged : Bool {
        return changedKeys.contains(#keyPath(ZMMeeting.notificationStateRawValue))
    }
    
    public var callingDateChanged : Bool {
        return changedKeys.contains(#keyPath(ZMMeeting.callingDate))
    }
    
}

public protocol MeetingObserver : NSObjectProtocol {
    func meetingDidChange(_ changeInfo: MeetingChangeInfo)
}

extension MeetingChangeInfo {
    
    // MARK: Registering MeetingObservers
    
    /// Adds an observer for a meeting
    ///
    /// You must hold on to the token and use it to unregister
    public static func add(observer: MeetingObserver, for meeting: ZMMeeting) -> NSObjectProtocol {
        return add(observer: observer, for: meeting, managedObjectContext: meeting.managedObjectContext!)
    }
    
    /// Adds an observer for the meeting if one specified or to all Meetings is none is specified
    ///
    /// You must hold on to the token and use it to unregister
    public static func add(observer: MeetingObserver, for meeting: ZMMeeting?, managedObjectContext: NSManagedObjectContext) -> NSObjectProtocol {
        return ManagedObjectObserverToken(name: .MeetingChange, managedObjectContext: managedObjectContext, object: meeting)
        { [weak observer] (note) in
            guard let `observer` = observer,
                let changeInfo = note.changeInfo as? MeetingChangeInfo
                else { return }
            observer.meetingDidChange(changeInfo)
        }
    }
    
}

extension Notification.Name {
    static let meetingListDidReload = Notification.Name("meetingListDidReload")
}

extension NSManagedObjectContext {
    
    static let MeetingListObserverCenterIden = "MeetingListObserverCenterIden"

    @objc public var meetingListObserverCenter : MeetingListObserverCenter {
        assert(zm_isUserInterfaceContext, "MeetingListObserverCenter does not exist in syncMOC")
        
        if let observer = self.userInfo[NSManagedObjectContext.MeetingListObserverCenterIden] as? MeetingListObserverCenter {
            return observer
        }
        
        let newObserver = MeetingListObserverCenter(managedObjectContext: self)
        self.userInfo[NSManagedObjectContext.MeetingListObserverCenterIden] = newObserver
        return newObserver
    }
}

//监听整个meetingList的改变，如插入，删除
public class MeetingListObserverCenter : NSObject, ChangeInfoConsumer {

    /// Map of Meeting to snapshot
    internal var snapshots : [UUID : SearchUserSnapshot] = [:]
    
    weak var managedObjectContext: NSManagedObjectContext?

    init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
    }
    
    //监听到单个会议的属性改变，目前也发 meetingListDidReload 这个通知
    public func objectsDidChange(changes: [ClassIdentifier: [ObjectChangeInfo]]) {
        if let meetingChanges = changes[ZMMeeting.classIdentifier] as? [MeetingChangeInfo] {
            meetingChanges.forEach{meetingDidChange($0)}
        }
    }
    
    private func meetingDidChange(_ info: MeetingChangeInfo) {
        guard info.callingDateChanged || info.notificationStateChanged || info.stateChanged else { return }
        notify()
    }
    
    /// 这里只关注新增的以及删除的
    func meetingListChanges(inserted: [ZMMeeting], deleted: [ZMMeeting]) {
        if deleted.count == 0 && inserted.count == 0 { return }
        notify()
    }
    
    private func notify() {
        guard let managedObjectContext = managedObjectContext else { return }
        NotificationInContext.init(name: .meetingListDidReload, context: managedObjectContext.notificationContext).post()
    }
    
    public func startObserving() {
        // do nothing
    }
    
    public func stopObserving() {
        // do nothing
    }
    
}

public protocol ZMMeetingListObserver : NSObjectProtocol {
    func meetingListsDidChange()
}

extension MeetingListObserverCenter {
    
    public static func addMeetingListObserver(_ observer: ZMMeetingListObserver, managedObjectContext: NSManagedObjectContext) -> NSObjectProtocol {
        return ManagedObjectObserverToken(name: .meetingListDidReload, managedObjectContext: managedObjectContext, block: { [weak observer] _ in
            observer?.meetingListsDidChange()
        })
    }
}
