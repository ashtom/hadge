//
//  UserDefaultKeys.swift
//  Hadge
//
//  Created by Thomas Dohmke on 5/5/20.
//  Copyright © 2020 Entire. All rights reserved.
//

import Foundation

class UserDefaultKeys {
    static let interfaceStyle = "interfaceStyle"
    static let lastActivitySyncDate = "lastActivitySyncDate"
    static let lastWorkout = "lastWorkout"
    static let lastSyncDate = "lastSyncDate"
    static let setupFinished = "setupFinished"
    static let workoutFilter = "workoutFilter"
}

enum InterfaceStyle: Int {
    case automatic
    case light
    case dark
}
