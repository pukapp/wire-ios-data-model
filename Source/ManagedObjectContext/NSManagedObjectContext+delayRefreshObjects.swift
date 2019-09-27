//
//  NSManagedObjectContext+delayRefreshObjects.swift
//  WireDataModel
//
//  Created by 王杰 on 2019/9/27.
//  Copyright © 2019 Wire Swiss GmbH. All rights reserved.
//

import Foundation

extension NSManagedObjectContext {
    
    static let RefreshObjectsTimeStampKey = "RefreshObjectsTimeStampKey"
    
    static let TWO_MINUTE: Double = 3 * 60
    
    @objc
    public var shouldRefreshObjects: Bool {
        if let lastRefreshDate = self.refreshObjectsTimeStamp {
            let seconds = NSDate().timeIntervalSince(lastRefreshDate)
            if seconds > NSManagedObjectContext.TWO_MINUTE {
                resetRefreshObjectsTimeStamp()
                return true
            }
            return false
        }
        resetRefreshObjectsTimeStamp()
        return true
    }
    
    var refreshObjectsTimeStamp: Date? {
        set {
            guard let date = newValue else {return}
            self.setPersistentStoreMetadata(date, key: NSManagedObjectContext.RefreshObjectsTimeStampKey)
        }
        get {
            if let date = self.persistentStoreMetadata(forKey: NSManagedObjectContext.RefreshObjectsTimeStampKey) as? Date {
                return date
            }
            return nil
        }
    }
    
    private func resetRefreshObjectsTimeStamp() {
        self.refreshObjectsTimeStamp = Date()
        self.saveOrRollback()
    }
    
}
