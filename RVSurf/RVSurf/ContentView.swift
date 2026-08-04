//
//  ContentView.swift
//  RVSurf
//
//  Created by Eliott Radcliffe on 8/3/26.
//

import RealityKit
import SwiftUI

struct ContentView: View {
    
    var body: some View {
        RealityView { content in
            content.camera = .spatialTracking
            
            // Subscribe to events associated with real-world LiDAR surfaces being added.
            // Using ModelComponent.self assures that their mesh has been generated.
            let _ = content.subscribe(
                to: ComponentEvents.DidAdd.self,
                componentType: ModelComponent.self
            ) { event in
                event.entity.components[ModelComponent.self]?.materials = [material]
            }
        }
        .task(startSession)
    }
    
    // - MARK: - Initialization
    
    private func startSession() async {
        let session = SpatialTrackingSession()
        let config = SpatialTrackingSession.Configuration(
            tracking: [.camera, .plane, .object, .world],
            sceneUnderstanding: [.occlusion, .physics, .collision, .shadow]
        )
        await session.run(config)
    }
    
    // - MARK: - Constants
    
    private let material: UnlitMaterial = {
        var mat = UnlitMaterial(color: .green)
        mat.triangleFillMode = .lines
        return mat
    }()
}

#Preview {
    ContentView()
}
