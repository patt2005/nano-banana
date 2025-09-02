import SwiftUI

struct AppColors {
    static let primary = Color(red: 255/255, green: 193/255, blue: 7/255) // Google Nano Banana yellow
    static let secondary = Color.white
    
    static let background = primary
    static let surface = secondary
    static let onPrimary = Color.black
    static let onSecondary = Color.black
    static let onBackground = Color.black
    static let onSurface = Color.black
    
    // Additional shades for UI depth
    static let primaryLight = Color(red: 255/255, green: 205/255, blue: 57/255)
    static let primaryDark = Color(red: 230/255, green: 173/255, blue: 0/255)
}