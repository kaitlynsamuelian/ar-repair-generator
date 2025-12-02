//
//  MeasurementState.swift
//  ARRepairGenerator
//

import Foundation
import Combine
import SceneKit

enum AppState {
    case measuring
    case partSelection
}

enum MeasurementType: String, CaseIterable, Identifiable {
    case width = "Width"
    case height = "Height"
    case depth = "Depth"
    case diameter = "Diameter"
    case thickness = "Thickness"
    case other = "Other"
    
    var id: String { self.rawValue }
}

// Represents a single measurement line
struct Measurement: Identifiable {
    let id = UUID()
    let distance: Double // in meters
    let startPoint: SCNVector3
    let endPoint: SCNVector3
    let timestamp: Date
    var type: MeasurementType = .other // User can categorize this!
    
    var distanceMM: Double {
        distance * 1000
    }
    
    var label: String {
        String(format: "%.1fmm", distanceMM)
    }
}

class MeasurementState: ObservableObject {
    @Published var measurements: [Measurement] = []
    @Published var measurementText: String = "Tap to start measuring"
    @Published var appState: AppState = .measuring
    @Published var showingCategoryPicker: UUID? = nil // ID of measurement to categorize
    @Published var sidebarCollapsed: Bool = false
    
    var onClearRequested: (() -> Void)?
    
    init() {
        // Initialize with empty state
        self.measurements = []
        self.measurementText = "Tap to start measuring"
        self.appState = .measuring
    }
    
    // Current distance for compatibility (uses last measurement)
    var currentDistance: Double {
        measurements.last?.distance ?? 0
    }
    
    // Get measurements by type
    func getMeasurements(ofType type: MeasurementType) -> [Measurement] {
        measurements.filter { $0.type == type }
    }
    
    // Update measurement type
    func updateMeasurementType(id: UUID, type: MeasurementType) {
        if let index = measurements.firstIndex(where: { $0.id == id }) {
            measurements[index].type = type
            updateText()
        }
    }
    
    func addMeasurement(distance: Double, start: SCNVector3, end: SCNVector3) {
        let measurement = Measurement(
            distance: distance,
            startPoint: start,
            endPoint: end,
            timestamp: Date()
        )
        measurements.append(measurement)
        
        updateText()
        print("📏 Added measurement #\(measurements.count): \(String(format: "%.1f", distance * 1000))mm")
    }
    
    func removeMeasurement(id: UUID) {
        measurements.removeAll { $0.id == id }
        updateText()
        onClearRequested?() // Signal AR view to redraw
    }
    
    func proceedToPartSelection() {
        appState = .partSelection
    }
    
    func backToMeasuring() {
        appState = .measuring
    }
    
    func clear() {
        measurements.removeAll()
        measurementText = "Tap to start measuring"
        appState = .measuring
        onClearRequested?()
    }
    
    private func updateText() {
        if measurements.isEmpty {
            measurementText = "Tap to start measuring"
        } else {
            let categorized = measurements.filter { $0.type != .other }.count
            if categorized == 0 {
                measurementText = String(format: "%d measurements - Label them!", measurements.count)
            } else if categorized == measurements.count {
                measurementText = String(format: "%d measurements labeled ✓", measurements.count)
            } else {
                measurementText = String(format: "%d/%d labeled", categorized, measurements.count)
            }
        }
    }
}
