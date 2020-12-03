//
// Wire
// Copyright (C) 2018 Wire Swiss GmbH
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
//


import Foundation

extension ZMConversation {
    
    @objc public func deleteOlderMessages() {
        
        guard let managedObjectContext = self.managedObjectContext,
              let clearedTimeStamp = self.clearedTimeStamp,
              !managedObjectContext.zm_isUserInterfaceContext else {
            return
        }
        
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ZMMessage.entityName())
        fetchRequest.predicate = NSPredicate(format: "(%K == %@ OR %K == %@) AND %K <= %@",
                                             ZMMessageConversationKey, self,
                                             ZMMessageHiddenInConversationKey, self,
                                             #keyPath(ZMMessage.serverTimestamp),
                                             clearedTimeStamp as CVarArg)
        
        let result = try! managedObjectContext.fetch(fetchRequest) as! [ZMMessage]
        
        for element in result {
            managedObjectContext.delete(element)
        }
        
    }
    
    @objc static public func deleteOlderNeedlessMessages(moc: NSManagedObjectContext) {
        
        //1. (selfConversation 消息删除)
        let selfConversation = ZMConversation.selfConversation(in: moc)
        let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: ZMMessage.entityName())
        fetchRequest.predicate = NSPredicate(format: "%K == %@",
                                              ZMMessageConversationKey, selfConversation)
        let request = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        request.resultType = .resultTypeStatusOnly
        try! moc.execute(request)
        
        //2. TODO
        
    }
    
    //TEST
    @objc static public func lookMessages(moc: NSManagedObjectContext) {
        
//        let managedObjectContext = moc
//        guard !managedObjectContext.zm_isUserInterfaceContext else {
//            return
//        }
        
        //        let fetchRequest1 = NSFetchRequest<NSFetchRequestResult>(entityName: ZMMessage.entityName())
        //
        //        let result1 = try! managedObjectContext.fetch(fetchRequest1) as! [ZMMessage]
        //
        //        print("所有消息数量:  \(result1.count)")
        //
        //
        //        let fetchRequest2 = NSFetchRequest<NSFetchRequestResult>(entityName: ZMMessage.entityName())
        //
        //        fetchRequest2.predicate = NSPredicate(format: "%K != nil",
        //                                             ZMMessageHiddenInConversationKey)
        //
        //        let result2 = try! managedObjectContext.fetch(fetchRequest2) as! [ZMMessage]
        //
        //        print("隐藏的消息数量: \(result2.count)")
        
//                let selfConversation = ZMConversation.selfConversation(in: moc)
//
//                let fetchRequest3 = NSFetchRequest<NSFetchRequestResult>(entityName: ZMMessage.entityName())
//
//                fetchRequest3.predicate = NSPredicate(format: "%K == %@",
//                                                      ZMMessageConversationKey, selfConversation)
//
//                let result3 = try! managedObjectContext.fetch(fetchRequest3) as! [ZMMessage]
//
//                print("同步自己其他设备造成的消息数量:  \(result3.count)")
        
//                let fetchRequest4 = NSFetchRequest<NSFetchRequestResult>(entityName: ZMSystemMessage.entityName())
//
//                let result4 = try! managedObjectContext.fetch(fetchRequest4) as! [ZMSystemMessage]
//
//                print("全部的系统消息数量:  \(result4.count)")
        
        //        let fetchRequest5 = NSFetchRequest<NSFetchRequestResult>(entityName: ZMMessage.entityName())
        //
        //        fetchRequest5.predicate = NSPredicate(format: "%K != nil",
        //                                              ZMMessageConversationKey)
        //
        //        let result5 = try! managedObjectContext.fetch(fetchRequest5) as! [ZMMessage]
        //
        //        print("显示的消息数量: \(result5.count)")
        
//        let fetchRequest6 = NSFetchRequest<NSFetchRequestResult>(entityName: ZMMessage.entityName())
//
//        fetchRequest6.predicate = NSPredicate(format: "visibleInConversation.conversationType = 5")
//
//        let result6 = try! managedObjectContext.fetch(fetchRequest6) as! [ZMMessage]
//
//        print("万人群的消息数量: \(result6.count)")
        
//        let fetchRequest7 = NSFetchRequest<NSFetchRequestResult>(entityName: ZMSystemMessage.entityName())
//
//        fetchRequest7.predicate = NSPredicate(format: "visibleInConversation.conversationType = 5")
//
//        let result7 = try! managedObjectContext.fetch(fetchRequest7) as! [ZMSystemMessage]
//
//        print("万人群中的系统消息数量: \(result7.count)")
    }
}
