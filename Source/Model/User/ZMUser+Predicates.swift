////
// Wire
// Copyright (C) 2019 Wire Swiss GmbH
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
import WireUtilities

extension ZMUser {
    
    /// Retrieves all users (excluding bots), having ZMConnectionStatusAccepted connection statuses.
    @objc static var predicateForConnectedNonBotUsers: NSPredicate {
        return predicateForUsers(withSearch: "", connectionStatuses: [ZMConnectionStatus.accepted.rawValue])
    }
    
    /// Retrieves connected users with name or handle matching search string
    ///
    /// - Parameter query: search string
    /// - Returns: predicate having search query and ZMConnectionStatusAccepted connection statuses
    @objc(predicateForConnectedUsersWithSearchString:)
    public static func predicateForConnectedUsers(withSearch query: String) -> NSPredicate {
        return predicateForUsers(withSearch: query, connectionStatuses: [ZMConnectionStatus.accepted.rawValue])
    }
    
    /// Retrieves all users with name or handle matching search string
    ///
    /// - Parameter query: search string
    /// - Returns: predicate having search query
    public static func predicateForAllUsers(withSearch query: String) -> NSPredicate {
        return predicateForUsers(withSearch: query, connectionStatuses: nil)
    }
    
    /// Retrieves users with name or handle matching search string, having one of given connection statuses
    ///
    /// - Parameters:
    ///   - query: search string
    ///   - connectionStatuses: an array of connections status of the users. E.g. for connected users it is [ZMConnectionStatus.accepted.rawValue]
    /// - Returns: predicate having search query and supplied connection statuses
    @objc(predicateForUsersWithSearchString:connectionStatusInArray:)
    public static func predicateForUsers(withSearch query: String, connectionStatuses: [Int16]? ) -> NSPredicate {
        var allPredicates = [[NSPredicate]]()
        if let statuses = connectionStatuses {
            allPredicates.append([predicateForUsers(withConnectionStatuses: statuses)])
        }
        
        if !query.isEmpty {
            /*新增根据备注搜索用户
                1.reMark代表设置的备注如：钢铁侠老板
                2.normalizedRemark是通过reMark生成的英文字符串如：gang tie xia lao ban
             输入“老”
             remarkPredicate匹配的是否包含“老”字符串
             normalizedRemarkPredicate匹配的是 英文字符串'gang tie xia lao ban'中五个单词，是否有任意单词以‘lao’开头
             */
            let remarkPredicate = NSPredicate.init(format: "reMark MATCHES %@", ".*\(query).*")
            let normalizedRemarkPredicate = NSPredicate(formatDictionary: [#keyPath(ZMUser.normalizedRemark) : "%K MATCHES %@"], matchingSearch: query)
            
            let namePredicate = NSPredicate(formatDictionary: [#keyPath(ZMUser.normalizedName) : "%K MATCHES %@"], matchingSearch: query)
            let handlePredicate = NSPredicate(format: "%K BEGINSWITH %@", #keyPath(ZMUser.handle), query.strippingLeadingAtSign())
            allPredicates.append([remarkPredicate, normalizedRemarkPredicate, namePredicate, handlePredicate].compactMap {$0})
        }
        
        let orPredicates = allPredicates.map { NSCompoundPredicate(orPredicateWithSubpredicates: $0) }
        
        return NSCompoundPredicate(andPredicateWithSubpredicates: orPredicates)
    }
    
    @objc(predicateForUsersWithConnectionStatusInArray:)
    public static func predicateForUsers(withConnectionStatuses connectionStatuses: [Int16]) -> NSPredicate {
        return NSPredicate(format: "(%K IN (%@))", #keyPath(ZMUser.connection.status), connectionStatuses)
    }
    
    public static func predicateForUsersToUpdateRichProfile() -> NSPredicate {
        return NSPredicate(format: "(%K == YES)", #keyPath(ZMUser.needsRichProfileUpdate))
    }
}
