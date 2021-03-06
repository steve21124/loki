//
//  TrainerViewController.swift
//  nwHacks2018
//
//  Created by Nathan Tannar on 1/13/18.
//  Copyright © 2018 Nathan Tannar. All rights reserved.
//

import UIKit
import ARKit

class TrainerViewController: FaceTrackerController {
    
    lazy var tableView: UITableView = {
        let tableView = UITableView()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.tableFooterView = UIView()
        tableView.contentInset.bottom = 100
        return tableView
    }()
    
    var blendShapes = [ARFaceAnchor.BlendShapeLocation : NSNumber]()
    
    // MARK: - Initialization
 
    override init() {
        super.init()
        title = "CoreML Trainer"
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    // MARK: - View Life Cycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        sceneView.isHidden = true
        view.backgroundColor = .white
        tableView.frame = view.bounds
        view.addSubview(tableView)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .play,
                                                           target: self,
                                                           action: #selector(resumeCapture))
        navigationItem.leftBarButtonItem?.isEnabled = false
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera,
                                                            target: self,
                                                            action: #selector(captureCurrentEmption))
    }
    
    // MARK: - User Actions
    
    @objc
    func captureCurrentEmption() {
        
        playChime()
        pauseCapture()
        
        
        let actionSheet = UIAlertController(title: "Save", message: "What Emotion is this?", preferredStyle: .actionSheet)
        Emotion.all().forEach { emotion in
            let action = UIAlertAction(title: emotion.rawValue.capitalized, style: .default, handler: { _ in
                
                guard let record = FaceRecord.create(for: emotion, anchors: self.blendShapes) else {
                    Ping(text: "Oops! No FaceRecord Was Captured", style: .danger).show()
                    return
                }
                record.saveInBackground()
                Ping(text: "Sent FaceRecord Model to Neural Net", style: .info).show()
                self.resumeCapture()
            })
            actionSheet.addAction(action)
        }
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true, completion: nil)
    }
    
    // MARK: - ARKit
  
    func playChime() {
        AudioServicesPlaySystemSound(1075)
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        
        guard let faceAnchor = anchor as? ARFaceAnchor else { return }
        blendShapes = faceAnchor.blendShapes
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }
    }

}

extension TrainerViewController: UITableViewDataSource, UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return blendShapes.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        cell.textLabel?.text = Array(blendShapes.keys)[indexPath.row].rawValue
        
        let probability = Array(blendShapes.values)[indexPath.row].doubleValue
        
        cell.detailTextLabel?.text = "\(probability)"
        cell.detailTextLabel?.textColor = .darkGray
        cell.detailTextLabel?.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        
        if probability >= 0.7 {
            cell.detailTextLabel?.textColor = .green
        } else if probability > 0.25 {
            cell.detailTextLabel?.textColor = .orange
        } else {
            cell.detailTextLabel?.textColor = .red
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
    }
}
