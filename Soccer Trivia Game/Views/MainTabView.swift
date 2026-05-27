import SwiftUI

enum AppTab: Int, CaseIterable {
    case home = 0
    case friends = 1
    case profile = 2
    case settings = 3

    var title: String {
        switch self {
        case .home: return "Home"
        case .friends: return "Friends"
        case .profile: return "Profile"
        case .settings: return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .friends: return "person.2.fill"
        case .profile: return "person.circle.fill"
        case .settings: return "gearshape.fill"
        }
    }
}

/// Root tab bar when authenticated: Home, Friends, Profile, Settings.
struct MainTabView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var selectedTab: AppTab = .home
    @StateObject private var inviteRoomViewModel: RoomViewModel
    @State private var showingInviteInbox = false
    @State private var showingInviteLobby = false

    init(authViewModel: AuthViewModel) {
        self.authViewModel = authViewModel
        _inviteRoomViewModel = StateObject(wrappedValue: RoomViewModel(
            firestoreService: FirestoreService(),
            authService: authViewModel.authService
        ))
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeTabContent(authViewModel: authViewModel)
            }
            .tag(AppTab.home.rawValue)
            .tabItem {
                Label(AppTab.home.title, systemImage: AppTab.home.icon)
            }

            NavigationStack {
                FriendsView(authViewModel: authViewModel)
            }
            .tag(AppTab.friends.rawValue)
            .tabItem {
                Label(AppTab.friends.title, systemImage: AppTab.friends.icon)
            }

            NavigationStack {
                ProfileView(authViewModel: authViewModel)
            }
            .tag(AppTab.profile.rawValue)
            .tabItem {
                Label(AppTab.profile.title, systemImage: AppTab.profile.icon)
            }

            NavigationStack {
                SettingsView(authViewModel: authViewModel)
            }
            .tag(AppTab.settings.rawValue)
            .tabItem {
                Label(AppTab.settings.title, systemImage: AppTab.settings.icon)
            }
        }
        .tint(RetroTheme.Colors.neonGreen)
        .onAppear {
            Task { await authViewModel.checkProfileExists() }
            inviteRoomViewModel.observeIncomingGameInvites()
        }
        .overlay(alignment: .topTrailing) {
            Button(action: {
                SoundManager.shared.playButtonClick()
                showingInviteInbox = true
            }) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .foregroundColor(RetroTheme.Colors.neonYellow)
                        .padding(10)
                        .background(Circle().fill(RetroTheme.Colors.darkBackground.opacity(0.9)))
                    if !inviteRoomViewModel.incomingGameInvites.isEmpty {
                        Text("\(inviteRoomViewModel.incomingGameInvites.count)")
                            .font(.caption2.bold())
                            .foregroundColor(.white)
                            .padding(4)
                            .background(Circle().fill(RetroTheme.Colors.retroRed))
                            .offset(x: 8, y: -8)
                    }
                }
            }
            .padding(.trailing, 18)
            .padding(.top, 8)
        }
        .sheet(isPresented: $showingInviteInbox) {
            NavigationStack {
                ZStack {
                    RetroTheme.retroGradient.ignoresSafeArea()
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            if inviteRoomViewModel.incomingGameInvites.isEmpty {
                                Text("No pending invites.")
                                    .retroText(style: RetroTheme.Typography.retroBody(size: 15), color: RetroTheme.Colors.retroGray)
                                    .padding(.horizontal, 20)
                                    .padding(.top, 30)
                            } else {
                                ForEach(inviteRoomViewModel.incomingGameInvites) { invite in
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Room \(invite.roomCode)")
                                            .retroText(style: RetroTheme.Typography.retroHeadline(size: 16), color: RetroTheme.Colors.retroWhite)
                                        Text("Host: \(invite.fromUid)")
                                            .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.retroGray)
                                        Text("Expires: \(invite.expiresAt.formatted(date: .omitted, time: .shortened))")
                                            .retroText(style: RetroTheme.Typography.retroCaption(size: 11), color: RetroTheme.Colors.retroGray)

                                        HStack {
                                            Button("Decline") {
                                                Task { await inviteRoomViewModel.declineGameInvite(invite) }
                                            }
                                            .font(RetroTheme.Typography.retroCaption(size: 13))
                                            .foregroundColor(RetroTheme.Colors.retroRed)

                                            Spacer()

                                            Button("Join") {
                                                Task {
                                                    await inviteRoomViewModel.acceptGameInvite(invite)
                                                    if inviteRoomViewModel.room != nil {
                                                        showingInviteInbox = false
                                                        showingInviteLobby = true
                                                    }
                                                }
                                            }
                                            .font(RetroTheme.Typography.retroCaption(size: 13))
                                            .foregroundColor(RetroTheme.Colors.neonGreen)
                                        }
                                    }
                                    .padding()
                                    .background(RoundedRectangle(cornerRadius: 14).fill(RetroTheme.Colors.darkBackground))
                                    .overlay(RoundedRectangle(cornerRadius: 14).stroke(RetroTheme.Colors.neonBlue.opacity(0.35), lineWidth: 1))
                                    .padding(.horizontal, 20)
                                }
                                .padding(.top, 10)
                            }
                        }
                        .padding(.bottom, 20)
                    }
                }
                .navigationTitle("Invites")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Close") { showingInviteInbox = false }
                    }
                }
            }
            .preferredColorScheme(.dark)
        }
        .fullScreenCover(isPresented: $showingInviteLobby) {
            NavigationStack {
                LobbyView(roomViewModel: inviteRoomViewModel)
            }
            .preferredColorScheme(.dark)
        }
        .fullScreenCover(isPresented: Binding(get: { authViewModel.needsUsernameSetup }, set: { _ in })) {
            UsernameSetupView(authViewModel: authViewModel)
        }
        .preferredColorScheme(.dark)
    }
}
