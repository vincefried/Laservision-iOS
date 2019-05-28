//
//  SettingsWorker.swift
//  EyeFighter
//
//  Created by Vincent Friedrich on 28.05.19.
//  Copyright © 2019 neoxapps. All rights reserved.
//

import Foundation

class SettingsWorker {
    private enum SettingsKey: String {
        case debugMode = "debug_mode"
    }
    
    var isDebugModeEnabled: Bool {
        set {
            UserDefaults.standard.set(newValue, forKey: SettingsKey.debugMode.rawValue)
        }
        
        get {
            return UserDefaults.standard.bool(forKey: SettingsKey.debugMode.rawValue)
        }
    }
}
