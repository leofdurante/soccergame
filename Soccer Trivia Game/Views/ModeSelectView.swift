import SwiftUI

/// View for selecting a specific game mode after choosing Multiplayer or Local
struct ModeSelectView: View {
    let playType: PlayType
    @ObservedObject var authViewModel: AuthViewModel
    @State private var selectedMode: GameMode?
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        ZStack {
            // Background - reuse similar style to HomeView
            GeometryReader { geometry in
                Group {
                    if let image = loadBackgroundImage() {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    } else {
                        RetroTheme.retroGradient
                    }
                }
            }
            .ignoresSafeArea()
            
            // Dark overlay
            LinearGradient(
                colors: [
                    Color.black.opacity(0.6),
                    Color.black.opacity(0.4),
                    Color.black.opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Play Type Badge
                    HStack {
                        Image(systemName: playType.icon)
                            .font(.title3)
                        Text(playType.displayName.uppercased())
                            .retroText(style: RetroTheme.Typography.retroHeadline(size: 16), color: .white)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(playType == .multiplayer ? RetroTheme.Colors.neonGreen.opacity(0.3) : RetroTheme.Colors.neonBlue.opacity(0.3))
                    )
                    .overlay(
                        Capsule()
                            .stroke(playType == .multiplayer ? RetroTheme.Colors.neonGreen : RetroTheme.Colors.neonBlue, lineWidth: 2)
                    )
                    .padding(.top, 20)
                    
                    // Title
                    Text("SELECT GAME MODE")
                        .retroText(style: RetroTheme.Typography.retroTitle(size: 32), color: RetroTheme.Colors.neonGreen)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // Mode Selection Buttons
                    VStack(spacing: 20) {
                        ForEach(GameMode.allCases) { mode in
                            Button(action: {
                                SoundManager.shared.playButtonClick()
                                selectedMode = mode
                            }) {
                                VStack(alignment: .leading, spacing: 8) {
                                    HStack {
                                        Image(systemName: mode.icon)
                                            .font(.title2)
                                            .foregroundColor(RetroTheme.Colors.neonGreen)
                                        Text(mode.displayName.uppercased())
                                            .retroText(style: RetroTheme.Typography.retroHeadline(size: 20), color: .white)
                                        Spacer()
                                        Image(systemName: "arrow.right")
                                            .font(.title3)
                                            .foregroundColor(.white)
                                    }
                                    
                                    Text(mode.description)
                                        .retroText(style: RetroTheme.Typography.retroCaption(size: 14), color: RetroTheme.Colors.retroGray)
                                        .multilineTextAlignment(.leading)
                                }
                                .padding(20)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(
                                    RoundedRectangle(cornerRadius: 16)
                                        .fill(RetroTheme.Colors.darkBackground.opacity(0.8))
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16)
                                        .stroke(RetroTheme.Colors.neonGreen.opacity(0.5), lineWidth: 2)
                                )
                                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    Spacer()
                        .frame(height: 40)
                }
                .padding(.vertical, 20)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button(action: {
                    SoundManager.shared.playButtonClick()
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("BACK")
                            .retroText(style: RetroTheme.Typography.retroCaption(), color: RetroTheme.Colors.retroWhite)
                    }
                }
            }
        }
        .navigationDestination(item: $selectedMode) { mode in
            modeStartView(for: mode, playType: playType)
        }
        .preferredColorScheme(.dark)
    }
    
    // Helper function to load background image
    private func loadBackgroundImage() -> UIImage? {
        // Method 1: Try with directory
        if let imagePath = Bundle.main.path(forResource: "main image", ofType: "jpg", inDirectory: "images"),
           let image = UIImage(contentsOfFile: imagePath) {
            return image
        }
        
        // Method 2: Try direct file system access
        if let bundlePath = Bundle.main.resourcePath {
            let fullPath = "\(bundlePath)/images/main image.jpg"
            if FileManager.default.fileExists(atPath: fullPath),
               let image = UIImage(contentsOfFile: fullPath) {
                return image
            }
        }
        
        return nil
    }
    
    @ViewBuilder
    private func modeStartView(for mode: GameMode, playType: PlayType) -> some View {
        switch mode {
        case .fanaticos:
            FanaticosStartView(playType: playType)
        case .quiz:
            QuizStartView(playType: playType, authViewModel: authViewModel)
        case .guessLogo:
            GuessLogoStartView(playType: playType)
        case .guessPlayer:
            GuessPlayerStartView(playType: playType)
        }
    }
}

