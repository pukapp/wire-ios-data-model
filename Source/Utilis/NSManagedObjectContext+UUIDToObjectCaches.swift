//
//  ZMManagedObject+UUIDToObjectCaches.swift
//  WireDataModel
//
//  Created by 王杰 on 2020/10/20.
//  Copyright © 2020 Wire Swiss GmbH. All rights reserved.
//

import Foundation

@objc extension NSManagedObjectContext {
    
    static var UUIDToObjectCaches: [NSManagedObjectContextType.RawValue: NSMapTable<NSString, ZMManagedObject>] = {
        var caches = [NSManagedObjectContextType.RawValue: NSMapTable<NSString, ZMManagedObject>]()
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
    
    
    @objc(getCacheManagedObjectWithuuidString:clazz:)
    public func getCacheManagedObject(uuidString: String?, clazz: AnyClass) -> ZMManagedObject? {
        guard let u = uuidString else {return nil}
        if let threadLocal = NSManagedObjectContext.UUIDToObjectCaches[self.type],
            let object = threadLocal.object(forKey: u as NSString),
            object.isKind(of: clazz){
            return object
        }
        return nil
    }
    
    @objc(setCacheManagedObjectWithuuidString:object:)
    public func setCacheManagedObject(uuidString: String?, object: ZMManagedObject) {
        guard let u = uuidString else {return}
        if let threadLocal = NSManagedObjectContext.UUIDToObjectCaches[self.type]
            {
            threadLocal.setObject(object, forKey: u as NSString)
        }
    }
    
}
