//
//  ViewController.swift
//  MagicHat
//
//  Created by Olivia Cane on 7/31/18.
//  Copyright © 2018 Olivia Cane. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    var hatPlaced = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        let throwButton = UIButton()
        throwButton.frame = CGRect(x: view.frame.size.width/2.0 - 50, y: view.frame.size.height - 100, width: 100, height: 40)
        throwButton.backgroundColor = UIColor.white
        throwButton.setTitle("Throw", for: .normal)
        throwButton.setTitleColor(UIColor.black, for: .normal)
        throwButton.addTarget(self, action: #selector(throwButtonClicked), for: UIControlEvents.touchUpInside)
        
        sceneView.delegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        sceneView.scene = SCNScene()
        
        
        sceneView.addSubview(throwButton)
        //let floor = SCNFloor()
        //floor.width = 4
        //floor.length = 4
        //let floorNode = SCNNode(geometry: floor)
        //floorNode
        //sceneView.scene.rootNode.addChildNode(floorNode)
        
        //sceneView.debugOptions = [.showPhysicsShapes]
 
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    @IBAction func tapPlane(_ sender: UITapGestureRecognizer) {
    // Get tap location
    let tapLocation = sender.location(in: sceneView)
    
    // Perform hit test
    let results = sceneView.hitTest(tapLocation, types: .existingPlaneUsingExtent)
    
    // If a hit was received, get position of
    if let result = results.first {
        //NO HAT YET
        if(!hatPlaced){
           placeHat(result)
            let plane = sceneView.scene.rootNode.childNode(withName: "planeNode", recursively: true)
           plane?.isHidden = true
           hatPlaced = true
        }
    }
    }

   private func placeHat(_ result: ARHitTestResult) {
    // Get transform of result
    let transform = result.worldTransform
    
    // Get position from transform (4th column of transformation matrix)
    let planePosition = SCNVector3Make(transform.columns.3.x, transform.columns.3.y, transform.columns.3.z)
    
    // Add Hat
    
    let hatNode = createObjectFromScene(planePosition, object: "art.scnassets/hat")
    sceneView.scene.rootNode.addChildNode(hatNode!)
   }

    private func createObjectFromScene(_ position: SCNVector3, object: String) -> SCNNode? {
        guard let url = Bundle.main.url(forResource: object, withExtension: "scn") else {
            NSLog("Could not find hat scene")
            return nil
        }
        guard let node = SCNReferenceNode(url: url) else { return nil }
        
        node.load()
        
        // Position scene
        node.position = position
        
        return node
    }
    
    @objc func throwButtonClicked(sender: UIButton!){
        //force
        let force = simd_make_float4(0, 0, -3, 0)
        
        //create ball
        let ball =  SCNSphere(radius: 0.03)
        let ballNode = SCNNode(geometry: ball)
        ballNode.physicsBody?.friction = 1
        ballNode.physicsBody = SCNPhysicsBody(type: .dynamic, shape: nil)
        ballNode.physicsBody?.allowsResting = true
        ballNode.physicsBody?.isAffectedByGravity = true
        ballNode.physicsBody?.collisionBitMask = -1
        
       //move ball in front of phone
       let camera = sceneView.session.currentFrame?.camera
       let cameraTransform = camera?.transform
       ballNode.simdTransform = cameraTransform!
       sceneView.scene.rootNode.addChildNode(ballNode)
        
        //throw ball
        let rotatedForce = simd_mul(cameraTransform!, force)
        let vectorForce = SCNVector3(x:rotatedForce.x, y:rotatedForce.y, z:rotatedForce.z)
0
        ballNode.physicsBody?.applyForce(vectorForce, asImpulse: true)
    }

    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Release any cached data, images, etc that aren't in use.
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    private var planeNode: SCNNode?
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        // Create an SCNNode for a detect ARPlaneAnchor
        guard let _ = anchor as? ARPlaneAnchor else {
            return nil
        }
        planeNode = SCNNode()
        return planeNode
    }
    
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Create an SNCPlane on the ARPlane
        guard let planeAnchor = anchor as? ARPlaneAnchor else {
            return
        }
        
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        
        let planeMaterial = SCNMaterial()
        planeMaterial.diffuse.contents = UIColor(red: 255/255, green: 255/255, blue: 255/255, alpha: 0.3)
        plane.materials = [planeMaterial]
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.position = SCNVector3Make(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi / 2, 1, 0, 0)
        
        node.addChildNode(planeNode)
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        // Present an error message to the user
        
    }
    
    func sessionWasInterrupted(_ session: ARSession) {
        // Inform the user that the session has been interrupted, for example, by presenting an overlay
        
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        // Reset tracking and/or remove existing anchors if consistent tracking is required
        
    }
}
