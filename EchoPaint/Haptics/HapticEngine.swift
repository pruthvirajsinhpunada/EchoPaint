//
//  HapticEngine.swift
//  EchoPaint
//
//  CoreHaptics-based tactile feedback
//

import CoreHaptics
import UIKit

/// Haptic engine for providing tactile feedback during drawing
class HapticEngine: ObservableObject {
    
    // MARK: - Properties
    
    private var engine: CHHapticEngine?
    private var continuousPlayer: CHHapticAdvancedPatternPlayer?
    private var bumpPlayer: CHHapticAdvancedPatternPlayer?
    
    @Published var isSupported: Bool = false
    @Published var isRunning: Bool = false
    
    private var lastBumpTime: Date = .distantPast
    private let bumpCooldown: TimeInterval = 0.1 // Minimum time between bumps
    
    // MARK: - Initialization
    
    init() {
        checkSupport()
        setupEngine()
    }
    
    deinit {
        stopEngine()
    }
    
    // MARK: - Setup
    
    private func checkSupport() {
        isSupported = CHHapticEngine.capabilitiesForHardware().supportsHaptics
    }
    
    private func setupEngine() {
        guard isSupported else {
            print("Haptics not supported on this device")
            return
        }
        
        do {
            engine = try CHHapticEngine()
            engine?.playsHapticsOnly = true
            
            // Handle engine reset
            engine?.resetHandler = { [weak self] in
                do {
                    try self?.engine?.start()
                    self?.createPlayers()
                } catch {
                    print("Failed to restart haptic engine: \(error)")
                }
            }
            
            // Handle engine stopped
            engine?.stoppedHandler = { [weak self] reason in
                print("Haptic engine stopped: \(reason.rawValue)")
                self?.isRunning = false
            }
            
            try engine?.start()
            isRunning = true
            createPlayers()
            
        } catch {
            print("Failed to create haptic engine: \(error)")
        }
    }
    
    private func createPlayers() {
        createContinuousPlayer()
        createBumpPlayer()
    }
    
    /// Create player for continuous gentle vibration while drawing
    private func createContinuousPlayer() {
        guard let engine = engine else { return }
        
        do {
            // Gentle continuous haptic
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.3)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.2)
            
            let event = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [intensity, sharpness],
                relativeTime: 0,
                duration: 100 // Long duration, we'll stop it manually
            )
            
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            continuousPlayer = try engine.makeAdvancedPlayer(with: pattern)
            
        } catch {
            print("Failed to create continuous haptic player: \(error)")
        }
    }
    
    /// Create player for "bump" when crossing existing line
    private func createBumpPlayer() {
        guard let engine = engine else { return }
        
        do {
            // Sharp bump haptic
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 1.0)
            
            let event = CHHapticEvent(
                eventType: .hapticTransient,
                parameters: [intensity, sharpness],
                relativeTime: 0
            )
            
            let pattern = try CHHapticPattern(events: [event], parameters: [])
            bumpPlayer = try engine.makeAdvancedPlayer(with: pattern)
            
        } catch {
            print("Failed to create bump haptic player: \(error)")
        }
    }
    
    // MARK: - Control
    
    func startEngine() {
        guard isSupported, let engine = engine else { return }
        
        do {
            try engine.start()
            isRunning = true
            createPlayers()
        } catch {
            print("Failed to start haptic engine: \(error)")
        }
    }
    
    func stopEngine() {
        engine?.stop()
        isRunning = false
    }
    
    // MARK: - Haptic Feedback
    
    /// Start continuous gentle haptic for drawing
    func beginDrawingHaptic() {
        guard isSupported, isRunning else { return }
        
        do {
            try continuousPlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to start drawing haptic: \(error)")
        }
    }
    
    /// Stop continuous haptic
    func endDrawingHaptic() {
        guard isSupported else { return }
        
        do {
            try continuousPlayer?.stop(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to stop drawing haptic: \(error)")
        }
    }
    
    /// Play bump haptic when crossing existing line
    func playBump() {
        guard isSupported, isRunning else { return }
        
        // Prevent too frequent bumps
        let now = Date()
        guard now.timeIntervalSince(lastBumpTime) >= bumpCooldown else { return }
        lastBumpTime = now
        
        do {
            try bumpPlayer?.start(atTime: CHHapticTimeImmediate)
        } catch {
            print("Failed to play bump haptic: \(error)")
        }
    }
    
    /// Play success haptic for button taps
    func playSuccess() {
        guard isSupported, let engine = engine else { return }
        
        do {
            let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.8)
            let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.5)
            
            let event1 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0)
            let event2 = CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: 0.1)
            
            let pattern = try CHHapticPattern(events: [event1, event2], parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            
        } catch {
            print("Failed to play success haptic: \(error)")
        }
    }
    
    /// Play warning haptic for clear action
    func playWarning() {
        guard isSupported, let engine = engine else { return }
        
        do {
            let events: [CHHapticEvent] = (0..<3).map { i in
                let intensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 0.7)
                let sharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.8)
                return CHHapticEvent(eventType: .hapticTransient, parameters: [intensity, sharpness], relativeTime: Double(i) * 0.08)
            }
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            
        } catch {
            print("Failed to play warning haptic: \(error)")
        }
    }
    
    /// Play celebratory haptic when shape is closed - the "wow" feature
    /// Rising "bloom" pattern that feels like completion/success
    func playShapeClosed() {
        guard isSupported, let engine = engine else { return }
        
        do {
            // Create a "blooming" pattern - rising intensity with a final pop
            var events: [CHHapticEvent] = []
            
            // Rising sequence (4 gentle taps with increasing intensity)
            for i in 0..<4 {
                let intensity = CHHapticEventParameter(
                    parameterID: .hapticIntensity,
                    value: Float(i + 1) * 0.2 // 0.2, 0.4, 0.6, 0.8
                )
                let sharpness = CHHapticEventParameter(
                    parameterID: .hapticSharpness,
                    value: Float(i) * 0.15 + 0.3 // Gradually sharper
                )
                let event = CHHapticEvent(
                    eventType: .hapticTransient,
                    parameters: [intensity, sharpness],
                    relativeTime: Double(i) * 0.06
                )
                events.append(event)
            }
            
            // Final "bloom" - strong, soft haptic that feels expansive
            let finalIntensity = CHHapticEventParameter(parameterID: .hapticIntensity, value: 1.0)
            let finalSharpness = CHHapticEventParameter(parameterID: .hapticSharpness, value: 0.3)
            let bloomEvent = CHHapticEvent(
                eventType: .hapticContinuous,
                parameters: [finalIntensity, finalSharpness],
                relativeTime: 0.3,
                duration: 0.2
            )
            events.append(bloomEvent)
            
            let pattern = try CHHapticPattern(events: events, parameters: [])
            let player = try engine.makePlayer(with: pattern)
            try player.start(atTime: CHHapticTimeImmediate)
            
        } catch {
            print("Failed to play shape closed haptic: \(error)")
        }
    }
}
