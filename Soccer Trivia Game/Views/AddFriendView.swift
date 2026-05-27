import SwiftUI

struct AddFriendView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @Environment(\.dismiss) private var dismiss
    @State private var searchText = ""
    @State private var searchBy: SearchBy = .username
    @State private var results: [UserProfile] = []
    @State private var isSearching = false
    @State private var errorMessage: String?

    enum SearchBy: String, CaseIterable {
        case username = "Username"
        case email = "Email"
    }

    var body: some View {
        ZStack {
            RetroTheme.retroGradient
                .ignoresSafeArea()
            VStack(spacing: 20) {
                Text("ADD FRIEND")
                    .retroText(style: RetroTheme.Typography.retroTitle(size: 24), color: RetroTheme.Colors.neonGreen)
                    .padding(.top, 20)
                Picker("Search by", selection: $searchBy) {
                    ForEach(SearchBy.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                HStack {
                    TextField(searchBy == .username ? "Enter username" : "Enter email", text: $searchText)
                        .textInputAutocapitalization(.never)
                        .keyboardType(searchBy == .email ? .emailAddress : .default)
                        .autocorrectionDisabled()
                        .padding()
                        .background(RoundedRectangle(cornerRadius: 12).fill(RetroTheme.Colors.darkBackground))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(RetroTheme.Colors.neonBlue, lineWidth: 2))
                    Button(action: search) {
                        Image(systemName: "magnifyingglass")
                            .font(.title2)
                            .foregroundColor(RetroTheme.Colors.neonGreen)
                    }
                }
                .padding(.horizontal, 20)
                if let err = errorMessage {
                    Text(err)
                        .retroText(style: RetroTheme.Typography.retroCaption(size: 13), color: RetroTheme.Colors.retroRed)
                        .padding(.horizontal, 20)
                }
                if isSearching {
                    ProgressView()
                        .tint(RetroTheme.Colors.neonGreen)
                }
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(results) { profile in
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(profile.displayName)
                                        .retroText(style: RetroTheme.Typography.retroHeadline(size: 16), color: RetroTheme.Colors.retroWhite)
                                    Text(profile.username)
                                        .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.retroGray)
                                }
                                Spacer()
                                Button("Request") {
                                    sendFriendRequest(profile)
                                }
                                .font(RetroTheme.Typography.retroCaption(size: 14))
                                .foregroundColor(RetroTheme.Colors.neonGreen)
                            }
                            .padding()
                            .background(RoundedRectangle(cornerRadius: 12).fill(RetroTheme.Colors.darkBackground))
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(RetroTheme.Colors.retroGray.opacity(0.3), lineWidth: 1))
                        }
                    }
                    .padding(.horizontal, 20)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    private func search() {
        SoundManager.shared.playButtonClick()
        errorMessage = nil
        results = []
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            errorMessage = "Enter a username or email."
            return
        }
        if searchBy == .email && !query.contains("@") {
            errorMessage = "Enter a valid email."
            return
        }
        isSearching = true
        Task {
            do {
                guard let uid = authViewModel.currentUser?.id else { return }
                let profile = try await ProfileService.shared.getProfile(uid: uid)
                let friendIds = profile?.friendIds ?? []
                if searchBy == .username {
                    results = try await ProfileService.shared.searchByUsername(query: query, currentUid: uid, friendIds: friendIds)
                } else {
                    results = try await ProfileService.shared.searchByEmail(email: query, currentUid: uid, friendIds: friendIds)
                }
                if results.isEmpty {
                    errorMessage = "No users found."
                }
            } catch {
                errorMessage = error.localizedDescription
            }
            isSearching = false
        }
    }

    private func sendFriendRequest(_ profile: UserProfile) {
        SoundManager.shared.playButtonClick()
        guard let uid = authViewModel.currentUser?.id else { return }
        Task {
            do {
                try await ProfileService.shared.sendFriendRequest(fromUid: uid, toUid: profile.uid)
                results.removeAll { $0.uid == profile.uid }
                errorMessage = "Request sent to @\(profile.username)."
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}
