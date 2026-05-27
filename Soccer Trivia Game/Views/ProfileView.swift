import SwiftUI
import Combine

struct ProfileView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: ProfileViewModel

    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        _viewModel = StateObject(wrappedValue: ProfileViewModel(authViewModel: authViewModel))
    }

    var body: some View {
        ZStack {
            RetroTheme.retroGradient
                .ignoresSafeArea()
            if viewModel.isLoading && viewModel.profile == nil {
                ProgressView()
                    .tint(RetroTheme.Colors.neonGreen)
            } else if let profile = viewModel.profile {
                ScrollView {
                    VStack(spacing: 24) {
                        // Avatar / initials
                        ZStack {
                            Circle()
                                .fill(RetroTheme.Colors.neonGreen.opacity(0.2))
                                .frame(width: 100, height: 100)
                            if let urlString = profile.profileImageURL, let url = URL(string: urlString) {
                                AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { initialsView(profile) }
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                initialsView(profile)
                            }
                        }
                        Text(profile.displayName.uppercased())
                            .retroText(style: RetroTheme.Typography.retroHeadline(size: 22), color: RetroTheme.Colors.retroWhite)
                        Text("@\(profile.username)")
                            .retroText(style: RetroTheme.Typography.retroCaption(size: 14), color: RetroTheme.Colors.retroGray)
                        if let country = profile.homeCountry, !country.isEmpty {
                            Text(country.uppercased())
                                .retroText(style: RetroTheme.Typography.retroCaption(size: 14), color: RetroTheme.Colors.neonBlue)
                        }
                        // Stats
                        HStack(spacing: 20) {
                            statBlock(title: "GAMES", value: "\(profile.gamesPlayedFanaticos)")
                            statBlock(title: "BEST", value: "\(profile.bestScore)")
                            statBlock(title: "STREAK", value: "\(profile.winStreak)")
                        }
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 16).fill(RetroTheme.Colors.darkBackground))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RetroTheme.Colors.neonGreen.opacity(0.5), lineWidth: 2))
                        .padding(.horizontal, 20)
                        NavigationLink {
                            EditProfileView(authViewModel: authViewModel, profile: profile)
                        } label: {
                            HStack {
                                Text("EDIT PROFILE")
                                    .retroText(style: RetroTheme.Typography.retroHeadline(size: 18), color: .white)
                                Image(systemName: "chevron.right")
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                        }
                        .retroButton(color: RetroTheme.Colors.neonBlue)
                        .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 24)
                }
            } else {
                VStack(spacing: 16) {
                    Text("No profile found.")
                        .retroText(style: RetroTheme.Typography.retroBody(), color: RetroTheme.Colors.retroGray)
                }
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadProfile() }
        .preferredColorScheme(.dark)
    }

    private func initialsView(_ profile: UserProfile) -> some View {
        let initials = profile.displayName.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined().uppercased()
        return Text(initials.isEmpty ? "?" : String(initials.prefix(2)))
            .font(RetroTheme.Typography.retroTitle(size: 36))
            .foregroundColor(RetroTheme.Colors.neonGreen)
    }

    private func statBlock(title: String, value: String) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .retroText(style: RetroTheme.Typography.retroCaption(size: 11), color: RetroTheme.Colors.retroGray)
            Text(value)
                .retroText(style: RetroTheme.Typography.retroHeadline(size: 24), color: RetroTheme.Colors.neonGreen)
        }
        .frame(maxWidth: .infinity)
    }
}

@MainActor
class ProfileViewModel: ObservableObject {
    @Published var profile: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    private let authViewModel: AuthViewModel
    private let profileService = ProfileService.shared

    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }

    func loadProfile() async {
        guard let uid = authViewModel.currentUser?.id else { return }
        isLoading = true
        do {
            profile = try await profileService.getProfile(uid: uid)
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
