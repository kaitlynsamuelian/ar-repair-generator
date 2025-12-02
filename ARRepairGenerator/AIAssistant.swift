//
//  AIAssistant.swift
//  ARRepairGenerator
//

import Foundation

class AIAssistant {
    private let apiKey: String
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String) {
        self.apiKey = apiKey
    }
    
    nonisolated struct PartSuggestion: Codable, Sendable {
        let partType: String
        let parameters: [String: Double]
        let reasoning: String
        let material: String
        
        enum CodingKeys: String, CodingKey {
            case partType = "part_type"
            case parameters
            case reasoning
            case material
        }
    }
    
    // ✨ Generate custom parts based on description + measurements
    func suggestCustomPart(description: String, measurement: Double, measurementContext: String = "", completion: @escaping (Result<PartSuggestion, Error>) -> Void) {
        let distanceMM = measurement * 1000
        
        // If we have labeled measurements, use them. Otherwise use the single measurement.
        let dimensionInfo = measurementContext.isEmpty ? 
            "MEASURED DIMENSION: \(String(format: "%.1f", distanceMM))mm" :
            "LABELED MEASUREMENTS:\n\(measurementContext)"
        
        let prompt = """
        USER WANTS: "\(description)"
        
        \(dimensionInfo)
        
        IMPORTANT: Use the LABELED measurements above to determine the correct dimensions for each parameter.
        - If "Width" is labeled, use it for width/length parameters
        - If "Height" is labeled, use it for height parameters  
        - If "Depth" is labeled, use it for depth/thickness parameters
        - If "Diameter" is labeled, use it for diameter/outer_diameter parameters
        
        You are an expert in parametric CAD and 3D printing. Generate a FUNCTIONAL, PRINTABLE part.
        
        ⚡ CRITICAL: ANALYZE THE DESCRIPTION TO DETERMINE THE CORRECT GEOMETRY TYPE ⚡
        
        STEP 1: ANALYZE WHAT THE USER WANTS
        Read the description carefully. Determine if they need:
        
        A) **HOLLOW SHELL/ENCLOSURE** (surrounds/protects something)
           Examples: phone case, lid, cap, enclosure, box, cover, sleeve
           → These MUST be hollow with proper clearances
           → Create: outer shell MINUS inner cavity
           → Leave appropriate faces OPEN (case = open front, lid = open bottom)
        
        B) **SOLID STRUCTURAL PART** (fills space, provides support, no enclosure)
           Examples: spacer, shim, standoff, wedge, block, support, filler, plug
           → These SHOULD be solid (not hollow)
           → Use measurements directly
           → Add features like fillets for strength
        
        C) **MIXED/FUNCTIONAL GEOMETRY** (solid with strategic voids)
           Examples: bracket, mount, clamp, hook, adapter, holder
           → Solid body with mounting holes, slots, or cutouts
           → Use difference() only for functional features (holes, slots)
           → Not a hollow shell, but not a plain block either
        
        STEP 2: CHOOSE GEOMETRY BASED ON ANALYSIS
        
        FOR HOLLOW SHELLS (A):
        - MUST include: fit_clearance, wall_thickness
        - Formula: outer = inner + clearance + (2 × wall_thickness)
        - Use difference() to subtract cavity
        - Specify which faces are open/closed
        
        FOR SOLID PARTS (B):
        - Use measurements directly
        - NO inner dimensions needed
        - Add chamfers/fillets for printability
        - Focus on structural integrity
        
        FOR MIXED GEOMETRY (C):
        - Solid base + strategic voids
        - Add hole_diameter, slot_width, etc. for functional features
        - NOT a shell, but not a simple block
        
        CRITICAL REQUIREMENTS:
        1. The measurement is usually the OPENING/HOLE size, not the outer size
        2. For caps/lids: Add 0.5-1mm to measurement for outer_diameter (slip-on fit)
        3. For caps/lids: Subtract 0.5-1mm from measurement for inner_diameter (snug fit)
        4. Minimum wall thickness: 1.5mm, top thickness: 2-3mm for strength
        5. Make heights proportional (caps: 10-15mm, knobs: 20-40mm)
        
        LIMITATIONS (what we CAN'T generate):
        - No threads (suggest press-fit or slip-on designs instead)
        - No complex features (grips, ridges, snap-fits are mentioned but not physically modeled)
        - Parts are basic prototypes for 3D printing refinement
        
        PARAMETER NAMING RULES (CRITICAL):
        - CAPS/LIDS: MUST include "outer_diameter" + "inner_diameter" + "height" + "top_thickness"
          (This creates a functional cap with a solid top!)
        - SOLID CYLINDERS (knobs, rods): Use "diameter" + "height" (no inner_diameter)
        - RECTANGULAR parts: Use "length" + "width" + "height"
        - Always use "height" (not "thickness") for vertical dimension
        
        EXAMPLES:
        
        "water bottle lid" + 40mm measurement (measured the bottle opening):
        {
            "part_type": "threaded_cap",
            "parameters": {
                "outer_diameter": 42.0,
                "inner_diameter": 39.0,
                "height": 12.0,
                "wall_thickness": 1.5,
                "top_thickness": 2.5,
                "thread_pitch": 3.0,
                "chamfer_top": 0.5
            },
            "reasoning": "Threaded cap WITH SOLID TOP. Outer: 42mm (40mm + 2mm wall), Inner: 39mm (snug fit), Height: 12mm, Top: 2.5mm, Threads: 3mm pitch (standard bottle thread).",
            "material": "PETG (food safe, flexible)"
        }
        
        "replacement knob" + 20mm measurement (measured the shaft):
        {
            "part_type": "knob",
            "parameters": {
                "diameter": 30.0,
                "height": 35.0,
                "hole_diameter": 6.2
            },
            "reasoning": "30mm diameter knob (1.5x measurement for grip), 35mm height, 6.2mm hole for M6 shaft with press fit.",
            "material": "PLA (rigid)"
        }
        
        "spacer" + 50mm measurement:
        {
            "part_type": "rectangular_spacer",
            "parameters": {
                "length": 50.0,
                "width": 20.0,
                "height": 3.0
            },
            "reasoning": "50mm long spacer matching measurement, 20mm wide for stability, 3mm thick.",
            "material": "PLA (rigid)"
        }
        
        "iphone case" + Width: 63.5mm, Height: 149.2mm, Depth: 16.4mm:
        {
            "part_type": "phone_case",
            "parameters": {
                "phone_width": 63.5,
                "phone_height": 149.2,
                "phone_depth": 16.4,
                "fit_clearance": 0.8,
                "wall_thickness": 2.0,
                "back_thickness": 2.5,
                "lip_height": 1.5,
                "corner_radius": 3.0
            },
            "reasoning": "TYPE A: HOLLOW SHELL. Inner cavity: 64.3×150×17.2mm (phone + 0.8mm clearance). Outer: 68.3×154×19.7mm (adds 2mm walls). Front OPEN for screen. Back CLOSED.",
            "material": "TPU (flexible)"
        }
        
        "spacer block" + Height: 5mm, Width: 20mm:
        {
            "part_type": "solid_spacer",
            "parameters": {
                "length": 20.0,
                "width": 20.0,
                "height": 5.0,
                "chamfer": 0.5
            },
            "reasoning": "TYPE B: SOLID BLOCK. No cavity needed - this fills a gap. 20×20×5mm with chamfered edges for easy placement.",
            "material": "PLA (rigid)"
        }
        
        "mounting bracket" + Width: 40mm, Height: 50mm:
        {
            "part_type": "L_bracket",
            "parameters": {
                "leg_length_1": 40.0,
                "leg_length_2": 50.0,
                "thickness": 3.0,
                "hole_diameter": 4.2,
                "corner_fillet": 5.0
            },
            "reasoning": "TYPE C: MIXED GEOMETRY. Solid L-bracket with mounting holes (4.2mm for M4 screws). Fillet at corner for strength. Not a shell, not a plain block.",
            "material": "PETG (strong, heat resistant)"
        }
        
        NOW GENERATE FOR USER'S REQUEST:
        
        STEP 1: Analyze "\(description)" - Which geometry type (A/B/C)?
        
        STEP 2: Choose parameters based on type:
        - Type A (SHELL): phone_width, phone_height, phone_depth, fit_clearance, wall_thickness, back_thickness
        - Type B (SOLID): length, width, height, chamfer
        - Type C (MIXED): leg_length_1, leg_length_2, thickness, hole_diameter, corner_fillet
        
        STEP 3: Apply labeled measurements to parameters
        - Width → phone_width or length or leg_length
        - Height → phone_height or height
        - Depth → phone_depth or thickness
        
        STEP 4: Add appropriate clearances (ONLY for Type A shells)
        
        Respond ONLY with JSON:
        {
            "part_type": "descriptive_name",
            "parameters": {
                // Choose parameters appropriate for the geometry type
                // Type A: phone_*, fit_clearance, wall_*, lip_*
                // Type B: length, width, height, chamfer
                // Type C: leg_*, thickness, hole_*, fillet
            },
            "reasoning": "TYPE A/B/C: Explain geometry choice and dimensions",
            "material": "PLA or PETG or TPU with reason"
        }
        """
        
        sendRequest(prompt: prompt, completion: completion)
    }
    
    // ✅ Shared request method to avoid code duplication
    private func sendRequest(prompt: String, completion: @escaping (Result<PartSuggestion, Error>) -> Void) {
        let messages: [[String: String]] = [
            ["role": "system", "content": "You are an expert in 3D printed repair parts. Always respond with valid JSON only."],
            ["role": "user", "content": prompt]
        ]
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": messages,
            "temperature": 0.5,  // ✅ Increased for more creativity
            "max_tokens": 800   // ✅ More tokens for complex parts
        ]
        
        guard let url = URL(string: endpoint) else {
            completion(.failure(NSError(domain: "Invalid URL", code: -1)))
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        do {
            request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        } catch {
            completion(.failure(error))
            return
        }
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            if let error = error {
                DispatchQueue.main.async {
                    completion(.failure(error))
                }
                return
            }
            
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(NSError(domain: "No data", code: -1)))
                }
                return
            }
            
            do {
                let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                
                if let choices = json?["choices"] as? [[String: Any]],
                   let firstChoice = choices.first,
                   let message = firstChoice["message"] as? [String: Any],
                   let content = message["content"] as? String {
                    
                    // Clean the response (remove markdown code blocks if present)
                    var cleanContent = content.trimmingCharacters(in: .whitespacesAndNewlines)
                    if cleanContent.hasPrefix("```json") {
                        cleanContent = cleanContent.replacingOccurrences(of: "```json", with: "")
                        cleanContent = cleanContent.replacingOccurrences(of: "```", with: "")
                        cleanContent = cleanContent.trimmingCharacters(in: .whitespacesAndNewlines)
                    }
                    
                    let contentData = cleanContent.data(using: .utf8)!
                    let suggestion = try JSONDecoder().decode(PartSuggestion.self, from: contentData)
                    
                    DispatchQueue.main.async {
                        completion(.success(suggestion))
                    }
                } else {
                    throw NSError(domain: "Invalid response format", code: -1)
                }
            } catch {
                print("⚠️ Decode error: \(error)")
                DispatchQueue.main.async {
                    // More intelligent fallback
                    let fallback = PartSuggestion(
                        partType: "custom",
                        parameters: ["diameter": 40, "height": 10, "thickness": 2.0],
                        reasoning: "Fallback part based on measurement",
                        material: "PLA"
                    )
                    completion(.success(fallback))
                }
            }
        }.resume()
    }
}

