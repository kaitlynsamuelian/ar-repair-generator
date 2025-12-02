//
//  Theme.swift
//  ARRepairGenerator
//
//  Professional pink-and-white UI theme
//

import SwiftUI

// MARK: - Color Palette
extension Color {
    // Primary Colors
    static let appPink = Color(hex: "FF4F8B")           // Main pink accent
    static let appPinkDark = Color(hex: "E63E7A")       // Secondary pink (hover/active)
    static let appPinkLight = Color(hex: "FFF2F7")      // Subtle blush pink backgrounds
    
    // Neutrals
    static let appWhite = Color(hex: "FFFFFF")
    static let appTextLight = Color(hex: "6E6E73")      // Light gray text
    static let appTextDark = Color(hex: "1C1C1E")       // Dark text for readability
    static let appBorder = Color(hex: "F7DCE4")         // Soft border color
    
    // Translucent overlays
    static let appOverlay = Color.white.opacity(0.88)   // For camera overlay bars
    
    // Helper initializer for hex colors
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default: (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Typography
extension Font {
    // App-wide typography
    static let appTitle = Font.system(size: 24, weight: .bold, design: .rounded)
    static let appHeadline = Font.system(size: 18, weight: .semibold, design: .default)
    static let appBody = Font.system(size: 16, weight: .regular, design: .default)
    static let appBodyBold = Font.system(size: 16, weight: .semibold, design: .default)
    static let appCaption = Font.system(size: 14, weight: .medium, design: .default)
    static let appCaptionSmall = Font.system(size: 12, weight: .regular, design: .default)
    
    // Measurement labels (monospaced for numbers)
    static let appMeasurement = Font.system(size: 14, weight: .semibold, design: .rounded)
    static let appMeasurementLarge = Font.system(size: 48, weight: .bold, design: .monospaced)
}

// MARK: - Button Styles
struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appBodyBold)
            .foregroundColor(Color.appWhite)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(
                LinearGradient(
                    colors: configuration.isPressed ? [Color.appPinkDark, Color.appPinkDark] : [Color.appPink, Color.appPinkDark],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .cornerRadius(24)
            .shadow(color: Color.appPink.opacity(0.3), radius: 8, y: 4)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appBodyBold)
            .foregroundColor(Color.appPink)
            .padding(.vertical, 14)
            .padding(.horizontal, 24)
            .background(Color.appWhite)
            .cornerRadius(24)
            .overlay(
                RoundedRectangle(cornerRadius: 24)
                    .stroke(Color.appPink, lineWidth: 2)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.3), value: configuration.isPressed)
    }
}

struct SmallButtonStyle: ButtonStyle {
    let isDestructive: Bool
    
    init(isDestructive: Bool = false) {
        self.isDestructive = isDestructive
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.appCaption)
            .foregroundColor(isDestructive ? Color.red : Color.appPink)
            .padding(.vertical, 8)
            .padding(.horizontal, 12)
            .background(Color.appWhite)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isDestructive ? Color.red : Color.appBorder, lineWidth: 1.5)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
    }
}

// MARK: - Measurement Label Styles
struct ActiveMeasurementLabel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appMeasurement)
            .foregroundColor(Color.appWhite)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.appPink)
            .cornerRadius(999) // Pill shape
            .shadow(color: Color.appPink.opacity(0.4), radius: 4, y: 2)
    }
}

struct IdleMeasurementLabel: ViewModifier {
    func body(content: Content) -> some View {
        content
            .font(.appMeasurement)
            .foregroundColor(Color.appPink)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.appWhite)
            .cornerRadius(999) // Pill shape
            .overlay(
                RoundedRectangle(cornerRadius: 999)
                    .stroke(Color.appPink, lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.1), radius: 2, y: 1)
    }
}

extension View {
    func activeMeasurementStyle() -> some View {
        modifier(ActiveMeasurementLabel())
    }
    
    func idleMeasurementStyle() -> some View {
        modifier(IdleMeasurementLabel())
    }
}

// MARK: - Card Styles
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.appPinkLight)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.appBorder, lineWidth: 1)
            )
    }
}

struct OverlayBarBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(
                .ultraThinMaterial
                    .opacity(0.95)
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardBackground())
    }
    
    func overlayBar() -> some View {
        modifier(OverlayBarBackground())
    }
}

// MARK: - Common UI Components
struct MeasurementBadge: View {
    let number: Int
    let isActive: Bool
    
    var body: some View {
        Text("#\(number)")
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .foregroundColor(Color.appWhite)
            .frame(width: 28, height: 28)
            .background(isActive ? Color.appPink : Color.appTextLight)
            .clipShape(Circle())
            .shadow(color: isActive ? Color.appPink.opacity(0.3) : Color.clear, radius: 4)
    }
}

struct SectionHeader: View {
    let title: String
    let icon: String?
    
    init(_ title: String, icon: String? = nil) {
        self.title = title
        self.icon = icon
    }
    
    var body: some View {
        HStack(spacing: 8) {
            if let icon = icon {
                Image(systemName: icon)
                    .foregroundColor(Color.appPink)
                    .font(.title2)
            }
            Text(title)
                .font(.appHeadline)
                .foregroundColor(Color.appTextDark)
            Spacer()
        }
    }
}

