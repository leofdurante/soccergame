import SwiftUI

/// Screen for creating or joining a room
struct CreateJoinView: View {
    @StateObject private var roomViewModel: RoomViewModel
    @State private var roomCode = ""
    @State private var showingLobby = false
    let difficulty: Difficulty
    
    init(authViewModel: AuthViewModel, difficulty: Difficulty) {
        self.difficulty = difficulty
        let authService = authViewModel.authService
        let firestoreService = FirestoreService()
        _roomViewModel = StateObject(wrappedValue: RoomViewModel(
            firestoreService: firestoreService,
            authService: authService
        ))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Retro gradient background
                RetroTheme.retroGradient
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 30) {
                        // Retro header
                        VStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(RetroTheme.Colors.neonGreen.opacity(0.2))
                                    .frame(width: 80, height: 80)
                                    .shadow(color: RetroTheme.Colors.neonGreen.opacity(0.5), radius: 12, x: 0, y: 0)
                                
                                Image(systemName: "soccerball")
                                    .font(.system(size: 50))
                                    .foregroundColor(RetroTheme.Colors.neonGreen)
                                    .shadow(color: RetroTheme.Colors.neonGreen.opacity(0.8), radius: 6, x: 0, y: 0)
                            }
                            
                            Text("MULTIPLAYER")
                                .retroText(style: RetroTheme.Typography.retroTitle(size: 32), color: RetroTheme.Colors.neonGreen)
                                .padding(.horizontal, 20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(RetroTheme.Colors.neonGreen, lineWidth: 3)
                                        .shadow(color: RetroTheme.Colors.neonGreen.opacity(0.6), radius: 5, x: 0, y: 0)
                                )
                        }
                        .padding(.top, 20)
                        
                        VStack(spacing: 24) {
                            // Create Room Button
                            Button(action: {
                                SoundManager.shared.playButtonClick()
                                Task {
                                    await roomViewModel.createRoom(difficulty: difficulty.rawValue)
                                }
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .font(.title2)
                                    Text("CREATE ROOM")
                                        .retroText(style: RetroTheme.Typography.retroHeadline(size: 20), color: .white)
                                    Spacer()
                                    Image(systemName: "arrow.right")
                                        .font(.title3)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                            }
                            .retroButton(color: RetroTheme.Colors.neonGreen)
                            .disabled(roomViewModel.isLoading)
                            .opacity(roomViewModel.isLoading ? 0.5 : 1.0)
                            
                            // Retro Divider
                            HStack {
                                Rectangle()
                                    .frame(height: 2)
                                    .foregroundColor(RetroTheme.Colors.neonGreen.opacity(0.3))
                                Text("OR")
                                    .retroText(style: RetroTheme.Typography.retroCaption(), color: RetroTheme.Colors.retroGray)
                                    .padding(.horizontal, 16)
                                Rectangle()
                                    .frame(height: 2)
                                    .foregroundColor(RetroTheme.Colors.neonGreen.opacity(0.3))
                            }
                            .padding(.horizontal, 30)
                            
                            // Join Room Section
                            VStack(spacing: 16) {
                                Text("JOIN EXISTING ROOM")
                                    .retroText(style: RetroTheme.Typography.retroCaption(size: 14), color: RetroTheme.Colors.retroGray)
                                
                                TextField("ENTER ROOM CODE", text: $roomCode)
                                    .font(RetroTheme.Typography.retroHeadline(size: 20))
                                    .foregroundColor(RetroTheme.Colors.retroWhite)
                                    .multilineTextAlignment(.center)
                                    .textInputAutocapitalization(.characters)
                                    .keyboardType(.asciiCapable)
                                    .autocorrectionDisabled()
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(RetroTheme.Colors.darkBackground)
                                    )
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(RetroTheme.Colors.neonBlue, lineWidth: 3)
                                            .shadow(color: RetroTheme.Colors.neonBlue.opacity(0.6), radius: 5, x: 0, y: 0)
                                    )
                                    .padding(.horizontal, 30)
                                
                                Button(action: {
                                    SoundManager.shared.playButtonClick()
                                    Task {
                                        await roomViewModel.joinRoom(roomCode: roomCode.uppercased())
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "person.2.fill")
                                            .font(.title2)
                                        Text("JOIN ROOM")
                                            .retroText(style: RetroTheme.Typography.retroHeadline(size: 20), color: .white)
                                        Spacer()
                                        Image(systemName: "arrow.right")
                                            .font(.title3)
                                    }
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                }
                                .retroButton(color: RetroTheme.Colors.neonBlue)
                                .disabled(roomCode.isEmpty || roomViewModel.isLoading)
                                .opacity((roomCode.isEmpty || roomViewModel.isLoading) ? 0.5 : 1.0)
                            }
                        }
                        .padding(.horizontal, 30)
                        
                        if roomViewModel.isLoading {
                            VStack(spacing: 12) {
                                ProgressView()
                                    .tint(RetroTheme.Colors.neonGreen)
                                Text("LOADING...")
                                    .retroText(style: RetroTheme.Typography.retroCaption(), color: RetroTheme.Colors.retroGray)
                            }
                            .retroCard()
                            .padding(.horizontal, 40)
                            .padding(.top, 20)
                        }
                        
                        if let error = roomViewModel.errorMessage {
                            Text(error.uppercased())
                                .retroText(style: RetroTheme.Typography.retroBody(), color: RetroTheme.Colors.retroRed)
                                .multilineTextAlignment(.center)
                                .retroCard(backgroundColor: RetroTheme.Colors.darkerBackground)
                                .padding(.horizontal, 40)
                                .padding(.top, 20)
                        }
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationDestination(isPresented: $showingLobby) {
                if roomViewModel.room != nil {
                    LobbyView(roomViewModel: roomViewModel)
                }
            }
            .onChange(of: roomViewModel.room?.roomCode) { _, roomCode in
                guard roomCode != nil, !showingLobby else { return }
                showingLobby = true
            }
        }
    }
}

