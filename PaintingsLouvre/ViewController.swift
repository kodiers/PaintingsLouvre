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
}
