//
//  EditMessageProcessRecorder.swift
//  WireDataModel
//
//  Created by wj on 2020/12/23.
//  Copyright © 2020 Wire Swiss GmbH. All rights reserved.
//

import Foundation

@objcMembers
public class EditMessageProcessRecorder: NSObject {
    
    static let shared = EditMessageProcessRecorder()
    
    let maxSize = 100
    
    let defaults = AppGroupInfo.instance.sharedUserDefaults
    
    let EditMessageIdsProcessedInExtensionKey = "EditMessageIdsProcessedInExtensionKey"
    
    private var editMessageIds: [String] = []
    
    override init() {
        super.init()
        self.refreshIdsInMemory()
    }
    
    func applicationWillEnterForeground() {
        self.refreshIdsInMemory()
    }
    
    func applicationDidEnterBackground() {
        synchronization()
    }
    
    private func refreshIdsInMemory() {
        if let ids = defaults.array(forKey: EditMessageIdsProcessedInExtensionKey) as? [String] {
            editMessageIds = ids
        } else {
            defaults.setValue([], forKey: EditMessageIdsProcessedInExtensionKey)
            editMessageIds = []
        }
    }
    
    func addMessageEdited(messageId: String) {
        if editMessageIds.count > maxSize {
            editMessageIds = editMessageIds.secretSuffix(count: maxSize/2)
        }
        editMessageIds.append(messageId)
        synchronization()
    }
    
    func exist(messageId: String) -> Bool {
        let exist = editMessageIds.contains(messageId)
        return exist
    }
    
    func remove(messageId: String) {
        if let index = editMessageIds.firstIndex(of: messageId) {
            editMessageIds.remove(at: index)
            synchronization()
        }
    }
    
    func removeAll() {
        editMessageIds = []
        synchronization()
    }
    
    
    func synchronization() {
        defaults.setValue(editMessageIds, forKey: EditMessageIdsProcessedInExtensionKey)
    }
}

