//
// Wire
// Copyright (C) 2017 Wire Swiss GmbH
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

extension UserClient {
    
    /// Migrate client sessions from using the client identifier only as session identifier
    /// to new client sessions  useing user identifier + client identifier as session identifier.
    /// These have less chances of collision.
    static func migrateAllSessionsClientIdentifiers(in moc: NSManagedObjectContext) {
        guard let selfClient = ZMUser.selfUser(in: moc).selfClient(),
              let request = UserClient.sortedFetchRequest() else {
            // no client? no migration needed
            return
        }
        let allClients = moc.executeFetchRequestOrAssert(request) as! [UserClient]
        selfClient.keysStore.encryptionContext.perform { (session) in
            for client in allClients {
                client.migrateSessionIdentifierFromV1IfNeeded(sessionDirectory: session)
            }
        }
    }
}
