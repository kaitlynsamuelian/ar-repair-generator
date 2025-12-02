//
//  MeasurementUI.swift
//  ARRepairGenerator
//

import SwiftUI
import SceneKit

struct MeasurementUI: View {
    @ObservedObject var measurementState: MeasurementState
    @State private var selectedPart: String? = nil
    @State private var showingPart: Bool = false
    @State private var partDescription: String = ""
    @State private var currentPartNode: SCNNode? = nil
    @State private var currentAISuggestion: AIAssistant.PartSuggestion? = nil // Store AI data for OpenSCAD
    @State private var showPresetParts: Bool = false // Collapsible preset parts
    @FocusState private var isInputFocused: Bool
    
    private let stlExporter = STLExporter()
    private let scadExporter = OpenSCADExporter() // NEW: OpenSCAD exporter
    
    private var aiAssistant: AIAssistant {
        if let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENAI_API_KEY") as? String {
            return AIAssistant(apiKey: apiKey)
        } else {
            return AIAssistant(apiKey: "")
        }
    }
    
    let partTypes = [
        ("📏", "Shim", "shim"),
        ("⭕", "Washer", "washer"),
        ("📐", "Bracket", "bracket"),
        ("🔩", "Clamp", "clamp"),
        ("⬜", "Plate", "plate"),
        ("📎", "Clip", "clip")
    ]
    
    var body: some View {
        // Only show part selection when in that mode
        if measurementState.appState == .partSelection {
            // Part selection view
            partSelectionView
        }
    }
    
    // ✨ Part selection screen (only shows after "Next")
    var partSelectionView: some View {
        VStack(spacing: 16) {
            // Show ALL measurements with their labels
            VStack(spacing: 12) {
                HStack {
                    Text("Your Measurements")
                        .font(.appTitle)
                        .foregroundColor(Color.appTextDark)
                    Spacer()
                    Button(action: {
                        measurementState.backToMeasuring()
                        clearMeasurements()
                    }) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.left")
                            Text("Edit")
                        }
                    }
                    .buttonStyle(SmallButtonStyle())
                }
                
                // Display all measurements grouped by type
                VStack(spacing: 8) {
                    ForEach(MeasurementType.allCases.filter { type in
                        !measurementState.getMeasurements(ofType: type).isEmpty
                    }) { type in
                        HStack {
                            Image(systemName: iconForType(type))
                                .foregroundColor(Color.appPink)
                                .frame(width: 24)
                            
                            Text(type.rawValue + ":")
                                .font(.appBodyBold)
                                .foregroundColor(Color.appTextDark)
                            
                            Spacer()
                            
                            Text(measurementState.getMeasurements(ofType: type).map { $0.label }.joined(separator: ", "))
                                .font(.system(size: 16, weight: .bold, design: .monospaced))
                                .foregroundColor(Color.appPink)
                        }
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                        .cardStyle()
                    }
                }
            }
            .padding()
            .background(Color.appWhite)
            .cornerRadius(16)
            .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
            
            ScrollView {
                VStack(spacing: 20) {
                    // 🌟 AI CUSTOM PART GENERATOR - MAIN FOCUS
                    VStack(spacing: 16) {
                        SectionHeader("AI Part Generator", icon: "sparkles")
                        
                        Text("Describe what you need and AI will generate a custom part using your measurements:")
                            .font(.appBody)
                            .foregroundColor(Color.appTextLight)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        TextField("e.g., 'water bottle lid', 'missing knob', 'bracket'", text: $partDescription)
                            .focused($isInputFocused)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                            .padding(.vertical, 4)
                            .tint(Color.appPink)
                        
                        Button(action: {
                            isInputFocused = false
                            generateCustomPartWithAI()
                        }) {
                            HStack(spacing: 8) {
                                Image(systemName: "wand.and.stars")
                                Text("Generate AI Part")
                            }
                            .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(partDescription.isEmpty)
                        .opacity(partDescription.isEmpty ? 0.5 : 1.0)
                    }
                    .padding(20)
                    .cardStyle()
                    
                    // Collapsible Preset Parts Section
                    DisclosureGroup(
                        isExpanded: $showPresetParts,
                        content: {
                            VStack(spacing: 16) {
                                Text("Quick preset parts based on your measurements")
                                    .font(.appCaption)
                                    .foregroundColor(Color.appTextLight)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.top, 8)
                                
                                // Preset part selection grid
                                LazyVGrid(columns: [
                                    GridItem(.flexible()),
                                    GridItem(.flexible()),
                                    GridItem(.flexible())
                                ], spacing: 12) {
                                    ForEach(partTypes, id: \.2) { emoji, name, type in
                                        PartButton(
                                            emoji: emoji,
                                            name: name,
                                            isSelected: selectedPart == type
                                        ) {
                                            selectedPart = type
                                        }
                                    }
                                }
                                
                                Button(action: {
                                    if let part = selectedPart {
                                        generatePresetPart(type: part)
                                    }
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "cube.fill")
                                        Text("Generate Selected Preset")
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .buttonStyle(SecondaryButtonStyle())
                                .disabled(selectedPart == nil)
                                .opacity(selectedPart == nil ? 0.5 : 1.0)
                            }
                            .padding(.vertical, 8)
                        },
                        label: {
                            HStack(spacing: 8) {
                                Image(systemName: "square.grid.2x2")
                                    .foregroundColor(Color.appPink)
                                Text("Or Choose Preset Part")
                                    .font(.appBodyBold)
                                    .foregroundColor(Color.appTextDark)
                            }
                            .padding(.vertical, 8)
                        }
                    )
                    .tint(Color.appPink)
                    .padding()
                    .background(Color.appPinkLight.opacity(0.5))
                    .cornerRadius(12)
                    
                    // Export buttons (shows when part is generated)
                    if showingPart {
                        VStack(spacing: 12) {
                            Text("✨ Part Generated Successfully!")
                                .font(.appHeadline)
                                .foregroundColor(Color.appPink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            // STL Export
                            Button(action: exportSTL) {
                                HStack(spacing: 8) {
                                    Image(systemName: "cube")
                                    Text("Export STL")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            
                            // OpenSCAD Export
                            Button(action: exportOpenSCAD) {
                                HStack(spacing: 8) {
                                    Image(systemName: "gearshape.2")
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text("Export OpenSCAD")
                                        Text("✨ Includes threads & parameters")
                                            .font(.appCaptionSmall)
                                    }
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SecondaryButtonStyle())
                            
                            // Clear button
                            Button(action: clearMeasurements) {
                                HStack(spacing: 8) {
                                    Image(systemName: "trash")
                                    Text("Clear & Start Over")
                                }
                                .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(SmallButtonStyle(isDestructive: true))
                        }
                        .padding(20)
                        .background(Color.appWhite)
                        .cornerRadius(16)
                        .shadow(color: Color.black.opacity(0.08), radius: 8, y: 4)
                    }
                }
            }
            .padding()
            .overlayBar()
        }
        .onTapGesture {
            isInputFocused = false
        }
    }
    
    func generateCustomPartWithAI() {
        // Build context from labeled measurements
        var measurementContext = ""
        for type in MeasurementType.allCases {
            let measurements = measurementState.getMeasurements(ofType: type)
            if !measurements.isEmpty {
                let values = measurements.map { String(format: "%.1f", $0.distanceMM) }.joined(separator: ", ")
                measurementContext += "\(type.rawValue): \(values)mm\n"
            }
        }
        
        let primaryMeasurement = measurementState.currentDistance
        
        print("🤖 AI generating: '\(partDescription)'")
        print("   Measurements:\n\(measurementContext)")
        
        aiAssistant.suggestCustomPart(
            description: partDescription,
            measurement: primaryMeasurement,
            measurementContext: measurementContext
        ) { result in
            switch result {
            case .success(let suggestion):
                print("✅ AI Custom Part:")
                print("   Type: \(suggestion.partType)")
                print("   Parameters: \(suggestion.parameters)")
                print("   Reasoning: \(suggestion.reasoning)")
                print("   Material: \(suggestion.material)")
                
                let partNode = PartGenerator.generateFromAI(parameters: suggestion.parameters)
                currentPartNode = partNode
                currentAISuggestion = suggestion // Store for OpenSCAD export
                
                showingPart = true
                selectedPart = nil
                measurementState.measurementText = "✨ AI: \(suggestion.reasoning)"
                
            case .failure(let error):
                print("❌ AI Error: \(error.localizedDescription)")
                measurementState.measurementText = "AI error - check API key"
            }
        }
    }
    
    func generatePresetPart(type: String) {
        print("🎨 Generating preset: \(type)")
        
        let distanceMM = measurementState.currentDistance * 1000
        
        let partNode: SCNNode
        
        switch type {
        case "shim":
            partNode = PartGenerator.generateShim(length: distanceMM, width: distanceMM * 0.8, thickness: 2.0)
        case "washer":
            partNode = PartGenerator.generateWasher(outerDiameter: distanceMM, innerDiameter: distanceMM * 0.5, thickness: 3.0)
        case "bracket", "clamp", "plate", "clip":
            partNode = PartGenerator.generateShim(length: distanceMM, width: distanceMM, thickness: 3.0)
        default:
            partNode = PartGenerator.generateShim(length: 30, width: 30, thickness: 2.0)
        }
        
        currentPartNode = partNode
        currentAISuggestion = nil // No AI data for presets
        showingPart = true
        measurementState.measurementText = "Generated: \(type)"
    }
    
    func clearMeasurements() {
        print("🗑️ Clearing all...")
        selectedPart = nil
        showingPart = false
        partDescription = ""
        currentPartNode = nil
        currentAISuggestion = nil
        isInputFocused = false
        measurementState.clear()
    }
    
    func exportSTL() {
        guard let partNode = currentPartNode else {
            print("❌ No part to export")
            return
        }
        
        print("📦 Exporting to STL...")
        
        let timestamp = Date().formatted(.iso8601).replacingOccurrences(of: ":", with: "-")
        let partName = partDescription.isEmpty ? "repair_part" : partDescription.replacingOccurrences(of: " ", with: "_")
        let filename = "\(partName)_\(timestamp).stl"
        
        if let fileURL = stlExporter.exportToBinarySTL(node: partNode, filename: filename) {
            print("✅ STL created: \(fileURL.lastPathComponent)")
            
            shareFile(fileURL: fileURL, successMessage: "📤 STL ready!")
        } else {
            measurementState.measurementText = "❌ Export failed"
        }
    }
    
    func exportOpenSCAD() {
        guard let suggestion = currentAISuggestion else {
            print("⚠️ No AI suggestion data - can't export to OpenSCAD")
            measurementState.measurementText = "⚠️ Only AI-generated parts support OpenSCAD export"
            return
        }
        
        print("📐 Exporting to OpenSCAD...")
        
        let timestamp = Date().formatted(.iso8601).replacingOccurrences(of: ":", with: "-")
        let partName = partDescription.replacingOccurrences(of: " ", with: "_")
        let filename = "\(partName)_\(timestamp).scad"
        
        if let fileURL = scadExporter.exportToOpenSCAD(
            partType: suggestion.partType,
            parameters: suggestion.parameters,
            description: partDescription,
            material: suggestion.material,
            filename: filename
        ) {
            print("✅ OpenSCAD created: \(fileURL.lastPathComponent)")
            
            shareFile(fileURL: fileURL, successMessage: "📐 OpenSCAD ready! Open in OpenSCAD app.")
        } else {
            measurementState.measurementText = "❌ OpenSCAD export failed"
        }
    }
    
    private func iconForType(_ type: MeasurementType) -> String {
        switch type {
        case .width: return "arrow.left.and.right"
        case .height: return "arrow.up.and.down"
        case .depth: return "arrow.forward.backward"
        case .diameter: return "circle.dashed"
        case .thickness: return "square.stack.3d.up"
        case .other: return "questionmark.circle"
        }
    }
    
    private func shareFile(fileURL: URL, successMessage: String) {
        DispatchQueue.main.async {
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let rootVC = windowScene.windows.first?.rootViewController {
                
                let activityVC = UIActivityViewController(
                    activityItems: [fileURL],
                    applicationActivities: nil
                )
                
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = rootVC.view
                    popover.sourceRect = CGRect(x: rootVC.view.bounds.midX, y: rootVC.view.bounds.midY, width: 0, height: 0)
                    popover.permittedArrowDirections = []
                }
                
                rootVC.present(activityVC, animated: true) {
                    measurementState.measurementText = successMessage
                }
            }
        }
    }
}

struct PartButton: View {
    let emoji: String
    let name: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(emoji).font(.largeTitle)
                Text(name)
                    .font(.appCaption)
                    .fontWeight(.medium)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(isSelected ? Color.appPink : Color.appWhite)
            .foregroundColor(isSelected ? Color.appWhite : Color.appTextDark)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.appPink : Color.appBorder, lineWidth: 2)
            )
            .shadow(color: isSelected ? Color.appPink.opacity(0.3) : Color.clear, radius: 4, y: 2)
        }
    }
}

#Preview {
    MeasurementUI(measurementState: MeasurementState())
}


