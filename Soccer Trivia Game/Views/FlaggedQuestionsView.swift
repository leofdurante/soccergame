import SwiftUI
import Combine

/// Admin-only view listing all flagged questions for review.
struct FlaggedQuestionsView: View {
    @StateObject private var viewModel = FlaggedQuestionsViewModel()
    
    var body: some View {
        ZStack {
            RetroTheme.retroGradient
                .ignoresSafeArea()
            Group {
                if viewModel.isLoading && viewModel.flagged.isEmpty {
                    ProgressView()
                        .tint(RetroTheme.Colors.neonGreen)
                } else if viewModel.flagged.isEmpty {
                    Text("No flagged questions.")
                        .retroText(style: RetroTheme.Typography.retroBody(), color: RetroTheme.Colors.retroGray)
                } else {
                    List {
                        ForEach(viewModel.flagged) { flag in
                            VStack(alignment: .leading, spacing: 8) {
                                Text(flag.questionText)
                                    .retroText(style: RetroTheme.Typography.retroHeadline(size: 14), color: RetroTheme.Colors.retroWhite)
                                Text("Mode: \(flag.mode) · Type: \(flag.questionType)")
                                    .retroText(style: RetroTheme.Typography.retroCaption(size: 11), color: RetroTheme.Colors.retroGray)
                                Text("Correct: \(flag.options[safe: flag.correctAnswerIndex] ?? "?")")
                                    .retroText(style: RetroTheme.Typography.retroCaption(size: 11), color: RetroTheme.Colors.neonGreen)
                                Text("Flagged by: \(flag.userDisplayName)")
                                    .retroText(style: RetroTheme.Typography.retroCaption(size: 11), color: RetroTheme.Colors.retroGray)
                                if let reason = flag.reason, !reason.isEmpty {
                                    Text("Reason: \(reason)")
                                        .retroText(style: RetroTheme.Typography.retroCaption(size: 11), color: RetroTheme.Colors.retroGray)
                                }
                                Text(formatDate(flag.createdAt))
                                    .retroText(style: RetroTheme.Typography.retroCaption(size: 10), color: RetroTheme.Colors.retroGray)
                            }
                            .padding(.vertical, 8)
                            .listRowBackground(RetroTheme.Colors.darkBackground)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("Flagged questions")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
        .preferredColorScheme(.dark)
    }
    
    private func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateStyle = .short
        f.timeStyle = .short
        return f.string(from: date)
    }
}

@MainActor
class FlaggedQuestionsViewModel: ObservableObject {
    @Published var flagged: [FlaggedQuestion] = []
    @Published var isLoading = false
    
    func load() async {
        isLoading = true
        do {
            flagged = try await FlagService.shared.listFlaggedQuestions()
        } catch {
            flagged = []
        }
        isLoading = false
    }
}

private extension Array {
    subscript(safe index: Int) -> Element? {
        indices.contains(index) ? self[index] : nil
    }
}
