import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// One-time username setup for users without a Firestore profile (e.g. guest or legacy sign-in).
struct UsernameSetupView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var username = ""
    @State private var copiedDetails = false

    var body: some View {
        ZStack {
            RetroTheme.retroGradient
                .ignoresSafeArea()
            VStack(spacing: 24) {
                Text("CHOOSE YOUR USERNAME")
                    .retroText(style: RetroTheme.Typography.retroTitle(size: 28), color: RetroTheme.Colors.neonGreen)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Text("This will be used so friends can find you. Must be unique.")
                    .retroText(style: RetroTheme.Typography.retroCaption(size: 14), color: RetroTheme.Colors.retroGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Text("If your account was just created, this is the final step to finish setup.")
                    .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.retroGray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                TextField("USERNAME", text: $username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .font(RetroTheme.Typography.retroHeadline(size: 18))
                    .foregroundColor(RetroTheme.Colors.retroWhite)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(RetroTheme.Colors.darkBackground)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(RetroTheme.Colors.neonYellow, lineWidth: 3)
                    )
                    .padding(.horizontal, 40)
                if let error = authViewModel.errorMessage {
                    VStack(spacing: 10) {
                        Text(error)
                            .retroText(style: RetroTheme.Typography.retroCaption(size: 13), color: RetroTheme.Colors.retroRed)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        if authViewModel.errorDetails != nil {
                            Button(action: copyErrorDetails) {
                                HStack {
                                    Image(systemName: copiedDetails ? "checkmark.circle.fill" : "doc.on.doc")
                                    Text(copiedDetails ? "DETAILS COPIED" : "COPY TECHNICAL DETAILS")
                                        .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.retroGray)
                                }
                            }
                        }
                    }
                }
                Button(action: submit) {
                    HStack {
                        Text("CONTINUE")
                            .retroText(style: RetroTheme.Typography.retroHeadline(size: 18), color: .white)
                        Image(systemName: "arrow.right")
                            .font(.title3)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
                .retroButton(color: RetroTheme.Colors.neonGreen)
                .disabled(authViewModel.isLoading || username.trimmingCharacters(in: .whitespaces).count < 2)
                .opacity((authViewModel.isLoading || username.trimmingCharacters(in: .whitespaces).count < 2) ? 0.6 : 1)
                .padding(.horizontal, 40)
                if authViewModel.isLoading {
                    ProgressView()
                        .tint(RetroTheme.Colors.neonGreen)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func submit() {
        SoundManager.shared.playButtonClick()
        Task {
            await authViewModel.submitUsernameSetup(username: username)
        }
    }
    
    private func copyErrorDetails() {
        guard let details = authViewModel.errorDetails else { return }
        #if canImport(UIKit)
        UIPasteboard.general.string = details
        #endif
        copiedDetails = true
    }
}
