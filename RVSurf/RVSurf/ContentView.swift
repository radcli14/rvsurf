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
        let config = SpatialTrackingSession.Configuration(
            tracking: [.camera, .plane, .object, .world],
            sceneUnderstanding: [.occlusion, .physics, .collision, .shadow]
        )
        await session.run(config)
    }
}

extension RealityViewCameraContent {
    
    func setupSpatialTrackingVisualization() {
        subscribeToLidarSurfaceEvents()
        subscribeToPlaneDetectionEvents()
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
    
    // TODO: intended to capture simple plane detection on non-LiDAR devices, but the second print is never firing.
    private func subscribeToPlaneDetectionEvents() {
        print("subscribing to plane detection")
        let _ = subscribe(
            to: ComponentEvents.DidAdd.self,
            componentType: AnchoringComponent.self
        ) { event in
            print("anchor event", event)
        }
    }
    
    private static let meshTrackingMaterial: PhysicallyBasedMaterial = {
        var mat = PhysicallyBasedMaterial()
        mat.baseColor = .init(tint: .green)
        mat.emissiveColor = .init(color: .green)
        mat.triangleFillMode = .lines
        return mat
    }()
}

#Preview {
    ContentView()
}
