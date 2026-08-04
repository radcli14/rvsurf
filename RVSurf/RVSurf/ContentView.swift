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
    @State private var subscriptions: [EventSubscription] = []
    @State private var anchor: AnchorEntity?
    @State private var entities = Set<Entity>()
    
    let query = EntityQuery(where: .has(SceneUnderstandingComponent.self) && .has(ModelComponent.self))
    
    var material: UnlitMaterial
    init() {
        material = UnlitMaterial(color: .green)
        material.triangleFillMode = .lines
    }
    
    var body: some View {
        RealityView { content in
            content.camera = .spatialTracking
            
            // An anchor must be added so that we can access the scene for the query
            anchor = AnchorEntity(.plane(.horizontal, classification: .any, minimumBounds: [0.2, 0.2]))
            content.add(anchor!)

            // Create the handlers for component events, which are associated with the scene understanding
            let add = content.subscribe(
                to: ComponentEvents.DidAdd.self,
                componentType: SceneUnderstandingComponent.self
            ) { event in
                handleAdd(event)
            }

            let update = content.subscribe(
                to: ComponentEvents.DidChange.self,
                componentType: SceneUnderstandingComponent.self
            ) { event in
                handleUpdate(event)
            }
            
            let activate = content.subscribe(
                to: ComponentEvents.DidActivate.self,
                componentType: SceneUnderstandingComponent.self
            ) { event in
                handleActivate(event)
            }
            
            subscriptions = [add, update, activate]
            
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
    
    // - MARK: - Handlers
    
    private func handleAdd(_ event: ComponentEvents.DidAdd) {
        guard let scene = anchor?.scene else { return }
        
        // This block executes ONLY when ARKit expands or alters room geometry mapping
        let queryResult = scene.performQuery(query)
        let totalMeshes = queryResult.map { _ in 1 }.reduce(0, +)
        
        for entity in queryResult {
            entity.components[ModelComponent.self]?.materials = [material]
        }
        
        print("Scene understanding added! New total meshes found: \(totalMeshes)")
    }
    
    private func handleUpdate(_ event: ComponentEvents.DidChange) {
        guard let scene = anchor?.scene else { return }
        
        // This block executes ONLY when ARKit expands or alters room geometry mapping
        let queryResult = scene.performQuery(query)
        let totalMeshes = queryResult.map { _ in 1 }.reduce(0, +)
        
        print("Scene understanding updated! New total meshes found: \(totalMeshes)")
    }
    
    private func handleActivate(_ event: ComponentEvents.DidActivate) {
        guard let scene = anchor?.scene else { return }
        
        // This block executes ONLY when ARKit expands or alters room geometry mapping
        let queryResult = scene.performQuery(query)
        let totalMeshes = queryResult.map { _ in 1 }.reduce(0, +)
        
        print("Scene understanding activated! New total meshes found: \(totalMeshes)")
    }
}

#Preview {
    ContentView()
}
