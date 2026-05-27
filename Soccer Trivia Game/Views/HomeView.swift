import SwiftUI

/// Main home screen with authentication and play type selection
struct HomeView: View {
    @StateObject private var authViewModel: AuthViewModel
    
    init(authViewModel: AuthViewModel) {
        _authViewModel = StateObject(wrappedValue: authViewModel)
    }
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView(authViewModel: authViewModel)
                    .environmentObject(authViewModel)
            } else {
                AuthView(authViewModel: authViewModel)
            }
        }
    }
}

/// Home tab content: game mode list. Used inside MainTabView.
struct HomeTabContent: View {
    @ObservedObject var authViewModel: AuthViewModel

    var body: some View {
        homeContent
    }

    private var homeContent: some View {
        ZStack {
            // Background Image
            GeometryReader { geometry in
                Group {
                    // Try multiple methods to load the image
                    if let image = loadBackgroundImage() {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height)
                            .clipped()
                    } else {
                        // Fallback to gradient if image not found
                        RetroTheme.retroGradient
                    }
                }
            }
            .ignoresSafeArea()
            
            // Dark overlay for readability
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
            
            // Content
            VStack(spacing: 28) {
                Spacer()
                    .frame(height: 40)
                
                // Logo
                if let logoImage = loadLogoImage() {
                    Image(uiImage: logoImage)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 150, height: 150)
                        .shadow(color: Color.black.opacity(0.5), radius: 10, x: 0, y: 5)
                        .padding(.top, 40)
                        .transition(.opacity)
                } else {
                    // Fallback icon if logo not found
                    ZStack {
                        Circle()
                            .fill(RetroTheme.Colors.neonGreen.opacity(0.2))
                            .frame(width: 150, height: 150)
                            .shadow(color: RetroTheme.Colors.neonGreen.opacity(0.5), radius: 15, x: 0, y: 0)
                        
                        Image(systemName: "soccerball")
                            .font(.system(size: 80))
                            .foregroundColor(RetroTheme.Colors.neonGreen)
                            .shadow(color: RetroTheme.Colors.neonGreen.opacity(0.8), radius: 10, x: 0, y: 0)
                    }
                    #if DEBUG
                    .onAppear {
                        print("⚠️ Logo not found. Trying to locate...")
                        if let bundlePath = Bundle.main.resourcePath {
                            let fullPath = "\(bundlePath)/images/logo.png"
                            print("📁 Checking: \(fullPath)")
                            print("📁 Exists: \(FileManager.default.fileExists(atPath: fullPath))")
                        }
                    }
                    #endif
                    .padding(.top, 40)
                }
                
                Spacer(minLength: 10)
                
                // Game Mode Selection
                VStack(spacing: 16) {
                    // Soccerholic (Online Multiplayer)
                    NavigationLink {
                        CreateJoinView(authViewModel: authViewModel, difficulty: .medium)
                    } label: {
                        HStack {
                            Image(systemName: GameMode.fanaticos.icon)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SOCCERHOLIC (ONLINE)")
                                    .retroText(style: RetroTheme.Typography.retroHeadline(size: 22), color: .white)
                                Text("Real-time multiplayer quiz mode")
                                    .retroText(style: RetroTheme.Typography.retroCaption(size: 13), color: RetroTheme.Colors.retroGray)
                            }
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                    }
                    .retroButton(color: RetroTheme.Colors.neonGreen)
                    .shadow(color: RetroTheme.Colors.neonGreen.opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    // Solo Quiz
                    NavigationLink {
                        SoloQuizStartView()
                    } label: {
                        HStack {
                            Image(systemName: GameMode.quiz.icon)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("SOLO QUIZ")
                                    .retroText(style: RetroTheme.Typography.retroHeadline(size: 22), color: .white)
                                Text("Answer 10 random trivia questions")
                                    .retroText(style: RetroTheme.Typography.retroCaption(size: 13), color: RetroTheme.Colors.retroGray)
                            }
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                    }
                    .retroButton(color: RetroTheme.Colors.neonBlue)
                    .shadow(color: RetroTheme.Colors.neonBlue.opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    // Guess the Player
                    NavigationLink {
                        GuessPlayerStartView(playType: .local)
                    } label: {
                        HStack {
                            Image(systemName: GameMode.guessPlayer.icon)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("GUESS THE PLAYER")
                                    .retroText(style: RetroTheme.Typography.retroHeadline(size: 22), color: .white)
                                Text("Identify players from their photos")
                                    .retroText(style: RetroTheme.Typography.retroCaption(size: 13), color: RetroTheme.Colors.retroGray)
                            }
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                    }
                    .retroButton(color: RetroTheme.Colors.neonGreen)
                    .shadow(color: RetroTheme.Colors.neonGreen.opacity(0.5), radius: 10, x: 0, y: 5)
                    
                    // Guess the Club Logo
                    NavigationLink {
                        GuessLogoStartView(playType: .local)
                    } label: {
                        HStack {
                            Image(systemName: GameMode.guessLogo.icon)
                                .font(.title2)
                            VStack(alignment: .leading, spacing: 4) {
                                Text("GUESS THE CLUB LOGO")
                                    .retroText(style: RetroTheme.Typography.retroHeadline(size: 22), color: .white)
                                Text("Match badges to the right clubs")
                                    .retroText(style: RetroTheme.Typography.retroCaption(size: 13), color: RetroTheme.Colors.retroGray)
                            }
                            Spacer()
                            Image(systemName: "arrow.right")
                                .font(.title3)
                                .foregroundColor(.white)
                        }
                        .padding(.vertical, 14)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                    }
                    .retroButton(color: RetroTheme.Colors.neonYellow)
                    .shadow(color: RetroTheme.Colors.neonYellow.opacity(0.5), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .preferredColorScheme(.dark)
    }

    private func loadBackgroundImage() -> UIImage? {
        // Method 1: Try with directory
        if let imagePath = Bundle.main.path(forResource: "main image", ofType: "jpg", inDirectory: "images"),
           let image = UIImage(contentsOfFile: imagePath) {
            return image
        }
        
        // Method 2: Try without directory (if images are at root)
        if let imagePath = Bundle.main.path(forResource: "main image", ofType: "jpg"),
           let image = UIImage(contentsOfFile: imagePath) {
            return image
        }
        
        // Method 3: Try with different naming
        if let imagePath = Bundle.main.path(forResource: "main_image", ofType: "jpg", inDirectory: "images"),
           let image = UIImage(contentsOfFile: imagePath) {
            return image
        }
        
        // Method 4: Try loading from bundle resource URL
        if let resourceURL = Bundle.main.resourceURL,
           let imagePath = Bundle.main.path(forResource: "main image", ofType: "jpg", inDirectory: "images") {
            return UIImage(contentsOfFile: imagePath)
        }
        
        // Method 5: Try direct file system access
        if let bundlePath = Bundle.main.resourcePath {
            let fullPath = "\(bundlePath)/images/main image.jpg"
            if FileManager.default.fileExists(atPath: fullPath),
               let image = UIImage(contentsOfFile: fullPath) {
                return image
            }
        }
        
        return nil
    }

    private func loadLogoImage() -> UIImage? {
        // Method 1: Try with directory
        if let logoPath = Bundle.main.path(forResource: "logo", ofType: "png", inDirectory: "images"),
           let logoImage = UIImage(contentsOfFile: logoPath) {
            return logoImage
        }
        
        // Method 2: Try without directory
        if let logoPath = Bundle.main.path(forResource: "logo", ofType: "png"),
           let logoImage = UIImage(contentsOfFile: logoPath) {
            return logoImage
        }
        
        // Method 3: Try direct file system access
        if let bundlePath = Bundle.main.resourcePath {
            let fullPath = "\(bundlePath)/images/logo.png"
            if FileManager.default.fileExists(atPath: fullPath),
               let logoImage = UIImage(contentsOfFile: fullPath) {
                return logoImage
            }
        }
        
        return nil
    }
}
