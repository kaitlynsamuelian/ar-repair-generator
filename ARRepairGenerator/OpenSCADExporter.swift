//
//  OpenSCADExporter.swift
//  ARRepairGenerator
//

import Foundation

class OpenSCADExporter {
    
    /// Export part parameters to OpenSCAD .scad file
    func exportToOpenSCAD(
        partType: String,
        parameters: [String: Double],
        description: String,
        material: String,
        filename: String
    ) -> URL? {
        
        let scadCode = generateOpenSCADCode(
            partType: partType,
            parameters: parameters,
            description: description,
            material: material
        )
        
        // Save to temporary file
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)
        
        do {
            try scadCode.write(to: fileURL, atomically: true, encoding: .utf8)
            
            // Mark file as shareable
            var resourceValues = URLResourceValues()
            resourceValues.isExcludedFromBackup = true
            var fileURLCopy = fileURL
            try fileURLCopy.setResourceValues(resourceValues)
            
            print("✅ OpenSCAD exported to: \(fileURL.path)")
            return fileURL
        } catch {
            print("❌ OpenSCAD export failed: \(error)")
            return nil
        }
    }
    
    private func generateOpenSCADCode(
        partType: String,
        parameters: [String: Double],
        description: String,
        material: String
    ) -> String {
        
        // Helper to get parameter with fallback
        func getParam(_ names: [String], default defaultValue: Double = 0) -> Double {
            for name in names {
                if let value = parameters[name] {
                    return value
                }
            }
            return defaultValue
        }
        
        // Extract common parameters
        let outerD = getParam(["outer_diameter", "diameter", "base_diameter"])
        let innerD = getParam(["inner_diameter", "hole_diameter"])
        let height = getParam(["height", "h"])
        let length = getParam(["length", "l"])
        let width = getParam(["width", "w"])
        let wallThickness = getParam(["wall_thickness", "wall"], default: 1.5)
        let topThickness = getParam(["top_thickness"], default: 2.5)
        let threadPitch = getParam(["thread_pitch"], default: 3.0)
        let chamfer = getParam(["chamfer", "chamfer_top"], default: 0.5)
        
        // Detect phone case / enclosure type parts
        let phoneWidth = getParam(["phone_width"])
        let phoneHeight = getParam(["phone_height"])
        let phoneDepth = getParam(["phone_depth"])
        
        if phoneWidth > 0 && phoneHeight > 0 && phoneDepth > 0 {
            return generatePhoneCase(
                phoneWidth: phoneWidth,
                phoneHeight: phoneHeight,
                phoneDepth: phoneDepth,
                fitClearance: getParam(["fit_clearance"], default: 0.8),
                wallThickness: wallThickness,
                backThickness: getParam(["back_thickness"], default: 2.5),
                lipHeight: getParam(["lip_height"], default: 1.5),
                cornerRadius: getParam(["corner_radius"], default: 3.0),
                description: description,
                material: material
            )
        }
        // Generate appropriate code based on part type
        else if outerD > 0 && innerD > 0 && height > 0 {
            // CAP/LID with threads
            return generateCapWithThreads(
                outerD: outerD,
                innerD: innerD,
                height: height,
                topThickness: topThickness,
                threadPitch: threadPitch,
                chamfer: chamfer,
                description: description,
                material: material
            )
        } else if outerD > 0 && height > 0 {
            // SOLID CYLINDER
            return generateSolidCylinder(
                diameter: outerD,
                height: height,
                chamfer: chamfer,
                description: description,
                material: material
            )
        } 
        
        // Check for L-bracket
        let leg1 = getParam(["leg_length_1", "leg1"])
        let leg2 = getParam(["leg_length_2", "leg2"])
        
        if leg1 > 0 && leg2 > 0 {
            // L-BRACKET
            return generateLBracket(
                leg1: leg1,
                leg2: leg2,
                thickness: getParam(["thickness"]),
                holeDiameter: getParam(["hole_diameter"]),
                fillet: getParam(["corner_fillet", "fillet"]),
                description: description,
                material: material
            )
        } else if length > 0 && width > 0 {
            // RECTANGULAR PART
            return generateRectangularPart(
                length: length,
                width: width,
                height: height > 0 ? height : 3.0,
                chamfer: chamfer,
                description: description,
                material: material
            )
        } else {
            // FALLBACK
            return generateFallback(description: description)
        }
    }
    
    private func generateCapWithThreads(
        outerD: Double,
        innerD: Double,
        height: Double,
        topThickness: Double,
        threadPitch: Double,
        chamfer: Double,
        description: String,
        material: String
    ) -> String {
        let actualWallThickness = (outerD - innerD) / 2
        return """
        // AR Repair Generator - \(description)
        // Material: \(material)
        // Generated: \(Date())
        //
        // ✨ THIS IS A FUNCTIONAL SHELL, NOT A SOLID BLOCK
        // The part is created using difference() to subtract the inner cavity
        
        // PARAMETERS (Edit these!)
        outer_diameter = \(outerD);      // Outer diameter (mm)
        inner_diameter = \(innerD);      // Inner diameter (mm) - creates hollow space
        wall_height = \(height);         // Wall height (mm)
        top_thickness = \(topThickness); // Top thickness (mm)
        wall_thickness = \(String(format: "%.1f", actualWallThickness)); // Calculated wall thickness (mm)
        
        // THREAD PARAMETERS
        thread_pitch = \(threadPitch);   // Thread pitch (mm) - distance between threads
        thread_depth = 1.5;              // Thread depth (mm)
        thread_angle = 60;               // Thread angle (degrees) - ISO metric standard
        
        // FEATURES
        chamfer_size = \(chamfer);       // Top chamfer for comfort (mm)
        grip_ridges = 8;                 // Number of grip ridges
        ridge_depth = 0.8;               // Ridge depth (mm)
        
        $fn = 100; // Smoothness (50=draft, 100=good, 200=final)
        
        // ===== MAIN MODEL =====
        difference() {
            union() {
                // Outer wall with grip ridges
                difference() {
                    cylinder(h=wall_height, d=outer_diameter);
                    
                    // Add grip ridges around outer wall
                    for (i = [0:grip_ridges-1]) {
                        rotate([0, 0, i * (360/grip_ridges)])
                        translate([outer_diameter/2 - ridge_depth/2, 0, 0])
                        cylinder(h=wall_height, r=ridge_depth, $fn=20);
                    }
                }
                
                // Solid top disc
                translate([0, 0, wall_height])
                cylinder(h=top_thickness, d=outer_diameter);
                
                // Top chamfer for comfort
                translate([0, 0, wall_height + top_thickness])
                cylinder(h=chamfer_size, d1=outer_diameter, d2=outer_diameter - chamfer_size*2);
            }
            
            // Subtract inner cavity
            translate([0, 0, -0.1])
            cylinder(h=wall_height + 0.2, d=inner_diameter);
            
            // THREADS (ISO Metric style)
            // Note: For real threads, use a thread library like:
            // https://github.com/rcolyer/threads-scad
            // For now, this creates a helical groove approximation
            translate([0, 0, 0])
            for (z = [0:thread_pitch:wall_height]) {
                rotate([0, 0, z * 360 / thread_pitch])
                translate([inner_diameter/2, 0, z])
                rotate([0, 90, 0])
                cylinder(h=thread_depth, r=thread_pitch/4, $fn=20);
            }
        }
        
        // ===== INSTRUCTIONS =====
        // 1. Adjust parameters above to fit your needs
        // 2. For real ISO threads, install: https://github.com/rcolyer/threads-scad
        //    Then replace the thread section with: metric_thread(diameter=inner_diameter, pitch=thread_pitch, length=wall_height, internal=true);
        // 3. Preview (F5) then Render (F6)
        // 4. Export to STL: File → Export → Export as STL
        // 5. Print with: 3 perimeters, 20% infill, supports if needed
        
        """
    }
    
    private func generateSolidCylinder(
        diameter: Double,
        height: Double,
        chamfer: Double,
        description: String,
        material: String
    ) -> String {
        return """
        // AR Repair Generator - \(description)
        // Material: \(material)
        // Generated: \(Date())
        
        // PARAMETERS
        diameter = \(diameter);          // Diameter (mm)
        height = \(height);              // Height (mm)
        chamfer_size = \(chamfer);       // Top/bottom chamfer (mm)
        
        $fn = 100; // Smoothness
        
        // ===== MAIN MODEL =====
        union() {
            // Main cylinder
            cylinder(h=height, d=diameter);
            
            // Top chamfer
            translate([0, 0, height])
            cylinder(h=chamfer_size, d1=diameter, d2=diameter - chamfer_size*2);
            
            // Bottom chamfer
            cylinder(h=chamfer_size, d1=diameter - chamfer_size*2, d2=diameter);
        }
        
        """
    }
    
    private func generateRectangularPart(
        length: Double,
        width: Double,
        height: Double,
        chamfer: Double,
        description: String,
        material: String
    ) -> String {
        return """
        // AR Repair Generator - \(description)
        // Material: \(material)
        // Generated: \(Date())
        //
        // ✨ SOLID STRUCTURAL PART (Spacer/Shim/Block)
        // This is a SOLID part, not hollow - designed to fill space or provide support
        
        // PARAMETERS (Edit these!)
        length = \(length);              // Length (mm)
        width = \(width);                // Width (mm)
        height = \(height);              // Height/thickness (mm)
        chamfer_size = \(chamfer);       // Corner chamfer for easy placement (mm)
        corner_radius = 2.0;             // Corner rounding (mm)
        
        $fn = 50; // Smoothness (30=draft, 50=good, 100=final)
        
        // ===== MAIN MODEL - SOLID BLOCK WITH ROUNDED EDGES =====
        // Using minkowski() to round all edges smoothly
        minkowski() {
            // Main rectangular body (slightly smaller to account for rounding)
            cube([
                length - chamfer_size*2, 
                width - chamfer_size*2, 
                height - chamfer_size
            ], center=true);
            
            // Rounding element (sphere creates smooth edges)
            sphere(r=chamfer_size);
        }
        
        // ===== INSTRUCTIONS =====
        // This is a SOLID part (no cavities). Use for:
        // - Spacers to fill gaps
        // - Shims for leveling
        // - Standoffs for support
        // - Blocks for structural fill
        //
        // If you need HOLLOW instead (like an enclosure):
        // - Add "inner_" dimensions
        // - Use difference() to subtract inner cavity
        // - See phone_case example for hollow shell technique
        
        """
    }
    
    private func generatePhoneCase(
        phoneWidth: Double,
        phoneHeight: Double,
        phoneDepth: Double,
        fitClearance: Double,
        wallThickness: Double,
        backThickness: Double,
        lipHeight: Double,
        cornerRadius: Double,
        description: String,
        material: String
    ) -> String {
        return """
        // AR Repair Generator - \(description)
        // Material: \(material)
        // Generated: \(Date())
        //
        // 📱 FUNCTIONAL PHONE CASE - HOLLOW SHELL WITH OPEN FRONT
        // This creates a protective case by subtracting the phone cavity from an outer shell
        
        // PHONE DIMENSIONS (Edit to fit your device!)
        phone_width = \(phoneWidth);       // Phone width (mm)
        phone_height = \(phoneHeight);     // Phone height (mm)
        phone_depth = \(phoneDepth);       // Phone depth/thickness (mm)
        
        // FIT & STRUCTURE
        fit_clearance = \(fitClearance);   // Gap so phone slides in easily (mm)
        wall_thickness = \(wallThickness); // Side wall thickness (mm)
        back_thickness = \(backThickness); // Back wall thickness (mm)
        lip_height = \(lipHeight);         // Front lip for screen protection (mm)
        corner_radius = \(cornerRadius);   // Rounded corners (mm)
        
        $fn = 60; // Smoothness (30=draft, 60=good, 120=final)
        
        // ===== CALCULATED DIMENSIONS =====
        // Inner cavity (phone + clearance)
        inner_width = phone_width + fit_clearance;
        inner_height = phone_height + fit_clearance;
        inner_depth = phone_depth + fit_clearance;
        
        // Outer dimensions (inner + walls)
        outer_width = inner_width + (2 * wall_thickness);
        outer_height = inner_height + (2 * wall_thickness);
        outer_depth = inner_depth + back_thickness; // Back only, front is open!
        
        // ===== MAIN MODEL - FUNCTIONAL HOLLOW SHELL =====
        difference() {
            // Outer shell (solid)
            hull() {
                for (x = [0, 1], y = [0, 1], z = [0, 1]) {
                    translate([
                        x * (outer_width - 2*corner_radius) - outer_width/2 + corner_radius,
                        y * (outer_height - 2*corner_radius) - outer_height/2 + corner_radius,
                        z * (outer_depth - corner_radius)
                    ])
                    sphere(r = corner_radius);
                }
            }
            
            // Subtract inner cavity (this makes it HOLLOW!)
            translate([0, 0, back_thickness])
            hull() {
                for (x = [0, 1], y = [0, 1], z = [0, 1]) {
                    translate([
                        x * (inner_width - 2*corner_radius) - inner_width/2 + corner_radius,
                        y * (inner_height - 2*corner_radius) - inner_height/2 + corner_radius,
                        z * (inner_depth - corner_radius) + lip_height
                    ])
                    sphere(r = corner_radius - 0.5);
                }
            }
            
            // Cut away the FRONT (for screen access)
            translate([0, 0, back_thickness + inner_depth + lip_height])
            cube([outer_width + 1, outer_height + 1, outer_depth], center=true);
        }
        
        // ===== INSTRUCTIONS =====
        // 1. Adjust phone dimensions above to match YOUR device
        // 2. Increase fit_clearance if too tight, decrease if too loose
        // 3. Increase wall_thickness for more protection (makes case heavier)
        // 4. Preview (F5) then Render (F6)
        // 5. Export to STL: File → Export → Export as STL
        // 6. Print with: 3-4 perimeters, 20% infill, supports: none, TPU recommended
        
        """
    }
    
    private func generateLBracket(
        leg1: Double,
        leg2: Double,
        thickness: Double = 3.0,
        holeDiameter: Double = 4.2,
        fillet: Double = 5.0,
        description: String,
        material: String
    ) -> String {
        let actualThickness = thickness > 0 ? thickness : 3.0
        let actualHoleDiam = holeDiameter > 0 ? holeDiameter : 4.2
        let actualFillet = fillet > 0 ? fillet : 5.0
        return """
        // AR Repair Generator - \(description)
        // Material: \(material)
        // Generated: \(Date())
        //
        // 🔧 L-BRACKET - MIXED GEOMETRY (Solid with Functional Holes)
        // This is a solid bracket with mounting holes - not hollow, but not a plain block
        
        // PARAMETERS (Edit these!)
        leg_length_1 = \(leg1);              // First leg length (mm)
        leg_length_2 = \(leg2);              // Second leg length (mm)
        bracket_thickness = \(actualThickness); // Material thickness (mm)
        hole_diameter = \(actualHoleDiam);      // Mounting hole diameter (mm) - 4.2mm for M4 screws
        corner_fillet = \(actualFillet);        // Internal corner fillet for strength (mm)
        edge_chamfer = 0.5;              // Edge chamfer (mm)
        
        $fn = 50; // Smoothness
        
        // ===== MAIN MODEL - L-BRACKET WITH MOUNTING HOLES =====
        difference() {
            // Solid L-shape with fillet
            union() {
                // Horizontal leg
                translate([0, 0, bracket_thickness/2])
                cube([leg_length_1, leg_length_2, bracket_thickness], center=false);
                
                // Vertical leg
                translate([0, 0, 0])
                cube([leg_length_1, bracket_thickness, leg_length_2], center=false);
                
                // Corner fillet for strength
                translate([0, bracket_thickness, 0])
                rotate([0, 0, 0])
                cylinder(h=corner_fillet, r=corner_fillet);
            }
            
            // Subtract mounting holes (this makes it FUNCTIONAL, not just a block)
            // Hole 1 (horizontal leg)
            translate([leg_length_1/2, leg_length_2/2, -1])
            cylinder(h=bracket_thickness + 2, d=hole_diameter);
            
            // Hole 2 (vertical leg)
            translate([leg_length_1/2, bracket_thickness/2, leg_length_2/2])
            rotate([90, 0, 0])
            cylinder(h=bracket_thickness + 2, d=hole_diameter);
        }
        
        // ===== INSTRUCTIONS =====
        // This is a SOLID part with functional holes (Type C: Mixed Geometry)
        // - Solid body provides structural strength
        // - Holes allow mounting with screws
        // - Fillet at corner prevents stress concentration
        //
        // Adjust:
        // - leg_length_1/2 for different mounting distances
        // - hole_diameter for different screw sizes (3.2mm=M3, 4.2mm=M4, 5.2mm=M5)
        // - bracket_thickness for strength (2mm=light, 3mm=standard, 4mm=heavy duty)
        
        """
    }
    
    private func generateFallback(description: String) -> String {
        return """
        // AR Repair Generator - \(description)
        // Fallback part - edit parameters below
        
        diameter = 30;
        height = 10;
        
        $fn = 100;
        
        cylinder(h=height, d=diameter);
        
        """
    }
}

