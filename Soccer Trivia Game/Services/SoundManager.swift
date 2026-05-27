import Foundation
import AVFoundation

/// Manages sound effects for the game
@MainActor
class SoundManager {
    static let shared = SoundManager()
    
    private var audioPlayers: [String: AVAudioPlayer] = [:]
    
    private init() {
        setupAudioSession()
    }
    
    /// Setup audio session for sound effects
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    /// Play a sound effect
    func playSound(_ soundName: String, volume: Float = 0.5, trimDuration: TimeInterval? = nil) {
        // Try multiple locations for the sound file
        var url: URL?
        
        // Try main bundle first (Resources folder)
        if let bundleURL = Bundle.main.url(forResource: soundName, withExtension: nil) {
            url = bundleURL
        }
        // Try in Resources subdirectory
        else if let bundleURL = Bundle.main.url(forResource: soundName, withExtension: nil, subdirectory: "Resources") {
            url = bundleURL
        }
        // Try without extension
        else if let bundleURL = Bundle.main.url(forResource: soundName.replacingOccurrences(of: ".mp3", with: ""), withExtension: "mp3") {
            url = bundleURL
        }
        // Try without extension in Resources
        else if let bundleURL = Bundle.main.url(forResource: soundName.replacingOccurrences(of: ".mp3", with: ""), withExtension: "mp3", subdirectory: "Resources") {
            url = bundleURL
        }
        
        guard let soundURL = url else {
            print("⚠️ Sound file not found: \(soundName)")
            return
        }
        
        // Check if player already exists
        if let player = audioPlayers[soundName] {
            player.currentTime = 0
            player.volume = volume
            if let duration = trimDuration {
                // Create a timer to stop after duration
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                    if player.isPlaying {
                        player.stop()
                    }
                }
            }
            player.play()
            return
        }
        
        // Load and play new sound
        playSoundFromURL(soundURL, soundName: soundName, volume: volume, trimDuration: trimDuration)
    }
    
    private func playSoundFromURL(_ url: URL, soundName: String, volume: Float, trimDuration: TimeInterval?) {
        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = volume
            player.prepareToPlay()
            audioPlayers[soundName] = player
            
            if let duration = trimDuration {
                // Stop after specified duration
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
                    if player.isPlaying {
                        player.stop()
                    }
                }
            }
            
            player.play()
        } catch {
            print("❌ Failed to play sound \(soundName): \(error)")
        }
    }
    
    /// Play button click sound (soccer ball kick) - trimmed to 0.3 seconds
    func playButtonClick() {
        playSound("soccer-ball-kick-37625.mp3", volume: 0.3, trimDuration: 0.3)
    }
    
    /// Play game start sound (whistle) - trimmed to 1 second
    func playGameStart() {
        playSound("metal-whistle-6121.mp3", volume: 0.5, trimDuration: 1.0)
    }
    
    /// Stop all sounds
    func stopAllSounds() {
        audioPlayers.values.forEach { $0.stop() }
    }
}

