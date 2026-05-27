import SwiftUI

/// Retro 80s/90s style theme for Soccer Trivia
struct RetroTheme {
    // Retro Color Palette (Dimmed for better visibility)
    struct Colors {
        // Primary colors (dimmed ~40%)
        static let neonGreen = Color(red: 0.0, green: 0.6, blue: 0.3)
        static let neonPink = Color(red: 0.6, green: 0.0, blue: 0.5)
        static let neonBlue = Color(red: 0.0, green: 0.5, blue: 0.6)
        static let neonYellow = Color(red: 0.6, green: 0.6, blue: 0.0)
        static let neonOrange = Color(red: 0.6, green: 0.3, blue: 0.0)
        
        // Background colors
        static let darkBackground = Color(red: 0.1, green: 0.1, blue: 0.15)
        static let darkerBackground = Color(red: 0.05, green: 0.05, blue: 0.1)
        
        // Text colors
        static let retroWhite = Color.white
        static let retroGray = Color(red: 0.7, green: 0.7, blue: 0.7)
        
        // Accent colors (dimmed)
        static let retroRed = Color(red: 0.6, green: 0.12, blue: 0.12)
        static let retroPurple = Color(red: 0.36, green: 0.12, blue: 0.6)
    }
    
    // Retro Typography
    struct Typography {
        static func retroTitle(size: CGFloat = 36) -> Font {
            let scale: CGFloat = 0.8
            return .system(size: size * scale, weight: .black, design: .rounded)
        }
        
        static func retroHeadline(size: CGFloat = 24) -> Font {
            let scale: CGFloat = 0.8
            return .system(size: size * scale, weight: .bold, design: .rounded)
        }
        
        static func retroBody(size: CGFloat = 18) -> Font {
            let scale: CGFloat = 0.8
            return .system(size: size * scale, weight: .semibold, design: .rounded)
        }
        
        static func retroCaption(size: CGFloat = 14) -> Font {
            let scale: CGFloat = 0.8
            return .system(size: size * scale, weight: .medium, design: .monospaced)
        }
    }
    
    // Retro Button Styles
    struct ButtonStyles {
        static func neonButton(color: Color) -> some View {
            RoundedRectangle(cornerRadius: 12)
                .fill(color)
                .shadow(color: color.opacity(0.8), radius: 10, x: 0, y: 0)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white, lineWidth: 2)
                )
        }
        
        static func retroBorder(color: Color, width: CGFloat = 3) -> some View {
            RoundedRectangle(cornerRadius: 12)
                .stroke(color, lineWidth: width)
                .shadow(color: color.opacity(0.6), radius: 5, x: 0, y: 0)
        }
    }
    
    // Retro Card Style
    static func retroCard(backgroundColor: Color = Colors.darkBackground) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Colors.neonGreen, lineWidth: 2)
            )
            .shadow(color: Colors.neonGreen.opacity(0.3), radius: 10, x: 0, y: 5)
    }
    
    // Retro Gradient Background
    static let retroGradient = LinearGradient(
        colors: [
            Colors.darkerBackground,
            Colors.darkBackground,
            Color(red: 0.15, green: 0.1, blue: 0.2)
        ],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )
    
    // Retro Scanline Effect (optional overlay)
    static func scanlineOverlay() -> some View {
        GeometryReader { geometry in
            Path { path in
                for i in stride(from: 0, to: geometry.size.height, by: 4) {
                    path.move(to: CGPoint(x: 0, y: i))
                    path.addLine(to: CGPoint(x: geometry.size.width, y: i))
                }
            }
            .stroke(Color.black.opacity(0.1), lineWidth: 1)
        }
    }
}

// Retro View Modifiers
struct RetroButtonModifier: ViewModifier {
    let color: Color
    let isPressed: Bool
    
    func body(content: Content) -> some View {
        content
            .font(RetroTheme.Typography.retroBody())
            .foregroundColor(.white)
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(color)
                    .shadow(color: color.opacity(isPressed ? 0.4 : 0.8), radius: isPressed ? 5 : 10, x: 0, y: isPressed ? 2 : 5)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white, lineWidth: 2)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
    }
}

extension View {
    func retroButton(color: Color, isPressed: Bool = false) -> some View {
        modifier(RetroButtonModifier(color: color, isPressed: isPressed))
    }
    
    func retroCard(backgroundColor: Color = RetroTheme.Colors.darkBackground) -> some View {
        self
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(backgroundColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(RetroTheme.Colors.neonGreen, lineWidth: 2)
                    )
                    .shadow(color: RetroTheme.Colors.neonGreen.opacity(0.3), radius: 10, x: 0, y: 5)
            )
    }
    
    func retroText(style: Font, color: Color = RetroTheme.Colors.retroWhite) -> some View {
        self
            .font(style)
            .foregroundColor(color)
            .shadow(color: color.opacity(0.5), radius: 3, x: 0, y: 0)
    }
}

