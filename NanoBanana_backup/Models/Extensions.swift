import SwiftUI
import Foundation

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        
        self.init(
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners
    
    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Custom Font Extension
extension Font {
    static func circularStd(size: CGFloat, weight: Font.Weight = .medium) -> Font {
        return Font.custom("CircularStd-Medium", size: size)
    }
    
    // Predefined sizes for consistency
    static var circularStdTitle: Font {
        return Font.circularStd(size: 28, weight: .medium)
    }
    
    static var circularStdHeadline: Font {
        return Font.circularStd(size: 20, weight: .medium)
    }
    
    static var circularStdBody: Font {
        return Font.circularStd(size: 16, weight: .medium)
    }
    
    static var circularStdCaption: Font {
        return Font.circularStd(size: 14, weight: .medium)
    }
}