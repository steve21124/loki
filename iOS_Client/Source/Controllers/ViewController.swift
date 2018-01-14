//
//  ViewController.swift
//  nwHacks2018
//
//  Created by Nathan Tannar on 1/13/18.
//  Copyright © 2018 Nathan Tannar. All rights reserved.
//

import UIKit
import ARKit

class ViewController: UIViewController {
    
    var faceTrackingConfig: ARFaceTrackingConfiguration {
        let configuration = ARFaceTrackingConfiguration()
        configuration.isLightEstimationEnabled = true
        return configuration
    }
    
    lazy var sceneView: ARSCNView = {
        let sceneView = ARSCNView(frame: view.bounds)
        sceneView.automaticallyUpdatesLighting = true
        sceneView.isHidden = true
        sceneView.delegate = self
        return sceneView
    }()
    
    var session: ARSession {
        return sceneView.session
    }
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()
    
    var blendShapes = [ARFaceAnchor.BlendShapeLocation : NSNumber]()
    
    // MARK: - Initialization
 
    public init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = "Emotion Tracker"
        view.backgroundColor = .white
        tableView.frame = view.bounds
        view.addSubview(tableView)
        view.addSubview(sceneView)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .play,
                                                           target: self,
                                                           action: #selector(resumeCapture))
        navigationItem.leftBarButtonItem?.isEnabled = false
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera,
                                                            target: self,
                                                            action: #selector(captureCurrentEmption))
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        resumeCapture()
    }
    
    // MARK: - User Actions
    
    @objc
    func captureCurrentEmption() {
        
        playChime()
        session.pause()
        navigationItem.rightBarButtonItem?.isEnabled = false
        navigationItem.leftBarButtonItem?.isEnabled = true
        
        // Send data to backend here //
    }
    
    @objc
    func resumeCapture() {
        
        session.run(faceTrackingConfig, options: [.resetTracking, .removeExistingAnchors])
        navigationItem.rightBarButtonItem?.isEnabled = true
        navigationItem.leftBarButtonItem?.isEnabled = false
    }
    
    // MARK: - ARKit
  
    func playChime() {
        AudioServicesPlaySystemSound(1075)
    }

}

extension ViewController: ARSCNViewDelegate {
    
    public func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        blendShapes = faceAnchor.blendShapes
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
        
        let emotion = Emotion.recognized(in: anchor)
        print(emotion)
    }
}

extension ViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blendShapes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = Array(blendShapes.keys)[indexPath.row].rawValue
        cell.detailTextLabel?.text = "\(Array(blendShapes.values)[indexPath.row])"
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
