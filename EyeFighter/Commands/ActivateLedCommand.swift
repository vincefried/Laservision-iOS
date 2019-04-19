//
//  LedCommand.swift
//  MobileSystemeListe
//
//  Created by Vincent Friedrich on 16.04.19.
//  Copyright © 2019 neoxapps. All rights reserved.
//

import Foundation

struct ActivateLedCommand: ArduinoCommand {
    var c: Command = .activate
    
    enum LedState: String, Codable {
        case on, off
    }
    
    let s: LedState
    
    init(_ ledState: LedState) {
        self.s = ledState
    }
}

