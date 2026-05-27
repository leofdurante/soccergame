import SwiftUI

/// Read-only profile view for a friend.
struct FriendProfileView: View {
    let profile: UserProfile

    var body: some View {
        ZStack {
            RetroTheme.retroGradient
                .ignoresSafeArea()
            ScrollView {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(RetroTheme.Colors.neonBlue.opacity(0.2))
                            .frame(width: 100, height: 100)
                        if let urlString = profile.profileImageURL, let url = URL(string: urlString) {
                            AsyncImage(url: url) { image in image.resizable().scaledToFill() } placeholder: { initialsView }
                                .frame(width: 100, height: 100)
                                .clipShape(Circle())
                        } else {
                            initialsView
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
                    HStack(spacing: 20) {
                        VStack(spacing: 4) {
                            Text("GAMES")
                                .retroText(style: RetroTheme.Typography.retroCaption(size: 11), color: RetroTheme.Colors.retroGray)
                            Text("\(profile.gamesPlayedFanaticos)")
                                .retroText(style: RetroTheme.Typography.retroHeadline(size: 22), color: RetroTheme.Colors.neonGreen)
                        }
                        .frame(maxWidth: .infinity)
                        VStack(spacing: 4) {
                            Text("BEST")
                                .retroText(style: RetroTheme.Typography.retroCaption(size: 11), color: RetroTheme.Colors.retroGray)
                            Text("\(profile.bestScore)")
                                .retroText(style: RetroTheme.Typography.retroHeadline(size: 22), color: RetroTheme.Colors.neonGreen)
                        }
                        .frame(maxWidth: .infinity)
                        VStack(spacing: 4) {
                            Text("STREAK")
                                .retroText(style: RetroTheme.Typography.retroCaption(size: 11), color: RetroTheme.Colors.retroGray)
                            Text("\(profile.winStreak)")
                                .retroText(style: RetroTheme.Typography.retroHeadline(size: 22), color: RetroTheme.Colors.neonGreen)
                        }
                        .frame(maxWidth: .infinity)
                    }
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(RetroTheme.Colors.darkBackground))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(RetroTheme.Colors.neonGreen.opacity(0.5), lineWidth: 2))
                    .padding(.horizontal, 20)
                }
                .padding(.vertical, 24)
            }
        }
        .navigationTitle(profile.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.dark)
    }

    private var initialsView: some View {
        let initials = profile.displayName.split(separator: " ").prefix(2).compactMap { $0.first }.map(String.init).joined().uppercased()
        return Text(initials.isEmpty ? "?" : String(initials.prefix(2)))
            .font(RetroTheme.Typography.retroTitle(size: 36))
            .foregroundColor(RetroTheme.Colors.neonBlue)
    }
}
