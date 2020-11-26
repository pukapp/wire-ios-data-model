//
//  GroupIdentifier.swift
//  WireDataModel
//
//  Created by 王杰 on 2020/11/3.
//  Copyright © 2020 Wire Swiss GmbH. All rights reserved.
//

import Foundation

@objcMembers public class AppGroupInfo: NSObject {
    
    public static var sharedUserDefaults: UserDefaults {
        return UserDefaults(suiteName: AppGroupInfo.appGroupIdentifier)!
    }
    
    public static let appGroupIdentifier = Bundle.main.infoDictionary?["ApplicationGroupIdentifier"] as! String
}
