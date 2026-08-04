//
//  ContentView.swift
//  RVSurf
//
//  Created by Eliott Radcliffe on 8/3/26.
//

import RealityKit
import SwiftUI

struct ContentView: View {
    @State private var session = SpatialTrackingSession()
    
    var body: some View {
        RealityView { content in
            content.camera = .spatialTracking
            content.setupSpatialTrackingVisualization()
        }
        .task(startSession)
    }
    
    // - MARK: - Initialization
    
    private func startSession() async {
        // A surface-visualization demo only needs the camera (for pose) and plane detection
        // (for non-LiDAR surface visualization) -- object/world/body/face/image tracking are
        // unrelated to this use case. Scene understanding is left with occlusion enabled so
        // LiDAR devices still generate a reconstruction mesh to visualize.
        let config = SpatialTrackingSession.Configuration(
            tracking: [.camera, .plane],
            sceneUnderstanding: [.occlusion, .physics, .collision, .shadow]
        )
        await session.run(config)
    }
}

extension RealityViewCameraContent {

    func setupSpatialTrackingVisualization() {
        subscribeToLidarSurfaceEvents()
        addPlaneDetectionVisualization()
    }

    /// Subscribe to events associated with real-world LiDAR surfaces being added.
    /// Using ModelComponent.self assures that their mesh has been generated.
    private func subscribeToLidarSurfaceEvents() {
        let _ = subscribe(
            to: ComponentEvents.DidAdd.self,
            componentType: ModelComponent.self
        ) { event in
            event.entity.components[ModelComponent.self]?.materials = [Self.meshTrackingMaterial]
        }
    }

    /// Visualizes surfaces found via ARKit's plane detection, which is available on non-LiDAR
    /// devices (unlike the scene-reconstruction mesh visualized above).
    ///
    /// Enabling `.plane` tracking in the `SpatialTrackingSession.Configuration` only tells
    /// ARKit to *detect* planes -- unlike scene understanding, it does not by itself create any
    /// RealityKit entities for them. We have to create an `AnchorEntity` targeting `.plane` and
    /// add it to the scene ourselves; RealityKit then attaches ("anchors") it once ARKit finds a
    /// matching real-world plane. That's also why the previous subscription to
    /// `ComponentEvents.DidAdd` for `AnchoringComponent.self` never fired its second print: there
    /// was never any entity with that component being added to the scene to trigger it. The
    /// event that actually reports an anchor entity becoming anchored is
    /// `SceneEvents.AnchoredStateChanged`.
    ///
    /// The mesh size below is a fixed placeholder rather than the detected plane's true extent;
    /// tracking live extent growth needs ARKit's `PlaneDetectionProvider`/`PlaneAnchor` geometry,
    /// which is more than this simple demo needs.
    private func addPlaneDetectionVisualization() {
        for alignment: AnchoringComponent.Target.Alignment in [.horizontal, .vertical] {
            let planeAnchor = AnchorEntity(
                .plane(alignment, classification: .any, minimumBounds: [0.2, 0.2])
            )
            let planeMesh = ModelEntity(
                mesh: .generatePlane(width: 1, depth: 1),
                materials: [Self.planeDetectionMaterial]
            )
            planeAnchor.addChild(planeMesh)
            add(planeAnchor)
        }

        let _ = subscribe(to: SceneEvents.AnchoredStateChanged.self) { event in
            guard event.isAnchored else { return }
            print("Detected a real-world plane and anchored a visualization mesh to it.")
        }
    }

    private static let meshTrackingMaterial: PhysicallyBasedMaterial = {
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: .green)
        mat.emissiveColor = .init(color: .green)
        mat.triangleFillMode = .lines
        return mat
    }()

    private static let planeDetectionMaterial: PhysicallyBasedMaterial = {
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: .cyan)
        mat.emissiveColor = .init(color: .cyan)
        mat.triangleFillMode = .lines
        return mat
    }()
}

#Preview {
    ContentView()
}
