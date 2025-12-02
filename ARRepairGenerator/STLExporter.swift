//
//  STLExporter.swift
//  ARRepairGenerator
//

import Foundation
import SceneKit

class STLExporter {
    
    /// Export a SceneKit node to binary STL format
    func exportToBinarySTL(node: SCNNode, filename: String) -> URL? {
        // Collect all geometries from this node and its children
        var allVertices: [SCNVector3] = []
        var allTriangles: [(Int, Int, Int)] = []
        
        collectGeometries(from: node, vertices: &allVertices, triangles: &allTriangles)
        
        guard !allTriangles.isEmpty else {
            print("❌ No triangles found in node or children")
            return nil
        }
        
        print("✅ Found \(allTriangles.count) triangles from \(allVertices.count) vertices")
        
        // Create binary STL data
        var data = Data()
        
        // Header (80 bytes)
        let header = "Binary STL exported from ARRepairGenerator"
        let headerData = header.data(using: .utf8) ?? Data()
        data.append(headerData)
        data.append(Data(count: 80 - headerData.count))  // Pad to 80 bytes
        
        // Number of triangles (4 bytes, little-endian)
        var triangleCount = UInt32(allTriangles.count)
        data.append(Data(bytes: &triangleCount, count: 4))
        
        // Write each triangle
        for triangle in allTriangles {
            let v1 = allVertices[triangle.0]
            let v2 = allVertices[triangle.1]
            let v3 = allVertices[triangle.2]
            
            // Calculate normal
            let normal = calculateNormal(v1: v1, v2: v2, v3: v3)
            
            // Write normal (12 bytes: 3 floats)
            data.append(floatToData(normal.x))
            data.append(floatToData(normal.y))
            data.append(floatToData(normal.z))
            
            // Write vertices (36 bytes: 9 floats)
            data.append(floatToData(v1.x))
            data.append(floatToData(v1.y))
            data.append(floatToData(v1.z))
            
            data.append(floatToData(v2.x))
            data.append(floatToData(v2.y))
            data.append(floatToData(v2.z))
            
            data.append(floatToData(v3.x))
            data.append(floatToData(v3.y))
            data.append(floatToData(v3.z))
            
            // Attribute byte count (2 bytes, always 0)
            var attributeCount: UInt16 = 0
            data.append(Data(bytes: &attributeCount, count: 2))
        }
        
        // Save to temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        
        do {
            try data.write(to: fileURL)
            
            // Mark file as shareable and exclude from backup (fix iOS permissions)
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            var fileURLCopy = fileURL
            try fileURLCopy.setResourceValues(resourceValues)
            
            print("✅ STL exported to: \(fileURL.path)")
            return fileURL
        } catch {
            print("❌ Export failed: \(error)")
            return nil
        }
    }
    
    /// Recursively collect all geometries from a node and its children
    private func collectGeometries(from node: SCNNode, vertices: inout [SCNVector3], triangles: inout [(Int, Int, Int)]) {
        // If this node has geometry, process it
        if let geometry = node.geometry {
            let startIndex = vertices.count
            let nodeVertices = extractVertices(from: geometry, transform: node.simdWorldTransform)
            let nodeTriangles = extractTriangles(from: geometry, indexOffset: startIndex)
            
            vertices.append(contentsOf: nodeVertices)
            triangles.append(contentsOf: nodeTriangles)
            
            print("   📦 Added geometry: \(nodeVertices.count) vertices, \(nodeTriangles.count) triangles")
        }
        
        // Recursively process all children
        for child in node.childNodes {
            collectGeometries(from: child, vertices: &vertices, triangles: &triangles)
        }
    }
    
    private func extractVertices(from geometry: SCNGeometry, transform: simd_float4x4) -> [SCNVector3] {
        guard let vertexSource = geometry.sources(for: .vertex).first else { return [] }
        
        let stride = vertexSource.dataStride
        let offset = vertexSource.dataOffset
        let data = vertexSource.data
        let count = vertexSource.vectorCount
        
        var vertices: [SCNVector3] = []
        
        for i in 0..<count {
            let position = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> SCNVector3 in
                let pointer = bytes.baseAddress!.advanced(by: offset + (i * stride))
                let floatPointer = pointer.assumingMemoryBound(to: Float.self)
                
                // Apply world transform to vertex
                let localPos = simd_float4(floatPointer[0], floatPointer[1], floatPointer[2], 1.0)
                let worldPos = transform * localPos
                
                return SCNVector3(worldPos.x, worldPos.y, worldPos.z)
            }
            vertices.append(position)
        }
        
        return vertices
    }
    
    private func extractTriangles(from geometry: SCNGeometry, indexOffset: Int) -> [(Int, Int, Int)] {
        guard let element = geometry.elements.first else { return [] }
        
        let indexData = element.data
        let primitiveCount = element.primitiveCount
        let bytesPerIndex = element.bytesPerIndex
        
        var triangles: [(Int, Int, Int)] = []
        
        for i in 0..<primitiveCount {
            let indices = indexData.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) -> (Int, Int, Int) in
                if bytesPerIndex == 2 {
                    let pointer = bytes.baseAddress!.assumingMemoryBound(to: UInt16.self)
                    return (
                        Int(pointer[i * 3]) + indexOffset,
                        Int(pointer[i * 3 + 1]) + indexOffset,
                        Int(pointer[i * 3 + 2]) + indexOffset
                    )
                } else {
                    let pointer = bytes.baseAddress!.assumingMemoryBound(to: UInt32.self)
                    return (
                        Int(pointer[i * 3]) + indexOffset,
                        Int(pointer[i * 3 + 1]) + indexOffset,
                        Int(pointer[i * 3 + 2]) + indexOffset
                    )
                }
            }
            triangles.append(indices)
        }
        
        return triangles
    }
    
    private func calculateNormal(v1: SCNVector3, v2: SCNVector3, v3: SCNVector3) -> SCNVector3 {
        let u = SCNVector3(v2.x - v1.x, v2.y - v1.y, v2.z - v1.z)
        let v = SCNVector3(v3.x - v1.x, v3.y - v1.y, v3.z - v1.z)
        
        let normal = SCNVector3(
            u.y * v.z - u.z * v.y,
            u.z * v.x - u.x * v.z,
            u.x * v.y - u.y * v.x
        )
        
        // Normalize
        let length = sqrt(normal.x * normal.x + normal.y * normal.y + normal.z * normal.z)
        if length > 0 {
            return SCNVector3(normal.x / length, normal.y / length, normal.z / length)
        }
        return normal
    }
    
    private func floatToData(_ value: Float) -> Data {
        var float = value
        return Data(bytes: &float, count: 4)
    }
}

