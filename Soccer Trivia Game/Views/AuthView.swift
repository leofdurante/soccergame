import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AuthView: View {
    @ObservedObject var authViewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var username = ""
    @State private var isSignUp = false
    @State private var copiedDetails = false
    
    private var emailValidation: String? {
        authViewModel.emailValidationMessage(email)
    }
    
    private var passwordValidation: String? {
        authViewModel.passwordValidationMessage(password)
    }
    
    private var usernameValidation: String? {
        isSignUp ? authViewModel.usernameValidationMessage(username) : nil
    }
    
    private var canSubmit: Bool {
        authViewModel.canSubmitAuth(email: email, password: password, username: username, isSignUp: isSignUp)
    }
    
    var body: some View {
        ZStack {
            RetroTheme.retroGradient
                .ignoresSafeArea()
            
            if let imagePath = Bundle.main.path(forResource: "main image", ofType: "jpg", inDirectory: "images"),
               let image = UIImage(contentsOfFile: imagePath) {
                GeometryReader { geometry in
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height)
                        .opacity(0.2)
                        .overlay(RetroTheme.retroGradient.opacity(0.8))
                }
                .ignoresSafeArea()
            }
            
            ScrollView {
                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(RetroTheme.Colors.neonGreen.opacity(0.2))
                            .frame(width: 120, height: 120)
                            .shadow(color: RetroTheme.Colors.neonGreen.opacity(0.5), radius: 20, x: 0, y: 0)
                        
                        if let logoPath = Bundle.main.path(forResource: "logo", ofType: "png", inDirectory: "images"),
                           let logoImage = UIImage(contentsOfFile: logoPath) {
                            Image(uiImage: logoImage)
                                .resizable()
                                .scaledToFit()
                                .frame(width: 90, height: 90)
                                .shadow(color: RetroTheme.Colors.neonGreen.opacity(0.8), radius: 10, x: 0, y: 0)
                        } else {
                            Image(systemName: "soccerball")
                                .font(.system(size: 80))
                                .foregroundColor(RetroTheme.Colors.neonGreen)
                                .shadow(color: RetroTheme.Colors.neonGreen.opacity(0.8), radius: 10, x: 0, y: 0)
                        }
                    }
                    
                    Text("SOCCER TRIVIA")
                        .retroText(style: RetroTheme.Typography.retroTitle(size: 42), color: RetroTheme.Colors.neonGreen)
                        .padding(.horizontal)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(RetroTheme.Colors.neonGreen, lineWidth: 3)
                                .shadow(color: RetroTheme.Colors.neonGreen.opacity(0.6), radius: 5, x: 0, y: 0)
                        )
                        .padding(.horizontal, 20)
                    
                    VStack(spacing: 16) {
                        Text(isSignUp ? "CREATE YOUR ACCOUNT" : "WELCOME BACK")
                            .retroText(style: RetroTheme.Typography.retroCaption(size: 16), color: RetroTheme.Colors.retroGray)
                        
                        if isSignUp {
                            TextField("USERNAME (UNIQUE)", text: $username)
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
                                        .shadow(color: RetroTheme.Colors.neonYellow.opacity(0.6), radius: 5, x: 0, y: 0)
                                )
                            if let usernameValidation {
                                Text(usernameValidation)
                                    .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.retroRed)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        
                        TextField("EMAIL", text: $email)
                            .textInputAutocapitalization(.never)
                            .keyboardType(.emailAddress)
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
                                    .stroke(RetroTheme.Colors.neonBlue, lineWidth: 3)
                                    .shadow(color: RetroTheme.Colors.neonBlue.opacity(0.6), radius: 5, x: 0, y: 0)
                            )
                        if let emailValidation {
                            Text(emailValidation)
                                .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.retroRed)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        SecureField("PASSWORD", text: $password)
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
                                    .stroke(RetroTheme.Colors.neonGreen, lineWidth: 3)
                                    .shadow(color: RetroTheme.Colors.neonGreen.opacity(0.6), radius: 5, x: 0, y: 0)
                            )
                        if let passwordValidation {
                            Text(passwordValidation)
                                .retroText(style: RetroTheme.Typography.retroCaption(size: 12), color: RetroTheme.Colors.retroRed)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        Button(action: submitEmailAuth) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.title2)
                                Text(isSignUp ? "SIGN UP" : "SIGN IN")
                                    .retroText(style: RetroTheme.Typography.retroHeadline(size: 20), color: .white)
                                Spacer()
                                Image(systemName: "arrow.right")
                                    .font(.title3)
                            }
                            .padding()
                            .frame(maxWidth: .infinity)
                        }
                        .retroButton(color: RetroTheme.Colors.neonBlue)
                        .disabled(authViewModel.isLoading || !canSubmit)
                        .opacity((authViewModel.isLoading || !canSubmit) ? 0.5 : 1.0)
                        
                        Button(action: toggleMode) {
                            Text(isSignUp ? "ALREADY HAVE AN ACCOUNT? SIGN IN" : "NEW HERE? CREATE ACCOUNT")
                                .retroText(style: RetroTheme.Typography.retroCaption(size: 14), color: RetroTheme.Colors.retroGray)
                        }
                        .padding(.top, 4)
                    }
                    .padding(.horizontal, 30)
                    
                    if authViewModel.isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                                .tint(RetroTheme.Colors.neonGreen)
                            Text("LOADING...")
                                .retroText(style: RetroTheme.Typography.retroCaption(), color: RetroTheme.Colors.retroGray)
                        }
                        .retroCard()
                        .padding(.horizontal, 40)
                    } else if let error = authViewModel.errorMessage {
                        VStack(spacing: 12) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .font(.title2)
                                .foregroundColor(RetroTheme.Colors.retroRed)
                            Text(error)
                                .retroText(style: RetroTheme.Typography.retroBody(size: 15), color: RetroTheme.Colors.retroRed)
                                .multilineTextAlignment(.center)
                            
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
                        .padding(20)
                        .frame(maxWidth: .infinity)
                        .background(RoundedRectangle(cornerRadius: 16).fill(RetroTheme.Colors.darkerBackground))
                        .overlay(RoundedRectangle(cornerRadius: 16).stroke(RetroTheme.Colors.retroRed.opacity(0.6), lineWidth: 2))
                        .padding(.horizontal, 40)
                    }
                }
                .padding(.vertical, 20)
            }
        }
        .onChange(of: email) { _, _ in copiedDetails = false }
        .onChange(of: password) { _, _ in copiedDetails = false }
        .onChange(of: username) { _, _ in copiedDetails = false }
    }
    
    private func submitEmailAuth() {
        SoundManager.shared.playButtonClick()
        Task {
            if isSignUp {
                await authViewModel.signUpWithEmail(email: email, password: password, username: username)
            } else {
                await authViewModel.signInWithEmail(email: email, password: password)
            }
        }
    }
    
    private func toggleMode() {
        SoundManager.shared.playButtonClick()
        isSignUp.toggle()
        copiedDetails = false
    }
    
    private func copyErrorDetails() {
        guard let details = authViewModel.errorDetails else { return }
        #if canImport(UIKit)
        UIPasteboard.general.string = details
        #endif
        copiedDetails = true
    }
}

