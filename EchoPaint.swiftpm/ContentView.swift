//
//  ContentView.swift
//  EchoPaint
//
//  Main view combining canvas and controls
//

import SwiftUI
import AVFoundation
import UIKit

/// Main content view for EchoPaint
struct ContentView: View {
    
    // MARK: - State
    
    @StateObject private var drawingStore = DrawingStore()
    @StateObject private var soundEngine = SoundEngine()
    @StateObject private var hapticEngine = HapticEngine()
    
    @State private var showTutorial = true
    @State private var showClearConfirmation = false
    
    // MARK: - Body
    
    var body: some View {
        ZStack {
            // Background
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                headerView
                
                // Canvas
                CanvasView(
                    drawingStore: drawingStore,
                    soundEngine: soundEngine,
                    hapticEngine: hapticEngine
                )
                .ignoresSafeArea(edges: .horizontal)
                
                // Control Panel
                ControlPanelView(
                    onClear: handleClear,
                    onHelp: handleHelp,
                    drawingCount: drawingStore.paths.count
                )
            }
            
            // Tutorial overlay
            if showTutorial {
                TutorialOverlayView(isPresented: $showTutorial)
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showTutorial)
        .alert("Clear Canvas?", isPresented: $showClearConfirmation) {
            Button("Cancel", role: .cancel) { }
            Button("Clear All", role: .destructive) {
                performClear()
            }
        } message: {
            Text("This will erase all your drawings. This cannot be undone.")
        }
        .onAppear {
            setupAudioSession()
        }
    }
    
    // MARK: - Header
    
    private var headerView: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("EchoPaint")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)
                
                Text("Draw with Sound & Touch")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("EchoPaint. Draw with Sound and Touch.")
            
            Spacer()
            
            // Haptic indicator
            if hapticEngine.isSupported {
                Image(systemName: "hand.tap.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.cyan)
                    .accessibilityLabel("Haptic feedback enabled")
            } else {
                Image(systemName: "hand.tap")
                    .font(.system(size: 18))
                    .foregroundColor(.gray)
                    .accessibilityLabel("Haptic feedback not available on this device")
            }
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .top)
        )
    }
    
    // MARK: - Actions
    
    private func handleClear() {
        if drawingStore.paths.isEmpty {
            // Nothing to clear
            announceForVoiceOver("Canvas is already empty")
        } else {
            showClearConfirmation = true
        }
    }
    
    private func performClear() {
        hapticEngine.playWarning()
        soundEngine.playClearSweep()
        drawingStore.clearAll()
        announceForVoiceOver("Canvas cleared")
    }
    
    private func handleHelp() {
        hapticEngine.playSuccess()
        showTutorial = true
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    /// Post accessibility announcement for VoiceOver users
    private func announceForVoiceOver(_ message: String) {
        if UIAccessibility.isVoiceOverRunning {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                UIAccessibility.post(notification: .announcement, argument: message)
            }
        }
    }
}

#Preview {
    ContentView()
}
