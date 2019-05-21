//
//  Calibration.swift
//  EyeFighter
//
//  Created by Vincent Friedrich on 09.04.19.
//  Copyright © 2019 neoxapps. All rights reserved.
//

import Foundation

enum CalibrationState: String {
    case initial, center, right, left, up, down, done
    
    var next: CalibrationState {
        switch self {
        case .initial:
            return .center
        case .center:
            return .right
        case .right:
            return .down
        case .down:
            return .left
        case .left:
            return .up
        case .up:
            return .done
        case .done:
            return .done
        }
    }
}

protocol CalibrationDelegate {
    func calibrationStateDidChange(to state: CalibrationState)
    func calibrationDidChange(for state: CalibrationState, value: Float)
}

class Calibration {
    var state: CalibrationState = .initial {
        didSet {
            delegate?.calibrationStateDidChange(to: state)
        }
    }
    
    var delegate: CalibrationDelegate?
    
    var centerX: Float? {
        didSet {
            guard let value = centerX else { return }
            delegate?.calibrationDidChange(for: state, value: value)
        }
    }
    var centerY: Float? {
        didSet {
            guard let value = centerY else { return }
            delegate?.calibrationDidChange(for: state, value: value)
        }
    }
    var maxX: Float? {
        didSet {
            guard let value = maxX else { return }
            delegate?.calibrationDidChange(for: state, value: value)
        }
    }
    var minX: Float? {
        didSet {
            guard let value = minX else { return }
            delegate?.calibrationDidChange(for: state, value: value)
        }
    }
    var maxY: Float? {
        didSet {
            guard let value = maxY else { return }
            delegate?.calibrationDidChange(for: state, value: value)
        }
    }
    var minY: Float? {
        didSet {
            guard let value = minY else { return }
            delegate?.calibrationDidChange(for: state, value: value)
        }
    }
    
    func calibrate(to x: Float, y: Float) {
        switch state {
        case .center:
            centerX = x
            centerY = y
        case .right:
            maxX = x
        case .down:
            minY = y
        case .left:
            minX = x
        case .up:
            maxY = y
        default:
            break
        }
    }
    
    func next() {
        state = state.next
    }
    
    func reset() {
        state = .initial
        
        maxX = nil
        maxY = nil
        minX = nil
        minY = nil
    }
    
    static func getCalibrationBorder(for state: CalibrationState) -> (x: Int, y: Int) {
        switch state {
        case .center:
            return (x: 128, y: 128)
        case .right:
            return (x: 100, y: 128)
        case .down:
            return (x: 128, y: 192)
        case .left:
            return (x: 156, y: 128)
        case .up:
            return (x: 128, y: 64)
        case .initial:
            return (x: 128, y: 128)
        case .done:
            return (x: 128, y: 128)
        }
    }
    
    func getPosition(x: Float, y: Float) -> EyePosition? {
        guard let maxX = maxX,
            let minX = minX,
            let maxY = maxY,
            let minY = minY,
            let centerX = centerX,
            let centerY = centerY else { return nil }
        
        let xBorder: Float = x < centerX ? minX : maxX
        let yBorder: Float = y < centerY ? minY : maxY
        
        let xFactor: Float = (Float(Calibration.getCalibrationBorder(for: .right).x) - Float(Calibration.getCalibrationBorder(for: .center).x))
            / abs(xBorder)
        let yFactor: Float = (Float(Calibration.getCalibrationBorder(for: .up).y) - Float(Calibration.getCalibrationBorder(for: .center).y))
            / abs(yBorder)
        
        let newX: Float = xFactor * x + Float(Calibration.getCalibrationBorder(for: .center).x)
        let newY: Float = yFactor * y + Float(Calibration.getCalibrationBorder(for: .center).y)
        
        return EyePosition(x: Int(newX), y: Int(newY))
    }
}
