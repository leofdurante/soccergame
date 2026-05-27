import SwiftUI

/// Game round view for guessing a player
struct GuessPlayerRoundView: View {
    let player: PlayerProfile
    @Environment(\.dismiss) private var dismiss
    
    @State private var guessText: String = ""
    @State private var isSubmitted: Bool = false
    @State private var isCorrect: Bool = false
    @State private var showFeedback: Bool = false
    @State private var showNextPlayer: Bool = false
    
    var body: some View {
        ZStack {
            RetroTheme.retroGradient
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    // Title
                    Text("GUESS THE PLAYER")
                        .retroText(style: RetroTheme.Typography.retroTitle(size: 32), color: RetroTheme.Colors.neonGreen)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    
                    // Player Photo
                    AsyncImage(url: URL(string: player.photo)) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .tint(RetroTheme.Colors.neonGreen)
                                .frame(width: 250, height: 250)
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 250, height: 250)
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(RetroTheme.Colors.neonBlue, lineWidth: 4)
                                        .shadow(color: RetroTheme.Colors.neonBlue.opacity(0.6), radius: 10, x: 0, y: 0)
                                )
                        case .failure:
                            Image(systemName: "person.fill")
                                .font(.system(size: 100))
                                .foregroundColor(RetroTheme.Colors.retroGray)
                                .frame(width: 250, height: 250)
                                .background(
                                    RoundedRectangle(cornerRadius: 20)
                                        .fill(RetroTheme.Colors.darkBackground)
                                )
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(RetroTheme.Colors.retroGray, lineWidth: 2)
                                )
                        @unknown default:
                            EmptyView()
                        }
                    }
                    .padding(.vertical, 20)
                    
                    // Text Input
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ENTER PLAYER NAME")
                            .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.retroGray)
                        
                        TextField("Type player name...", text: $guessText)
                            .font(RetroTheme.Typography.retroHeadline(size: 18))
                            .foregroundColor(RetroTheme.Colors.retroWhite)
                            .autocapitalization(.words)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.words)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(RetroTheme.Colors.darkBackground)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(
                                        showFeedback 
                                            ? (isCorrect ? RetroTheme.Colors.neonGreen : RetroTheme.Colors.retroRed)
                                            : (guessText.isEmpty ? RetroTheme.Colors.retroGray : RetroTheme.Colors.neonBlue),
                                        lineWidth: 2
                                    )
                            )
                            .disabled(isSubmitted)
                        
                        if guessText.count > 0 && guessText.count < 3 {
                            Text("Enter at least 3 characters")
                                .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.retroRed.opacity(0.7))
                        }
                    }
                    .padding(.horizontal, 30)
                    
                    // Submit Button
                    Button(action: {
                        SoundManager.shared.playButtonClick()
                        submitGuess()
                    }) {
                        HStack {
                            if showFeedback {
                                Image(systemName: isCorrect ? "checkmark.circle.fill" : "xmark.circle.fill")
                                    .font(.title3)
                            }
                            Text(isSubmitted ? (isCorrect ? "CORRECT!" : "WRONG!") : "SUBMIT")
                                .retroText(style: RetroTheme.Typography.retroHeadline(size: 20), color: .white)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                    }
                    .retroButton(color: showFeedback ? (isCorrect ? RetroTheme.Colors.neonGreen : RetroTheme.Colors.retroRed) : RetroTheme.Colors.neonGreen)
                    .disabled(guessText.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 || isSubmitted)
                    .opacity(guessText.trimmingCharacters(in: .whitespacesAndNewlines).count < 3 || isSubmitted ? 0.5 : 1.0)
                    .padding(.horizontal, 30)
                    
                    // Feedback Message
                    if showFeedback {
                        VStack(spacing: 12) {
                            if isCorrect {
                                Text("✓ CORRECT!")
                                    .retroText(style: RetroTheme.Typography.retroHeadline(size: 24), color: RetroTheme.Colors.neonGreen)
                                
                                Text("The player is: \(player.fullName)")
                                    .retroText(style: RetroTheme.Typography.retroBody(size: 16), color: RetroTheme.Colors.retroGray)
                                    .multilineTextAlignment(.center)
                            } else {
                                Text("✗ WRONG!")
                                    .retroText(style: RetroTheme.Typography.retroHeadline(size: 24), color: RetroTheme.Colors.retroRed)
                                
                                Text("The correct answer is: \(player.fullName)")
                                    .retroText(style: RetroTheme.Typography.retroBody(size: 16), color: RetroTheme.Colors.retroGray)
                                    .multilineTextAlignment(.center)
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(RetroTheme.Colors.darkBackground.opacity(0.5))
                        )
                        .padding(.horizontal, 30)
                    }
                    
                    // Next Player Button (Placeholder)
                    if showFeedback {
                        Button(action: {
                            SoundManager.shared.playButtonClick()
                            dismiss()
                        }) {
                            HStack {
                                Image(systemName: "arrow.left")
                                Text("BACK TO SEARCH")
                                    .retroText(style: RetroTheme.Typography.retroHeadline(size: 18), color: .white)
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                        }
                        .retroButton(color: RetroTheme.Colors.neonBlue)
                        .padding(.horizontal, 30)
                        .padding(.top, 8)
                    }
                    
                    Spacer(minLength: 20)
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
        .preferredColorScheme(.dark)
    }
    
    private func submitGuess() {
        guard !isSubmitted else { return }
        
        let trimmedGuess = guessText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmedGuess.count >= 3 else { return }
        
        isSubmitted = true
        
        // Validate guess
        isCorrect = GuessPlayerValidator.isCorrectGuess(input: trimmedGuess, player: player)
        
        // Show feedback with animation
        withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
            showFeedback = true
        }
    }
}

#Preview {
    NavigationStack {
        GuessPlayerRoundView(
            player: PlayerProfile(
                id: "Q154",
                name: "Kylian Mbappé",
                photo: "https://upload.wikimedia.org/wikipedia/commons/thumb/0/0a/Kylian_Mbapp%C3%A9_2023.jpg/220px-Kylian_Mbapp%C3%A9_2023.jpg",
                source: "wikidata",
                nationality: "France",
                firstname: "Kylian",
                lastname: "Mbappé"
            )
        )
    }
}

