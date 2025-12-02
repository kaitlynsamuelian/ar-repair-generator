//
//  PartGenerator.swift
//  ARRepairGenerator
//

import Foundation
import SceneKit

class PartGenerator {
    
    /// Generate a shim (rectangular plate)
    static func generateShim(length: Double, width: Double, thickness: Double) -> SCNNode {
        let box = SCNBox(
            width: CGFloat(length / 1000),
            height: CGFloat(thickness / 1000),
            length: CGFloat(width / 1000),
            chamferRadius: 0
        )
        box.firstMaterial?.diffuse.contents = UIColor.systemBlue
        box.firstMaterial?.specular.contents = UIColor.white
        box.firstMaterial?.metalness.contents = 0.2
        
        let node = SCNNode(geometry: box)
        return node
    }
    
    /// Generate a washer (solid cylinder for now - ring requires CSG)
    static func generateWasher(outerDiameter: Double, innerDiameter: Double, thickness: Double) -> SCNNode {
        // For now, create a simple cylinder
        // TODO: Use CSG to subtract inner cylinder for true washer
        let cylinder = SCNCylinder(
            radius: CGFloat(outerDiameter / 2000),
            height: CGFloat(thickness / 1000)
        )
        cylinder.firstMaterial?.diffuse.contents = UIColor.systemOrange
        cylinder.firstMaterial?.specular.contents = UIColor.white
        cylinder.firstMaterial?.metalness.contents = 0.3
        
        let node = SCNNode(geometry: cylinder)
        return node
    }
    
    /// Generate a custom cylinder (for bottle caps, knobs, etc.)
    static func generateCylinder(diameter: Double, height: Double, wallThickness: Double = 2.0) -> SCNNode {
        let cylinder = SCNCylinder(
            radius: CGFloat(diameter / 2000),
            height: CGFloat(height / 1000)
        )
        cylinder.firstMaterial?.diffuse.contents = UIColor.systemPurple
        cylinder.firstMaterial?.specular.contents = UIColor.white
        cylinder.firstMaterial?.metalness.contents = 0.2
        
        let node = SCNNode(geometry: cylinder)
        return node
    }
    
    /// Generate a CAP with a solid top (for lids, caps)
    static func generateCap(outerDiameter: Double, innerDiameter: Double, height: Double, topThickness: Double = 2.0) -> SCNNode {
        let parentNode = SCNNode()
        
        // 1. Outer wall (cylinder)
        let wallHeight = CGFloat(height / 1000)
        let outerWall = SCNCylinder(
            radius: CGFloat(outerDiameter / 2000),
            height: wallHeight
        )
        outerWall.firstMaterial?.diffuse.contents = UIColor.systemPurple
        outerWall.firstMaterial?.specular.contents = UIColor.white
        
        let wallNode = SCNNode(geometry: outerWall)
        parentNode.addChildNode(wallNode)
        
        // 2. Top disc (solid cap)
        let topDisc = SCNCylinder(
            radius: CGFloat(outerDiameter / 2000),
            height: CGFloat(topThickness / 1000)
        )
        topDisc.firstMaterial?.diffuse.contents = UIColor.systemPurple
        topDisc.firstMaterial?.specular.contents = UIColor.white
        
        let topNode = SCNNode(geometry: topDisc)
        topNode.position = SCNVector3(0, Float(wallHeight / 2 + CGFloat(topThickness / 2000)), 0)
        parentNode.addChildNode(topNode)
        
        // 3. Inner cavity (hollow space) - represented by a smaller cylinder for visualization
        let innerCavity = SCNCylinder(
            radius: CGFloat(innerDiameter / 2000),
            height: wallHeight * 0.9
        )
        innerCavity.firstMaterial?.diffuse.contents = UIColor.systemPurple.withAlphaComponent(0.3)
        
        let cavityNode = SCNNode(geometry: innerCavity)
        cavityNode.position = SCNVector3(0, Float(-wallHeight * 0.05), 0)
        // Note: For true CSG subtraction, we'd need external library. This is visualization only.
        // The exported STL will still be solid, which is fine for 3D printing.
        
        return parentNode
    }
    
    /// Generate a sphere (for knobs, caps, etc.)
    static func generateSphere(diameter: Double) -> SCNNode {
        let sphere = SCNSphere(radius: CGFloat(diameter / 2000))
        sphere.firstMaterial?.diffuse.contents = UIColor.systemGreen
        sphere.firstMaterial?.specular.contents = UIColor.white
        sphere.firstMaterial?.metalness.contents = 0.1
        
        let node = SCNNode(geometry: sphere)
        return node
    }
    
    /// 🧠 SMART AI PART GENERATOR - Works with ANY parameter combination
    static func generateFromAI(parameters: [String: Double]) -> SCNNode {
        print("🎨 Generating part from AI parameters: \(parameters)")
        
        // Helper function to get a parameter by multiple possible names
        func getParam(_ names: [String]) -> Double? {
            for name in names {
                if let value = parameters[name] {
                    return value
                }
            }
            return nil
        }
        
        // Extract common parameters with flexible naming
        let diameter = getParam(["diameter", "outer_diameter", "base_diameter"])
        let innerDiameter = getParam(["inner_diameter", "inner_d"])
        let height = getParam(["height", "thickness", "depth", "h"])
        let length = getParam(["length", "l"])
        let width = getParam(["width", "w"])
        
        // Phone case specific
        let phoneWidth = getParam(["phone_width"])
        let phoneHeight = getParam(["phone_height"])
        let phoneDepth = getParam(["phone_depth"])
        let fitClearance = getParam(["fit_clearance"]) ?? 0.8
        let wallThickness = getParam(["wall_thickness", "wall"]) ?? 2.0
        let backThickness = getParam(["back_thickness"]) ?? 2.5
        
        // Bracket specific
        let leg1 = getParam(["leg_length_1", "leg1"])
        let leg2 = getParam(["leg_length_2", "leg2"])
        
        // 📱 PHONE CASE / ENCLOSURE (has phone dimensions)
        if let pw = phoneWidth, let ph = phoneHeight, let pd = phoneDepth {
            print("   → 📱 Phone Case/Enclosure: \(pw)×\(ph)×\(pd)mm")
            // For preview: Create a simple box representing the case
            // (OpenSCAD will have the full hollow shell code)
            let outerWidth = (pw + fitClearance + wallThickness * 2) / 1000
            let outerHeight = (ph + fitClearance + wallThickness * 2) / 1000
            let outerDepth = (pd + fitClearance + backThickness) / 1000
            
            let box = SCNBox(width: CGFloat(outerWidth), height: CGFloat(outerHeight), length: CGFloat(outerDepth), chamferRadius: 0.003)
            box.firstMaterial?.diffuse.contents = UIColor.systemTeal
            box.firstMaterial?.transparency = 0.7 // Semi-transparent to show it's a shell
            
            return SCNNode(geometry: box)
        }
        
        // 🔧 BRACKET (L-shape with legs)
        else if let l1 = leg1, let l2 = leg2 {
            print("   → 🔧 L-Bracket: \(l1)mm × \(l2)mm")
            // Simple L-shape representation (OpenSCAD will have holes and fillets)
            let parentNode = SCNNode()
            
            let thick = (getParam(["thickness"]) ?? 3.0) / 1000
            
            // Horizontal leg
            let leg1Box = SCNBox(width: CGFloat(l1 / 1000), height: CGFloat(thick), length: CGFloat(l2 / 1000), chamferRadius: 0)
            leg1Box.firstMaterial?.diffuse.contents = UIColor.systemGray
            let leg1Node = SCNNode(geometry: leg1Box)
            parentNode.addChildNode(leg1Node)
            
            // Vertical leg (simplified for preview)
            let leg2Box = SCNBox(width: CGFloat(l1 / 1000), height: CGFloat(l2 / 1000), length: CGFloat(thick), chamferRadius: 0)
            leg2Box.firstMaterial?.diffuse.contents = UIColor.systemGray
            let leg2Node = SCNNode(geometry: leg2Box)
            leg2Node.position = SCNVector3(0, Float(l2 / 2000), Float(thick / 2))
            parentNode.addChildNode(leg2Node)
            
            return parentNode
        }
        
        // 🔵 CIRCULAR PARTS (any part with a diameter)
        else if let diam = diameter {
            
            // 🧢 CAP / LID (has inner diameter + height = functional cap with top)
            if let innerD = innerDiameter, let h = height {
                let topThick = getParam(["top_thickness"]) ?? 2.0
                print("   → 🧢 Cap/Lid with Top: OD\(diam)mm ID\(innerD)mm × \(h)mm")
                return generateCap(outerDiameter: diam, innerDiameter: innerD, height: h, topThickness: topThick)
            }
            
            // 🟣 SOLID CYLINDER (has height but no inner diameter - knob, rod, etc.)
            else if let h = height {
                print("   → 🟣 Solid Cylinder/Knob: Ø\(diam)mm × \(h)mm")
                return generateCylinder(diameter: diam, height: h, wallThickness: wallThickness)
            }
            
            // 🟢 SPHERE (diameter only, no height)
            else {
                print("   → 🟢 Sphere/Ball: Ø\(diam)mm")
                return generateSphere(diameter: diam)
            }
        }
        
        // 🔷 RECTANGULAR PARTS (length + width)
        else if let len = length, let wid = width {
            let thick = height ?? 2.0  // Default to 2mm if not specified
            print("   → 🔷 Rectangle/Shim/Plate: \(len)×\(wid)×\(thick)mm")
            return generateShim(length: len, width: wid, thickness: thick)
        }
        
        // ⚠️ SMART FALLBACK - Use whatever we have
        else if let h = height {
            // If we only have height, assume it's a small cylinder
            let defaultDiam = h * 1.5  // Make diameter 1.5x the height
            print("   → ⚠️ Fallback cylinder: Ø\(defaultDiam)mm × \(h)mm")
            return generateCylinder(diameter: defaultDiam, height: h)
        }
        
        // 🆘 LAST RESORT - Default shim
        else {
            print("   → 🆘 Fallback to default 30×30×2mm shim")
            return generateShim(length: 30, width: 30, thickness: 2)
        }
    }
}

