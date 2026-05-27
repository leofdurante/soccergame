import SwiftUI

struct SettingsView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @AppStorage("app_language") private var appLanguage: String = "en"
    @State private var profile: UserProfile?
    @State private var loadedProfile = false

    var body: some View {
        ZStack {
            RetroTheme.retroGradient
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("SETTINGS")
                        .retroText(style: RetroTheme.Typography.retroTitle(size: 28), color: RetroTheme.Colors.neonGreen)
                        .padding(.horizontal, 20)
                        .padding(.top, 20)
                    VStack(spacing: 16) {
                        // Admin: Flagged questions
                        if profile?.isAdmin == true {
                            NavigationLink {
                                FlaggedQuestionsView()
                            } label: {
                                HStack {
                                    Image(systemName: "flag.fill")
                                    Text("FLAGGED QUESTIONS (ADMIN)")
                                        .retroText(style: RetroTheme.Typography.retroHeadline(size: 16), color: RetroTheme.Colors.neonYellow)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            .background(RoundedRectangle(cornerRadius: 16).fill(RetroTheme.Colors.darkBackground))
                            .overlay(RoundedRectangle(cornerRadius: 16).stroke(RetroTheme.Colors.neonYellow.opacity(0.5), lineWidth: 1))
                        }
                        // Language
                        VStack(alignment: .leading, spacing: 8) {
                            Text("LANGUAGE")
                                .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.retroGray)
                            Picker("", selection: $appLanguage) {
                                Text("English").tag("en")
                                Text("Español").tag("es")
                                Text("Português").tag("pt")
                            }
                            .pickerStyle(.menu)
                            .tint(RetroTheme.Colors.neonGreen)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(RoundedRectangle(cornerRadius: 16).fill(RetroTheme.Colors.darkBackground))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RetroTheme.Colors.retroGray.opacity(0.3), lineWidth: 1))

                        // Log out
                        Button(action: {
                            SoundManager.shared.playButtonClick()
                            authViewModel.signOut()
                        }) {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("LOG OUT")
                                    .retroText(style: RetroTheme.Typography.retroHeadline(size: 18), color: RetroTheme.Colors.retroRed)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                        }
                        .retroButton(color: RetroTheme.Colors.retroRed.opacity(0.8))
                    }
                    .padding(.horizontal, 20)
                }
                .padding(.bottom, 40)
            }
        }
        .task {
            guard !loadedProfile, let uid = authViewModel.currentUser?.id else { return }
            loadedProfile = true
            profile = try? await ProfileService.shared.getProfile(uid: uid)
        }
        .preferredColorScheme(.dark)
    }
}
