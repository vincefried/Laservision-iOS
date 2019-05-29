//
//  SetupViewModel.swift
//  EyeFighter
//
//  Created by Vincent Friedrich on 29.05.19.
//  Copyright © 2019 neoxapps. All rights reserved.
//

import Foundation

protocol SetupViewModelDelegate {
    func updateUINeeded()
}

class SetupViewModel {
    var titleText: String = ""
    var descriptionText: String = ""
    var isDescriptionLabelHidden: Bool = false
    
    var delegate: SetupViewModelDelegate?
    
    let bluetoothWorker: BluetoothWorker
    
    init(calibrationState: CalibrationState, bluetoothWorker: BluetoothWorker) {
        self.bluetoothWorker = bluetoothWorker
        handleStateChange(calibrationState: calibrationState)
    }
    
    func handleStateChange(calibrationState: CalibrationState) {
        switch calibrationState {
        case .initial:
            titleText = "Not calibrated"
            descriptionText = "Tap to start"
        case .center:
            titleText = "Look to center"
            descriptionText = "Tap to set"
        case .right:
            titleText = "Look right"
            descriptionText = "Tap to set"
        case .down:
            titleText = "Look down"
            descriptionText = "Tap to set"
        case .left:
            titleText = "Look left"
            descriptionText = "Tap to set"
        case .up:
            titleText = "Look up"
            descriptionText = "Tap to finish"
        case .done:
            titleText = "Calibration done"
            descriptionText = ""
        }
        
        isDescriptionLabelHidden = calibrationState == .done
        
        let border = Calibration.getCalibrationBorder(for: calibrationState)
        let command = ControlXYCommand(x: border.x, y: border.y)
        bluetoothWorker.send(command)
        
        delegate?.updateUINeeded()
    }
}
