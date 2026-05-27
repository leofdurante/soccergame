import SwiftUI
import Combine
import FirebaseFirestore

struct FriendsView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @StateObject private var viewModel: FriendsViewModel

    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        _viewModel = StateObject(wrappedValue: FriendsViewModel(authViewModel: authViewModel))
    }

    var body: some View {
        ZStack {
            RetroTheme.retroGradient
                .ignoresSafeArea()
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack {
                        Text("FRIENDS")
                            .retroText(style: RetroTheme.Typography.retroTitle(size: 28), color: RetroTheme.Colors.neonGreen)
                        Spacer()
                        NavigationLink {
                            AddFriendView(authViewModel: authViewModel)
                        } label: {
                            Image(systemName: "person.badge.plus")
                                .font(.title2)
                                .foregroundColor(RetroTheme.Colors.neonGreen)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    if !viewModel.incomingRequests.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("FRIEND REQUESTS")
                                .retroText(style: RetroTheme.Typography.retroCaption(size: 13), color: RetroTheme.Colors.neonYellow)
                                .padding(.horizontal, 20)
                            
                            ForEach(viewModel.incomingRequests) { request in
                                HStack(spacing: 12) {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(viewModel.requestSenderName(for: request.fromUid))
                                            .retroText(style: RetroTheme.Typography.retroHeadline(size: 15), color: RetroTheme.Colors.retroWhite)
                                        Text("@\(viewModel.requestSenderUsername(for: request.fromUid))")
                                            .retroText(style: RetroTheme.Typography.retroCaption(size: 11), color: RetroTheme.Colors.retroGray)
                                    }
                                    Spacer()
                                    Button("Decline") {
                                        Task { await viewModel.declineRequest(request) }
                                    }
                                    .font(RetroTheme.Typography.retroCaption(size: 12))
                                    .foregroundColor(RetroTheme.Colors.retroRed)
                                    
                                    Button("Accept") {
                                        Task { await viewModel.acceptRequest(request) }
                                    }
                                    .font(RetroTheme.Typography.retroCaption(size: 12))
                                    .foregroundColor(RetroTheme.Colors.neonGreen)
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 12).fill(RetroTheme.Colors.darkBackground))
                                .overlay(RoundedRectangle(cornerRadius: 12).stroke(RetroTheme.Colors.neonYellow.opacity(0.4), lineWidth: 1))
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    
                    if viewModel.friends.isEmpty && !viewModel.isLoading {
                        Text("No friends yet. Tap + to search by username or email.")
                            .retroText(style: RetroTheme.Typography.retroBody(size: 16), color: RetroTheme.Colors.retroGray)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                    } else {
                        ForEach(viewModel.friends) { profile in
                            NavigationLink {
                                FriendProfileView(profile: profile)
                            } label: {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(RetroTheme.Colors.neonBlue.opacity(0.3))
                                            .frame(width: 50, height: 50)
                                        Text(initials(for: profile))
                                            .font(RetroTheme.Typography.retroHeadline(size: 18))
                                            .foregroundColor(RetroTheme.Colors.neonBlue)
                                    }
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(profile.displayName)
                                            .retroText(style: RetroTheme.Typography.retroHeadline(size: 18), color: RetroTheme.Colors.retroWhite)
                                        Text("@\(profile.username)")
                                            .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.retroGray)
                                        if let ts = viewModel.lastPlayedWith[profile.uid] {
                                            Text("Last played: \(formatDate(ts))")
                                                .retroText(style: RetroTheme.Typography.retroCaption(size: 11), color: RetroTheme.Colors.retroGray)
                                        }
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundColor(RetroTheme.Colors.retroGray)
                                }
                                .padding()
                                .background(RoundedRectangle(cornerRadius: 16).fill(RetroTheme.Colors.darkBackground))
                                .overlay(RoundedRectangle(cornerRadius: 16).stroke(RetroTheme.Colors.retroGray.opacity(0.3), lineWidth: 1))
                            }
                            .padding(.horizontal, 20)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
        }
        .navigationTitle("Friends")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.loadFriends() }
        .refreshable { await viewModel.loadFriends() }
        .preferredColorScheme(.dark)
    }

    private func initials(for profile: UserProfile) -> String {
        profile.displayName.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined().uppercased()
    }

    private func formatDate(_ seconds: Double) -> String {
        let d = Date(timeIntervalSince1970: seconds)
        let f = DateFormatter()
        f.dateStyle = .short
        return f.string(from: d)
    }
}

@MainActor
class FriendsViewModel: ObservableObject {
    @Published var friends: [UserProfile] = []
    @Published var incomingRequests: [FriendRequest] = []
    @Published var lastPlayedWith: [String: Double] = [:]
    @Published var isLoading = false
    @Published var senderProfilesByUid: [String: UserProfile] = [:]
    private let authViewModel: AuthViewModel
    private let profileService = ProfileService.shared
    private var requestListener: ListenerRegistration?

    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
    }
    
    deinit {
        requestListener?.remove()
    }

    func loadFriends() async {
        guard let uid = authViewModel.currentUser?.id else { return }
        isLoading = true
        do {
            let profile = try await profileService.getProfile(uid: uid)
            guard let p = profile, !p.friendIds.isEmpty else {
                friends = []
                lastPlayedWith = [:]
                isLoading = false
                return
            }
            let list = try await profileService.getProfiles(uids: p.friendIds)
            friends = list
            lastPlayedWith = p.lastPlayedWith
        } catch {
            friends = []
        }
        isLoading = false
        startIncomingRequestsListener()
    }
    
    private func startIncomingRequestsListener() {
        guard let uid = authViewModel.currentUser?.id else { return }
        requestListener?.remove()
        requestListener = profileService.observeIncomingFriendRequests(for: uid) { [weak self] result in
            Task { @MainActor in
                guard let self else { return }
                switch result {
                case .success(let requests):
                    self.incomingRequests = requests
                    await self.loadRequestSenderProfiles()
                case .failure:
                    self.incomingRequests = []
                    self.senderProfilesByUid = [:]
                }
            }
        }
    }
    
    private func loadRequestSenderProfiles() async {
        let uids = Array(Set(incomingRequests.map(\.fromUid)))
        guard !uids.isEmpty else {
            senderProfilesByUid = [:]
            return
        }
        let profiles = try? await profileService.getProfiles(uids: uids)
        var map: [String: UserProfile] = [:]
        profiles?.forEach { map[$0.uid] = $0 }
        senderProfilesByUid = map
    }
    
    func requestSenderName(for uid: String) -> String {
        senderProfilesByUid[uid]?.displayName ?? "Unknown user"
    }
    
    func requestSenderUsername(for uid: String) -> String {
        senderProfilesByUid[uid]?.username ?? uid
    }
    
    func acceptRequest(_ request: FriendRequest) async {
        guard let requestId = request.id, let uid = authViewModel.currentUser?.id else { return }
        do {
            try await profileService.acceptFriendRequest(requestId: requestId, currentUid: uid)
            await loadFriends()
        } catch { }
    }
    
    func declineRequest(_ request: FriendRequest) async {
        guard let requestId = request.id, let uid = authViewModel.currentUser?.id else { return }
        do {
            try await profileService.declineFriendRequest(requestId: requestId, currentUid: uid)
        } catch { }
    }
}
