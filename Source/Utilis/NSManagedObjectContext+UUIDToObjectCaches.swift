//
//  ZMManagedObject+UUIDToObjectCaches.swift
//  WireDataModel
//
//  Created by 王杰 on 2020/10/20.
//  Copyright © 2020 Wire Swiss GmbH. All rights reserved.
//

import Foundation

@objc extension NSManagedObjectContext {
    
    static var UUIDToObjectCaches: [NSManagedObjectContextType.RawValue: NSMapTable<NSUUID, ZMManagedObject>] = {
        var caches = [NSManagedObjectContextType.RawValue: NSMapTable<NSUUID, ZMManagedObject>]()
        caches[NSManagedObjectContextType.msg.rawValue] = NSMapTable.strongToWeakObjects()
        caches[NSManagedObjectContextType.ui.rawValue] = NSMapTable.strongToWeakObjects()
        caches[NSManagedObjectContextType.sync.rawValue] = NSMapTable.strongToWeakObjects()
        caches[NSManagedObjectContextType.search.rawValue] = NSMapTable.strongToWeakObjects()
        return caches
    }()
    
    typealias UUIDString = String
    
    enum NSManagedObjectContextType: String {
        case ui
        case sync
        case msg
        case search
    }
    
    var type: String {
        if self.zm_isSyncContext {
            return NSManagedObjectContextType.sync.rawValue
        }
        if self.zm_isMsgContext {
            return NSManagedObjectContextType.msg.rawValue
        }
        if self.zm_isUserInterfaceContext {
            return NSManagedObjectContextType.ui.rawValue
        }
        if self.zm_isSearchContext {
            return NSManagedObjectContextType.search.rawValue
        }
        return NSManagedObjectContextType.sync.rawValue
    }
    
    
    @objc(getCacheManagedObjectWithUUID:)
    public func getCacheManagedObject(uuid: UUID?) -> ZMManagedObject? {
        guard let u = uuid else {return nil}
        if let threadLocal = NSManagedObjectContext.UUIDToObjectCaches[self.type] , let object = threadLocal.object(forKey: u as NSUUID) {
            return object
        }
        return nil
    }
    
    @objc(setCacheManagedObjectWithUUID:object:)
    public func setCacheManagedObject(uuid: UUID?, object: ZMManagedObject) {
        guard let u = uuid else {return}
        if let threadLocal = NSManagedObjectContext.UUIDToObjectCaches[self.type]
            {
            threadLocal.setObject(object, forKey: u as NSUUID)
        }
    }
    
}
