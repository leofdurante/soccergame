import SwiftUI

struct EditProfileView: View {
    @ObservedObject var authViewModel: AuthViewModel
    let profile: UserProfile
    @Environment(\.dismiss) private var dismiss
    @State private var displayName: String = ""
    @State private var homeCountry: String = ""
    @State private var profileImageURL: String = ""
    @State private var username: String = ""
    @State private var isSaving = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            RetroTheme.retroGradient
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 20) {
                    TextField("DISPLAY NAME", text: $displayName)
                        .textContentType(.name)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(RetroTheme.Colors.darkBackground))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(RetroTheme.Colors.neonBlue, lineWidth: 2))
                    TextField("USERNAME", text: $username)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(RetroTheme.Colors.darkBackground))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(RetroTheme.Colors.neonYellow, lineWidth: 2))
                    TextField("HOME COUNTRY", text: $homeCountry)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(RetroTheme.Colors.darkBackground))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(RetroTheme.Colors.retroGray, lineWidth: 2))
                    TextField("PROFILE IMAGE URL (OPTIONAL)", text: $profileImageURL)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(RetroTheme.Colors.darkBackground))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(RetroTheme.Colors.retroGray, lineWidth: 2))
                    if let err = errorMessage {
                        Text(err)
                            .retroText(style: RetroTheme.Typography.retroCaption(size: 13), color: RetroTheme.Colors.retroRed)
                            .multilineTextAlignment(.center)
                    }
                    Button(action: save) {
                        Text("SAVE")
                            .retroText(style: RetroTheme.Typography.retroHeadline(size: 18), color: .white)
                            .padding()
                            .frame(maxWidth: .infinity)
                    }
                    .retroButton(color: RetroTheme.Colors.neonGreen)
                    .disabled(isSaving)
                }
                .padding(20)
            }
        }
        .onAppear {
            displayName = profile.displayName
            homeCountry = profile.homeCountry ?? ""
            profileImageURL = profile.profileImageURL ?? ""
            username = profile.username
        }
        .preferredColorScheme(.dark)
    }

    private func save() {
        SoundManager.shared.playButtonClick()
        guard let uid = authViewModel.currentUser?.id else { return }
        errorMessage = nil
        isSaving = true
        Task {
            do {
                try await ProfileService.shared.updateProfile(
                    uid: uid,
                    displayName: displayName.isEmpty ? nil : displayName,
                    homeCountry: homeCountry.isEmpty ? nil : homeCountry,
                    profileImageURL: profileImageURL.isEmpty ? nil : profileImageURL,
                    username: username.isEmpty ? nil : username
                )
                await MainActor.run { dismiss() }
            } catch {
                errorMessage = error.localizedDescription
            }
            isSaving = false
        }
    }
}
