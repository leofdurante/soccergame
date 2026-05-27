import SwiftUI

/// Placeholder start screen for Soccerholic Mode
struct FanaticosStartView: View {
    let playType: PlayType
    @Environment(\.dismiss) private var dismiss
    @State private var showStartConfirmation = false
    
    var body: some View {
        ZStack {
            RetroTheme.retroGradient
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                Spacer()
                
                // Mode Icon
                Image(systemName: GameMode.fanaticos.icon)
                    .font(.system(size: 80))
                    .foregroundColor(RetroTheme.Colors.neonGreen)
                    .shadow(color: RetroTheme.Colors.neonGreen.opacity(0.8), radius: 10, x: 0, y: 0)
                
                // Mode Name
                Text("SOCCERHOLIC MODE")
                    .retroText(style: RetroTheme.Typography.retroTitle(size: 36), color: RetroTheme.Colors.neonGreen)
                    .padding(.horizontal, 20)
                    .multilineTextAlignment(.center)
                
                // Play Type Badge
                HStack {
                    Image(systemName: playType.icon)
                    Text(playType.displayName.uppercased())
                        .retroText(style: RetroTheme.Typography.retroCaption(size: 14), color: .white)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(
                    Capsule()
                        .fill(playType == .multiplayer ? RetroTheme.Colors.neonGreen.opacity(0.3) : RetroTheme.Colors.neonBlue.opacity(0.3))
                )
                .overlay(
                    Capsule()
                        .stroke(playType == .multiplayer ? RetroTheme.Colors.neonGreen : RetroTheme.Colors.neonBlue, lineWidth: 2)
                )
                
                // Description
                Text(GameMode.fanaticos.description)
                    .retroText(style: RetroTheme.Typography.retroBody(size: 16), color: RetroTheme.Colors.retroGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                
                // Start Button
                Button(action: {
                    SoundManager.shared.playButtonClick()
                    showStartConfirmation = true
                }) {
                    HStack {
                        Image(systemName: "play.fill")
                            .font(.title3)
                        Text("START")
                            .retroText(style: RetroTheme.Typography.retroHeadline(size: 24), color: .white)
                    }
                    .padding(.vertical, 18)
                    .padding(.horizontal, 40)
                    .frame(minWidth: 200)
                }
                .retroButton(color: RetroTheme.Colors.neonGreen)
                .shadow(color: RetroTheme.Colors.neonGreen.opacity(0.5), radius: 10, x: 0, y: 5)
                
                Spacer()
            }
            .padding(.vertical, 40)
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
        .alert("Coming Soon", isPresented: $showStartConfirmation) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Soccerholic Mode gameplay is coming soon!")
        }
    }
}

