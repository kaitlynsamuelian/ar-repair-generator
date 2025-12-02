//
//  ARViewContainer.swift
//  ARRepairGenerator
//

import SwiftUI
import ARKit

struct ARViewContainer: UIViewRepresentable {
    @ObservedObject var measurementState: MeasurementState

    func makeCoordinator() -> Coordinator {
        Coordinator(self, measurementState: measurementState)
    }

    func makeUIView(context: Context) -> ARSCNView {
        let arView = ARSCNView(frame: .zero)
        arView.delegate = context.coordinator

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]

        if ARWorldTrackingConfiguration.supportsSceneReconstruction(.mesh) {
            configuration.sceneReconstruction = .mesh
        }

        arView.session.run(configuration)
        arView.debugOptions = [.showFeaturePoints]

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        arView.addGestureRecognizer(tapGesture)

        // Set up the clear callback
        measurementState.onClearRequested = { [weak coordinator = context.coordinator] in
            coordinator?.clearAllMeasurements()
        }

        return arView
    }

    func updateUIView(_ uiView: ARSCNView, context: Context) {
        // No state modifications here
    }

    class Coordinator: NSObject, ARSCNViewDelegate {
        var parent: ARViewContainer
        var measurementState: MeasurementState
        
        // Store multiple measurement lines
        var measurementLines: [(id: UUID, nodes: [SCNNode])] = [] // Each entry has: points, line, text
        var pendingPoint: SCNNode? // First point waiting for second point

        init(_ parent: ARViewContainer, measurementState: MeasurementState) {
            self.parent = parent
            self.measurementState = measurementState
        }

        @objc func handleTap(_ sender: UITapGestureRecognizer) {
            guard let arView = sender.view as? ARSCNView else { return }
            let location = sender.location(in: arView)

            let results = arView.raycastQuery(from: location, allowing: .estimatedPlane, alignment: .any)

            if let query = results {
                let raycastResults = arView.session.raycast(query)

                if let firstResult = raycastResults.first {
                    addMeasurementPoint(at: firstResult.worldTransform, in: arView)
                }
            }
        }

        func addMeasurementPoint(at transform: simd_float4x4, in arView: ARSCNView) {
            // Create point sphere
            let sphere = SCNSphere(radius: 0.005)
            sphere.firstMaterial?.diffuse.contents = UIColor(Color.appPink)
            sphere.firstMaterial?.emission.contents = UIColor(Color.appPink)

            let node = SCNNode(geometry: sphere)
            node.simdTransform = transform

            arView.scene.rootNode.addChildNode(node)

            // If this is the first point of a new measurement
            if pendingPoint == nil {
                pendingPoint = node
                print("📍 Start point placed")
            }
            // If we already have a start point, complete the measurement
            else {
                guard let startNode = pendingPoint else { return }
                
                let distance = simd_distance(startNode.simdPosition, node.simdPosition)
                let distanceMM = distance * 1000
                
                print("📏 Distance: \(String(format: "%.1f", distanceMM))mm")

                // Draw line
                let lineNode = drawLine(from: startNode.position, to: node.position, in: arView)

                // Draw text label
                let midpoint = SCNVector3(
                    (startNode.position.x + node.position.x) / 2,
                    (startNode.position.y + node.position.y) / 2,
                    (startNode.position.z + node.position.z) / 2
                )
                let textNode = addTextLabel(at: midpoint, text: String(format: "%.1fmm", distanceMM), in: arView)

                // Store in measurementState
                measurementState.addMeasurement(
                    distance: Double(distance),
                    start: startNode.position,
                    end: node.position
                )

                // Store nodes for this measurement
                let measurementID = measurementState.measurements.last!.id
                let nodes = [startNode, node, lineNode, textNode]
                measurementLines.append((id: measurementID, nodes: nodes))

                // Show category picker for this measurement
                DispatchQueue.main.async { [weak self] in
                    self?.measurementState.showingCategoryPicker = measurementID
                }

                // Reset for next measurement
                pendingPoint = nil
                print("✅ Measurement complete. Choose category to continue.")
            }
        }

        func drawLine(from start: SCNVector3, to end: SCNVector3, in arView: ARSCNView) -> SCNNode {
            let vector = SCNVector3(end.x - start.x, end.y - start.y, end.z - start.z)
            let distance = sqrt(vector.x * vector.x + vector.y * vector.y + vector.z * vector.z)

            let cylinder = SCNCylinder(radius: 0.001, height: CGFloat(distance))
            cylinder.firstMaterial?.diffuse.contents = UIColor(Color.appPink)
            cylinder.firstMaterial?.emission.contents = UIColor(Color.appPinkDark)

            let lineNode = SCNNode(geometry: cylinder)
            lineNode.position = SCNVector3(
                (start.x + end.x) / 2,
                (start.y + end.y) / 2,
                (start.z + end.z) / 2
            )

            lineNode.look(at: end, up: arView.scene.rootNode.worldUp, localFront: lineNode.worldUp)

            arView.scene.rootNode.addChildNode(lineNode)
            return lineNode
        }

        func addTextLabel(at position: SCNVector3, text: String, in arView: ARSCNView) -> SCNNode {
            // Create text geometry
            let textGeometry = SCNText(string: text, extrusionDepth: 0.5)
            textGeometry.font = UIFont.systemFont(ofSize: 8, weight: .bold)
            textGeometry.firstMaterial?.diffuse.contents = UIColor.white
            textGeometry.firstMaterial?.emission.contents = UIColor.white

            let textNode = SCNNode(geometry: textGeometry)
            textNode.scale = SCNVector3(0.002, 0.002, 0.002)
            
            // Create pink pill background
            let textBounds = textGeometry.boundingBox
            let textWidth = CGFloat(textBounds.max.x - textBounds.min.x) * 0.002
            let textHeight = CGFloat(textBounds.max.y - textBounds.min.y) * 0.002
            
            let pillBox = SCNBox(
                width: textWidth + 0.01,
                height: textHeight + 0.006,
                length: 0.0005,
                chamferRadius: 0.003
            )
            pillBox.firstMaterial?.diffuse.contents = UIColor(Color.appPink)
            pillBox.firstMaterial?.emission.contents = UIColor(Color.appPink).withAlphaComponent(0.6)
            
            let pillNode = SCNNode(geometry: pillBox)
            pillNode.position = SCNVector3(textBounds.max.x * 0.001, textBounds.max.y * 0.001, -0.001)
            
            // Combine text and background
            let containerNode = SCNNode()
            containerNode.addChildNode(pillNode)
            containerNode.addChildNode(textNode)
            containerNode.position = SCNVector3(position.x, position.y + 0.015, position.z)

            let billboardConstraint = SCNBillboardConstraint()
            containerNode.constraints = [billboardConstraint]

            arView.scene.rootNode.addChildNode(containerNode)
            return containerNode
        }

        func clearAllMeasurements() {
            print("🗑️ Clearing all AR measurements...")

            // Remove all nodes from all measurements
            for (_, nodes) in measurementLines {
                nodes.forEach { $0.removeFromParentNode() }
            }
            measurementLines.removeAll()

            // Remove pending point if any
            pendingPoint?.removeFromParentNode()
            pendingPoint = nil

            print("✅ All measurements cleared!")
        }
    }
}

