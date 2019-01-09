//
//  ViewController.swift
//  PaintingsLouvre
//
//  Created by Viktor Yamchinov on 28/12/2018.
//  Copyright © 2018 Viktor Yamchinov. All rights reserved.
//

import UIKit
import SceneKit
import ARKit
import WebKit

class ViewController: UIViewController, ARSCNViewDelegate {

    @IBOutlet var sceneView: ARSCNView!
    
    var paintings = [String: Painting]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loadData()
        
        let preload = WKWebView()
        view.addSubview(preload)
        let request = URLRequest(url: URL(string: "https://en.wikipedia.org/wiki/Mona_Lisa")!)
        preload.load(request)
        preload.removeFromSuperview()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARImageTrackingConfiguration()
        guard let trackingImages = ARReferenceImage.referenceImages(inGroupNamed: "Paintings", bundle: nil) else {
            fatalError("Could not load tracking images")
        }
        configuration.trackingImages = trackingImages

        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }

    // MARK: - ARSCNViewDelegate
    
/*
    // Override to create and configure nodes for anchors added to the view's session.
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        let node = SCNNode()
     
        return node
    }
*/
    
    func loadData() {
        // find JSON file in our bundle
        guard let url = Bundle.main.url(forResource: "paintings", withExtension: "json") else {
            fatalError("Unable to find paintings.json in bundle")
        }
        // convert that to a Data instance
        guard let data = try? Data(contentsOf: url) else {
            fatalError("Unable to load paintings.json")
        }
        // and decode it to dictionary
        let decoder = JSONDecoder()
        guard let loadedPaintings = try? decoder.decode([String: Painting].self, from: data) else {
            fatalError("Unable to parse paintings.json")
        }
        paintings = loadedPaintings
    }
    
    func renderer(_ renderer: SCNSceneRenderer, nodeFor anchor: ARAnchor) -> SCNNode? {
        guard let imageAnchor = anchor as? ARImageAnchor else {
            return nil
        }
        guard let paintingName = imageAnchor.referenceImage.name else {
            return nil
        }
        guard let painting = paintings[paintingName] else {
            return nil
        }
        let plane = SCNPlane(width: imageAnchor.referenceImage.physicalSize.width, height: imageAnchor.referenceImage.physicalSize.height)
        plane.firstMaterial?.diffuse.contents = UIColor.clear
        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi / 2
        let node = SCNNode()
        node.opacity = 0
        node.addChildNode(planeNode)
        // define a constant for spacing, allowing us to space nodes neatly on the screen
        let spacing: Float = 0.005
        // create a text node with our title
        let titleNode = textNode(painting.title, font: UIFont.boldSystemFont(ofSize: 10))
        // position from its top left
        titleNode.pivotOnTopLeft()
        // move it to the top right edge of our painting
        titleNode.position.x += Float(plane.width / 2) + spacing
        titleNode.position.y += Float(plane.height / 2)
        // and add it to the plane node
        planeNode.addChildNode(titleNode)
        let painterNode = textNode(painting.artist, font: UIFont.systemFont(ofSize: 8))
        painterNode.pivotOnTopCenter()
        painterNode.position.y -= Float(plane.height / 2) + spacing
        planeNode.addChildNode(painterNode)
        let yearNode = textNode(painting.year, font: UIFont.systemFont(ofSize: 6))
        yearNode.pivotOnTopCenter()
        yearNode.position.y = painterNode.position.y - spacing - painterNode.height
        planeNode.addChildNode(yearNode)
        
        let detailsWidth = max(titleNode.width, 0.25)
        let detailsHeight = (Float(plane.height) - titleNode.height) + painterNode.height + yearNode.height + (spacing * 2)
        let detailsPlane = SCNPlane(width: CGFloat(detailsWidth), height: CGFloat(detailsHeight))
        let detailsNode = SCNNode(geometry: detailsPlane)
        detailsNode.pivotOnTopLeft()
        detailsNode.position.x += Float(plane.width / 2) + spacing
        detailsNode.position.y = titleNode.position.y - titleNode.height - spacing
        planeNode.addChildNode(detailsNode)
        
        DispatchQueue.main.async {
            let width: CGFloat = 800
            let height = width / (detailsPlane.width / detailsPlane.height)
            let webView = WKWebView(frame: CGRect(x: 0, y: 0, width: width, height: height))
            let request = URLRequest(url: painting.url)
            webView.load(request)
            detailsPlane.firstMaterial?.diffuse.contents = webView
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                SCNTransaction.animationDuration = 1
                node.opacity = 1
            })
        }
        
        return node
    }
    
    func textNode(_ str: String, font: UIFont) -> SCNNode {
        // create flat text geometry from our string
        let text = SCNText(string: str, extrusionDepth: 0.0)
        // make it un-flat as possible, with causes the corners of letters to be rounded smoothly
        text.flatness = 0.1
        // assign a font
        text.font = font
        // wrap font in new node
        let textNode = SCNNode(geometry: text)
        // and scale that node down to a tiny fraction of its size
        textNode.scale = SCNVector3(0.002, 0.002, 0.002)
        // send it back so it can be positioned on our scene
        return textNode
    }
}


extension SCNNode {
    var width: Float {
        return (boundingBox.max.x - boundingBox.min.x) * scale.x
    }
    
    var height: Float {
        return (boundingBox.max.y - boundingBox.min.y) * scale.y
    }
    
    func pivotOnTopLeft() {
        let (min, max) = boundingBox
        pivot = SCNMatrix4MakeTranslation(min.x, (max.y - min.y) + min.y, 0)
    }
    
    func pivotOnTopCenter() {
        let (min, max) = boundingBox
        pivot = SCNMatrix4MakeTranslation((max.x - min.x) / 2 + min.x, (max.y - min.y) + min.y, 0)
    }
}
