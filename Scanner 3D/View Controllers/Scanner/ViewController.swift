//
//  ViewController.swift
//  Scanner 3D
//
//  Created by Vladislav Mikheenko on 18.11.2022.
//

import Foundation
import RealityKit
import ARKit
import ModelIO
import MetalKit
import QuickLook


class ViewController: UIViewController, ARSessionDelegate {

    @IBOutlet weak var arView: ARView!
    
    @IBOutlet weak var saveScane: UIButton! {
        didSet {
            saveScane.setTitle("Save", for: .normal)
        }
    }
    
    let coachingOverlay = ARCoachingOverlayView()
    
    // Cache for 3D text geometries representing the classification values.
    var modelsForClassification: [ARMeshClassification: ModelEntity] = [:]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        arViewConfig()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // Prevent the screen from being dimmed to avoid interrupting the AR experience.
        UIApplication.shared.isIdleTimerDisabled = true
    }
    
    override var prefersHomeIndicatorAutoHidden: Bool {
        return true
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    //MARK: func
    
    private func arViewConfig() {
        arView.session.delegate = self
        
//        setupCoachingOverlay()

        arView.environment.sceneUnderstanding.options = []
        
        // Turn on occlusion from the scene reconstruction's mesh.
        arView.environment.sceneUnderstanding.options.insert(.occlusion)
        
        // Turn on physics for the scene reconstruction's mesh.
        arView.environment.sceneUnderstanding.options.insert(.physics)

        // Display a debug visualization of the mesh.
        arView.debugOptions.insert(.showSceneUnderstanding)
        
        // For performance, disable render options that are not required for this app.
        arView.renderOptions = [.disablePersonOcclusion, .disableDepthOfField, .disableMotionBlur]
        
        // Manually configure what kind of AR session to run since
        // ARView on its own does not turn on mesh classification.
        arView.automaticallyConfigureSession = false
        let configuration = ARWorldTrackingConfiguration()
        configuration.sceneReconstruction = .meshWithClassification
//        configuration.planeDetection = [.horizontal, .vertical]

        configuration.environmentTexturing = .automatic
        arView.session.run(configuration)
    }
    
    private func generate3DModel() {
        guard let frame = arView.session.currentFrame else {
//            fatalError("Couldn't get the current ARFrame")
            print("error")
            return
        }
        
        // Fetch the default MTLDevice to initialize a MetalKit buffer allocator with
        guard let device = MTLCreateSystemDefaultDevice() else {
//            fatalError("Failed to get the system's default Metal device!")
            print("error")
            return
        }
        
        // Using the Model I/O framework to export the scan, so we're initialising an MDLAsset object,
        // which we can export to a file later, with a buffer allocator
        let allocator = MTKMeshBufferAllocator(device: device)
        let asset = MDLAsset(bufferAllocator: allocator)
        
        // Fetch all ARMeshAncors
        let meshAnchors = frame.anchors.compactMap({ $0 as? ARMeshAnchor })
        
        // Convert the geometry of each ARMeshAnchor into a MDLMesh and add it to the MDLAsset
        for meshAncor in meshAnchors {
            
            // Some short handles, otherwise stuff will get pretty long in a few lines
            let geometry = meshAncor.geometry
            let vertices = geometry.vertices
            let faces = geometry.faces
            let verticesPointer = vertices.buffer.contents()
            let facesPointer = faces.buffer.contents()
            
            // Converting each vertex of the geometry from the local space of their ARMeshAnchor to world space
            for vertexIndex in 0..<vertices.count {
                
                // Extracting the current vertex with an extension method provided by Apple in Extensions.swift
                let vertex = geometry.vertex(at: UInt32(vertexIndex))
                
                // Building a transform matrix with only the vertex position
                // and apply the mesh anchors transform to convert into world space
                var vertexLocalTransform = matrix_identity_float4x4
                vertexLocalTransform.columns.3 = SIMD4<Float>(x: vertex.0, y: vertex.1, z: vertex.2, w: 1)
                let vertexWorldPosition = (meshAncor.transform * vertexLocalTransform).position
                
                // Writing the world space vertex back into it's position in the vertex buffer
                let vertexOffset = vertices.offset + vertices.stride * vertexIndex
                let componentStride = vertices.stride / 3
                verticesPointer.storeBytes(of: vertexWorldPosition.x, toByteOffset: vertexOffset, as: Float.self)
                verticesPointer.storeBytes(of: vertexWorldPosition.y, toByteOffset: vertexOffset + componentStride, as: Float.self)
                verticesPointer.storeBytes(of: vertexWorldPosition.z, toByteOffset: vertexOffset + (2 * componentStride), as: Float.self)
            }
            
            // Initializing MDLMeshBuffers with the content of the vertex and face MTLBuffers
            let byteCountVertices = vertices.count * vertices.stride
            let byteCountFaces = faces.count * faces.indexCountPerPrimitive * faces.bytesPerIndex
            let vertexBuffer = allocator.newBuffer(with: Data(bytesNoCopy: verticesPointer, count: byteCountVertices, deallocator: .none), type: .vertex)
            let indexBuffer = allocator.newBuffer(with: Data(bytesNoCopy: facesPointer, count: byteCountFaces, deallocator: .none), type: .index)
            
            // Creating a MDLSubMesh with the index buffer and a generic material
            let indexCount = faces.count * faces.indexCountPerPrimitive
            let material = MDLMaterial(name: "mat1", scatteringFunction: MDLPhysicallyPlausibleScatteringFunction())
            let submesh = MDLSubmesh(indexBuffer: indexBuffer, indexCount: indexCount, indexType: .uInt32, geometryType: .triangles, material: material)
            
            // Creating a MDLVertexDescriptor to describe the memory layout of the mesh
            let vertexFormat = MTKModelIOVertexFormatFromMetal(vertices.format)
            let vertexDescriptor = MDLVertexDescriptor()
            vertexDescriptor.attributes[0] = MDLVertexAttribute(name: MDLVertexAttributePosition, format: vertexFormat, offset: 0, bufferIndex: 0)
            vertexDescriptor.layouts[0] = MDLVertexBufferLayout(stride: meshAncor.geometry.vertices.stride)
            
            // Finally creating the MDLMesh and adding it to the MDLAsset
            let mesh = MDLMesh(vertexBuffer: vertexBuffer, vertexCount: meshAncor.geometry.vertices.count, descriptor: vertexDescriptor, submeshes: [submesh])
            asset.add(mesh)
        }
        
        // Setting the path to export the OBJ file to
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!

            
        let urlOBJ = documentsPath.appendingPathComponent("\(Date()).obj")

        // Exporting the OBJ file
        if MDLAsset.canExportFileExtension("obj") {
            do {
//                try asset.export(to: urlOBJ)
                try asset.export(to: urlOBJ)
                
                arView?.session.pause()
                if let configuration = arView.session.configuration {
                            arView.session.run(configuration, options: .resetSceneReconstruction)
                }
                
                let vc = MenuVC(nibName: "MenuVC", bundle: nil)
                self.navigationController?.pushViewController(vc, animated: true)
                
                //show succes alert
                //go next menu
            } catch let error {
//                fatalError(error.localizedDescription)
            }
        } else {
//            fatalError("Can't export OBJ")
        }
    }
    
    //MARK: Action
    
    @IBAction func saveAction(_ sender: UIButton) {
        generate3DModel()
    }
    
    
    @IBAction func showMenuTap(_ sender: Any) {
        
        arView?.session.pause()
        if let configuration = arView.session.configuration {
                    arView.session.run(configuration, options: .resetSceneReconstruction)
        }
        
        let vc = MenuVC(nibName: "MenuVC", bundle: nil)
        self.navigationController?.pushViewController(vc, animated: true)
    }
    
}

