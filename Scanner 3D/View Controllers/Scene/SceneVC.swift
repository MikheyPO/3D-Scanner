//
//  SceneVC.swift
//  Scanner 3D
//
//  Created by Vladislav Mikheenko on 20.11.2022.
//

import SceneKit
import SceneKit.ModelIO

class SceneVC: UIViewController {
    
    //MARK: UI
    @IBOutlet weak var scnView: SCNView!
    
    //MARK: properties
    var modelName: String?
    private let dataManager = DataStorageManager()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let wrapName = modelName {
            if let url = dataManager.getFileUrl(for: wrapName) {
                do {
                    scnView.scene = try SCNScene(url: url)
                } catch let error {
                    print("error is \(error)")
                }
            }
        }
        
    }

}
