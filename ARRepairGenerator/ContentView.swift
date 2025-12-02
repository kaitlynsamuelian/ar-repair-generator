//
//  ContentView.swift
//  ARRepairGenerator
//

import SwiftUI

struct ContentView: View {
    @StateObject private var measurementState = MeasurementState()

    var body: some View {
        ZStack {
            // AR camera view - only show when measuring
            if measurementState.appState == .measuring {
                ARViewContainer(measurementState: measurementState)
                    .ignoresSafeArea()
                    .transition(.opacity)
            } else {
                // White background when not measuring
                Color.white
                    .ignoresSafeArea()
            }

            // UI overlay
            VStack {
                // Top bar
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("AR Tape Measure")
                            .font(.appHeadline)
                            .foregroundColor(Color.appTextDark)
                        Text(measurementState.measurementText)
                            .font(.appCaption)
                            .foregroundColor(Color.appTextLight)
                    }
                    Spacer()
                }
                .padding()
                .overlayBar()
                
                Spacer()
                
                HStack(spacing: 0) {
                    // Collapsible sidebar with measurements
                    if measurementState.appState == .measuring && !measurementState.measurements.isEmpty {
                        ZStack(alignment: .trailing) {
                            if !measurementState.sidebarCollapsed {
                                MeasurementsSidebar(measurementState: measurementState)
                                    .transition(.move(edge: .leading))
                                    .frame(maxWidth: 300)
                            }
                            
                            // Chevron toggle button on the edge
                            SidebarToggleButton(measurementState: measurementState)
                                .padding(.leading, measurementState.sidebarCollapsed ? 0 : 8)
                        }
                    }
                    
                    Spacer()
                    
                    // "Done Measuring" button (when measuring and has measurements)
                    if measurementState.appState == .measuring && !measurementState.measurements.isEmpty {
                        VStack {
                            Spacer()
                            DoneMeasuringButton(measurementState: measurementState)
                                .padding()
                        }
                    }
                }
                
                // Main UI (part selection)
                if measurementState.appState == .partSelection {
                    MeasurementUI(measurementState: measurementState)
                        .ignoresSafeArea()
                }
            }
            
            // Category picker popup (appears immediately after measurement)
            if let measurementID = measurementState.showingCategoryPicker {
                CategoryPickerPopup(measurementState: measurementState, measurementID: measurementID)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: measurementState.appState)
        .animation(.easeInOut(duration: 0.3), value: measurementState.sidebarCollapsed)
    }
}

// Category picker that appears immediately after measurement
struct CategoryPickerPopup: View {
    @ObservedObject var measurementState: MeasurementState
    let measurementID: UUID
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Text("Categorize This Measurement")
                    .font(.appTitle)
                    .foregroundColor(Color.appTextDark)
                
                if let measurement = measurementState.measurements.first(where: { $0.id == measurementID }) {
                    Text(measurement.label)
                        .font(.appMeasurementLarge)
                        .foregroundColor(Color.appPink)
                }
                
                Text("What did you measure?")
                    .font(.appBody)
                    .foregroundColor(Color.appTextLight)
                
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(MeasurementType.allCases) { type in
                        Button(action: {
                            measurementState.updateMeasurementType(id: measurementID, type: type)
                            withAnimation {
                                measurementState.showingCategoryPicker = nil
                            }
                        }) {
                            VStack(spacing: 8) {
                                Image(systemName: iconForType(type))
                                    .font(.title)
                                    .foregroundColor(Color.appPink)
                                Text(type.rawValue)
                                    .font(.appBodyBold)
                                    .foregroundColor(Color.appTextDark)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.appWhite)
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.appBorder, lineWidth: 1.5)
                            )
                            .shadow(color: Color.black.opacity(0.05), radius: 4, y: 2)
                        }
                    }
                }
                .padding(.horizontal)
            }
            .padding(24)
            .background(Color.appWhite)
            .cornerRadius(24)
            .shadow(color: Color.black.opacity(0.2), radius: 20, y: 10)
            .padding(40)
        }
    }
    
    func iconForType(_ type: MeasurementType) -> String {
        switch type {
        case .width: return "arrow.left.and.right"
        case .height: return "arrow.up.and.down"
        case .depth: return "arrow.forward.backward"
        case .diameter: return "circle.dashed"
        case .thickness: return "square.stack.3d.up"
        case .other: return "questionmark.circle"
        }
    }
}

// Collapsible sidebar showing all measurements
struct MeasurementsSidebar: View {
    @ObservedObject var measurementState: MeasurementState
    
    var body: some View {
        VStack(spacing: 12) {
            HStack {
                Text("Measurements")
                    .font(.appHeadline)
                    .foregroundColor(Color.appTextDark)
                Spacer()
                Button(action: { measurementState.clear() }) {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.caption)
                        Text("Clear")
                            .font(.appCaptionSmall)
                    }
                    .foregroundColor(.red)
                }
            }
            
            ScrollView {
                VStack(spacing: 8) {
                    ForEach(Array(measurementState.measurements.enumerated()), id: \.element.id) { index, measurement in
                        HStack(spacing: 8) {
                            MeasurementBadge(number: index + 1, isActive: measurement.type != .other)
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(measurement.type.rawValue)
                                    .font(.appCaption)
                                    .foregroundColor(measurement.type == .other ? Color.appTextLight : Color.appTextDark)
                                Text(measurement.label)
                                    .font(.appCaptionSmall)
                                    .foregroundColor(Color.appTextLight)
                            }
                            
                            Spacer()
                            
                            Button(action: {
                                measurementState.removeMeasurement(id: measurement.id)
                            }) {
                                Image(systemName: "trash")
                                    .font(.caption2)
                                    .foregroundColor(.red.opacity(0.8))
                            }
                        }
                        .padding(10)
                        .background(Color.appWhite)
                        .cornerRadius(12)
                        .shadow(color: Color.black.opacity(0.05), radius: 2, y: 1)
                    }
                }
            }
            
            // Summary
            if !measurementState.measurements.isEmpty {
                Divider()
                    .background(Color.appBorder)
                
                VStack(alignment: .leading, spacing: 6) {
                    Text("Summary")
                        .font(.appCaption)
                        .foregroundColor(Color.appPink)
                    
                    ForEach(MeasurementType.allCases.filter { type in
                        !measurementState.getMeasurements(ofType: type).isEmpty
                    }) { type in
                        HStack {
                            Text(type.rawValue + ":")
                                .font(.appCaptionSmall)
                                .foregroundColor(Color.appTextLight)
                            Text(measurementState.getMeasurements(ofType: type).map { $0.label }.joined(separator: ", "))
                                .font(.system(size: 12, weight: .semibold, design: .monospaced))
                                .foregroundColor(Color.appTextDark)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding()
        .overlayBar()
        .cornerRadius(16)
        .padding(.leading)
        .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
    }
}

// Sidebar toggle button with chevron icon
struct SidebarToggleButton: View {
    @ObservedObject var measurementState: MeasurementState
    
    var body: some View {
        Button(action: {
            withAnimation(.spring(response: 0.3)) {
                measurementState.sidebarCollapsed.toggle()
            }
        }) {
            Image(systemName: measurementState.sidebarCollapsed ? "chevron.right" : "chevron.left")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(Color.appWhite)
                .frame(width: 30, height: 50)
                .background(Color.appPink)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .shadow(color: Color.appPink.opacity(0.4), radius: 6, x: 2, y: 2)
        }
    }
}

// "Done Measuring" button
struct DoneMeasuringButton: View {
    @ObservedObject var measurementState: MeasurementState
    
    var body: some View {
        VStack(spacing: 12) {
            Button(action: {
                measurementState.proceedToPartSelection()
            }) {
                HStack(spacing: 8) {
                    Text("Done Measuring")
                    Image(systemName: "checkmark.circle.fill")
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
        .padding(.horizontal)
    }
}

#Preview {
    ContentView()
}
