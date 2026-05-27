import SwiftUI

/// View for "Guess the Player" question type
struct GuessPlayerView: View {
    let question: Question
    @Binding var guessText: String
    @Binding var isSubmitted: Bool
    let onSubmit: () -> Void
    
    @State private var image: UIImage? = nil
    @State private var isLoadingImage = false
    
    var body: some View {
        VStack(spacing: 24) {
            // Title
            Text("GUESS THE PLAYER")
                .retroText(style: RetroTheme.Typography.retroHeadline(size: 24), color: RetroTheme.Colors.neonGreen)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(RetroTheme.Colors.darkBackground)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(RetroTheme.Colors.neonGreen, lineWidth: 2)
                )
            
            // Player Image
            Group {
                if isLoadingImage {
                    ProgressView()
                        .tint(RetroTheme.Colors.neonGreen)
                        .frame(width: 200, height: 200)
                } else if let image = image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(RetroTheme.Colors.neonBlue, lineWidth: 3)
                                .shadow(color: RetroTheme.Colors.neonBlue.opacity(0.6), radius: 5, x: 0, y: 0)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(RetroTheme.Colors.darkBackground)
                        .frame(width: 200, height: 200)
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(RetroTheme.Colors.retroGray, lineWidth: 2)
                        )
                }
            }
            .padding(.vertical, 12)
            
            // Question Text
            Text(question.text)
                .retroText(style: RetroTheme.Typography.retroBody(size: 18), color: RetroTheme.Colors.retroWhite)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 30)
            
            // Text Input
            VStack(alignment: .leading, spacing: 8) {
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
                            .stroke(guessText.isEmpty ? RetroTheme.Colors.retroGray : RetroTheme.Colors.neonBlue, lineWidth: 2)
                    )
                    .disabled(isSubmitted)
            }
            .padding(.horizontal, 30)
            
            // Submit Button
            Button(action: {
                SoundManager.shared.playButtonClick()
                onSubmit()
            }) {
                Text("SUBMIT")
                    .retroText(style: RetroTheme.Typography.retroHeadline(size: 20), color: .white)
                    .frame(maxWidth: .infinity)
                    .padding()
            }
            .retroButton(color: RetroTheme.Colors.neonGreen)
            .disabled(guessText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitted)
            .opacity(guessText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isSubmitted ? 0.5 : 1.0)
            .padding(.horizontal, 30)
            .padding(.top, 8)
        }
        .padding(.vertical, 20)
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        guard let guessPlayer = question.guessPlayer else { return }
        let imageURL = guessPlayer.imageURL
        
        isLoadingImage = true
        
        // Local bundle image (Fanáticos mix mode): "local:Player Name"
        if imageURL.hasPrefix("local:") {
            let name = String(imageURL.dropFirst(6)).trimmingCharacters(in: .whitespaces)
            if let localImage = PlayerImageResolver.image(for: name) {
                await MainActor.run {
                    self.image = localImage
                    self.isLoadingImage = false
                }
                return
            }
        }
        
        // Load from URL
        if let url = URL(string: imageURL), url.scheme != nil {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let loadedImage = UIImage(data: data) {
                    await MainActor.run {
                        self.image = loadedImage
                        self.isLoadingImage = false
                    }
                    return
                }
            } catch {
                print("Failed to load image from URL: \(error)")
            }
        }
        
        // Fallback to placeholder
        await MainActor.run {
            self.isLoadingImage = false
        }
    }
}

#Preview {
    GuessPlayerView(
        question: Question(
            type: .guessPlayer,
            text: "Guess the player",
            options: [],
            correctAnswer: -1,
            guessPlayer: Question.GuessPlayerPayload(
                imageURL: "https://media.api-sports.io/football/players/276.png",
                canonical: Question.GuessPlayerPayload.Canonical(first: "Kylian", last: "Mbappé"),
                aliases: ["Mbappé", "KM7"],
                constraints: Question.GuessPlayerPayload.Constraints(minChars: 3, allowSingleToken: true)
            )
        ),
        guessText: .constant(""),
        isSubmitted: .constant(false),
        onSubmit: {}
    )
    .background(RetroTheme.retroGradient)
}

