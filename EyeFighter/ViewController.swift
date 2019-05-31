//
//  ViewController.swift
//  EyeFighter
//
//  Created by Vincent Friedrich on 02.04.19.
//  Copyright © 2019 neoxapps. All rights reserved.
//

import UIKit
import ARKit
import FTLinearActivityIndicator

class ViewController: UIViewController {
    
    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var connectingLabel: UILabel!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var visualEffectView: UIVisualEffectView!
    @IBOutlet weak var setupView: UIView!
    @IBOutlet weak var faceActivityIndicator: FTLinearActivityIndicator!
    @IBOutlet weak var upperContainerView: UIVisualEffectView!
    @IBOutlet weak var setupTitleLabel: UILabel!
    @IBOutlet weak var setupDescriptionLabel: UILabel!
    
    var faceAnchor: ARFaceAnchor?
    var leftPupil: Pupil?
    var rightPupil: Pupil?
    var arrow: Arrow?
    
    let calibration = Calibration()
    
    let bluetoothWorker = BluetoothWorker()
    let settingsWorker = SettingsWorker()
    
    var setupViewModel: SetupViewModel!
    var connectionViewModel: ConnectionViewModel!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(didTap)))
        view.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(didLongPress)))

        visualEffectView.layer.cornerRadius = 10
        visualEffectView.layer.masksToBounds = true
        
        setupUpperContainerView()
        setupARView()
        
        faceActivityIndicator.hidesWhenStopped = true
        faceActivityIndicator.tintColor = .white
        
        calibration.delegate = self
        bluetoothWorker.delegate = self
        
        setupViewModel = SetupViewModel(calibrationState: calibration.state, isFaceDetected: calibration.isFaceDetected, bluetoothWorker: bluetoothWorker)
        setupViewModel.delegate = self
        updateSetupContainerUI()
        
        connectionViewModel = ConnectionViewModel(state: bluetoothWorker.connectionState, bluetoothWorker: bluetoothWorker)
        connectionViewModel.delegate = self
        updateConnectionContainerUI()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in self?.bluetoothWorker.scanAndConnect() }
    }
    
    private func updateConnectionContainerUI() {
        connectingLabel.text = connectionViewModel.connectionText
        connectingLabel.textColor = connectionViewModel.connectionTextColor
        
        refreshButton.isHidden = connectionViewModel.isRefreshButtonHidden
        
        if connectionViewModel.isAnimating {
            activityIndicator.startAnimating()
        } else {
            activityIndicator.stopAnimating()
        }
    }
    
    private func updateSetupContainerUI() {
        setupTitleLabel.text = setupViewModel.titleText
        setupTitleLabel.textColor = setupViewModel.titleTextColor
        setupDescriptionLabel.text = setupViewModel.descriptionText

        
        if setupViewModel.isFaceDetected {
            if faceActivityIndicator.isAnimating {
                self.faceActivityIndicator.stopAnimating()
            }
        } else {
            if !faceActivityIndicator.isAnimating {
                self.faceActivityIndicator.startAnimating()
            }
        }
    }
    
    private func setupUpperContainerView() {
        upperContainerView.layer.cornerRadius = 10
        upperContainerView.layer.masksToBounds = true
    }
    
    private func setupARView() {
        guard ARFaceTrackingConfiguration.isSupported else { fatalError("Face ID is not available on this device") }
        
        arrow = Arrow()
        guard let arrow = arrow else { return }
        sceneView.scene.rootNode.addChildNode(arrow)
    }
    
    private func startARView() {
        let configuration = ARFaceTrackingConfiguration()
        
        sceneView.scene.background.contents = UIColor.black
        sceneView.session.run(configuration)
    }
    
    private func pauseARView() {
        sceneView.session.pause()
    }
    
    @objc private func didTap() {
        guard let faceAnchor = faceAnchor, (bluetoothWorker.isConnected || settingsWorker.isDebugModeEnabled) else { return }
        
        if calibration.state == .done {
            guard let position = calibration.getPosition(x: faceAnchor.lookAtPoint.x, y: faceAnchor.lookAtPoint.y) else { return }
            // TODO add labels in debug mode
            print("\(position.x) \(position.y)")
        } else {
            calibration.calibrate(to: faceAnchor.lookAtPoint.x, y: faceAnchor.lookAtPoint.y)
            calibration.next()
        }
    }
    
    @objc private func didLongPress() {
        calibration.reset()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        startARView()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        pauseARView()
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let navigationController = segue.destination as? UINavigationController,
            let settingsViewController = navigationController.viewControllers.first as? SettingsViewController {
            let settingsViewModel = SettingsViewModel(settingsWorker: settingsWorker, bluetoothWorker: bluetoothWorker)
            settingsViewController.viewModel = settingsViewModel
        }
    }
    
    @IBAction func tappedRefreshButton(_ sender: UIButton) {
        connectionViewModel.handleRefreshButtonPressed()
    }
}

extension ViewController: ARSCNViewDelegate {
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let device = sceneView.device else { return nil }
        let faceGeometry = ARSCNFaceGeometry(device: device)
        faceGeometry?.firstMaterial?.fillMode = .lines
        faceGeometry?.firstMaterial?.transparency = 0.05
        let node = SCNNode(geometry: faceGeometry)
        
        leftPupil = Pupil()
        rightPupil = Pupil()
        guard let leftPupil = leftPupil, let rightPupil = rightPupil else { return nil }
        node.addChildNode(leftPupil)
        node.addChildNode(rightPupil)
        
        return node
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didRenderScene scene: SCNScene, atTime time: TimeInterval) {
        guard let pointOfView = sceneView.pointOfView,
            let leftPupil = leftPupil,
            let rightPupil = rightPupil else {
                calibration.isFaceDetected = false
                return
        }

        DispatchQueue.main.async {
            self.calibration.isFaceDetected = self.sceneView.isNode(leftPupil, insideFrustumOf: pointOfView) && self.sceneView.isNode(rightPupil, insideFrustumOf: pointOfView)
        }
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        faceAnchor = anchor as? ARFaceAnchor

        guard let faceAnchor = faceAnchor else { return }
        
        if let leftPupil = leftPupil, let rightPupil = rightPupil {
            leftPupil.update(transform: faceAnchor.leftEyeTransform)
            rightPupil.update(transform: faceAnchor.rightEyeTransform)
        }
        
        if let arrow = arrow, let camera = sceneView.pointOfView {
            arrow.update(position: node.position, camera: camera, calibrationState: calibration.state)
        }
        
        if let faceGeometry = node.geometry as? ARSCNFaceGeometry {
            faceGeometry.update(from: faceAnchor.geometry)
        }
        
        guard let position = calibration.getPosition(x: faceAnchor.lookAtPoint.x, y: faceAnchor.lookAtPoint.y) else { return }
        
        print("x: \(position.x) y: \(position.y)")
        
        let command = ControlXYCommand(direction: position)
        bluetoothWorker.send(command)
    }
}

extension ViewController: SetupViewModelDelegate {
    func updateSetupUINeeded() {
        updateSetupContainerUI()
    }
}

extension ViewController: ConnectionViewModelDelegate {
    func updateConnectionUINeeded() {
        updateConnectionContainerUI()
    }
}

extension ViewController: CalibrationDelegate {
    func calibrationStateDidChange(to state: CalibrationState) {
        setupViewModel.handleStateChange(calibrationState: state)
    }
    
    func calibrationDidChange(for state: CalibrationState, value: Float) {
        print("Saved point \(value) for \(state.rawValue)")
    }
    
    func changedFaceDetectedState(isFaceDetected: Bool) {
        setupViewModel.handleIsFaceDetected(isFaceDetected: isFaceDetected)
    }
}

extension ViewController: BluetoothWorkerDelegate {
    func changedConnectionState(_ state: ConnectionState) {
        connectionViewModel.handleConnectionStateChange(connectionState: state)
    }
    
    func connectedDevice(_ device: BluetoothDevice) {
        print("Successfully connected to \(device.name)")
    }
    
    func disconnectedDevice(_ device: BluetoothDevice) {
        print("Disconnected \(device.name)")
    }
}
