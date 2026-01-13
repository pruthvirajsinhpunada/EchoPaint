//
//  ControlPanelView.swift
//  EchoPaint
//
//  Accessible control buttons for the canvas
//

import SwiftUI

/// Control panel with accessible buttons following Apple HIG
struct ControlPanelView: View {
    let onClear: () -> Void
    let onHelp: () -> Void
    let drawingCount: Int
    
    @Environment(\.accessibilityReduceMotion) var reduceMotion
    
    var body: some View {
        HStack(spacing: 20) {
            // Clear Button
            Button(action: onClear) {
                HStack(spacing: 8) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Clear")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.white)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.red.opacity(0.8))
                )
            }
            .accessibilityLabel("Clear Canvas")
            .accessibilityHint("Double tap to erase all drawings. You have \(drawingCount) strokes on the canvas.")
            .accessibilityAddTraits(.isButton)
            
            Spacer()
            
            // Stroke Count (for accessibility feedback)
            Text("\(drawingCount) strokes")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .accessibilityLabel("\(drawingCount) strokes drawn")
            
            Spacer()
            
            // Help Button
            Button(action: onHelp) {
                HStack(spacing: 8) {
                    Image(systemName: "questionmark.circle.fill")
                        .font(.system(size: 20, weight: .semibold))
                    Text("Help")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundColor(.black)
                .padding(.horizontal, 24)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.white)
                )
            }
            .accessibilityLabel("Help and Instructions")
            .accessibilityHint("Double tap to hear how to use EchoPaint")
            .accessibilityAddTraits(.isButton)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 16)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}

/// Tutorial overlay view
struct TutorialOverlayView: View {
    @Binding var isPresented: Bool
    
    var body: some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .onTapGesture {
                    isPresented = false
                }
            
            VStack(spacing: 32) {
                // Title
                VStack(spacing: 8) {
                    Image(systemName: "hand.draw.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.cyan)
                    
                    Text("Welcome to EchoPaint")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel("Welcome to EchoPaint")
                
                // Instructions
                VStack(alignment: .leading, spacing: 20) {
                    TutorialRow(
                        icon: "hand.point.up.fill",
                        color: .yellow,
                        title: "Touch to Draw",
                        description: "Drag your finger across the screen to create lines"
                    )
                    
                    TutorialRow(
                        icon: "arrow.up.arrow.down",
                        color: .green,
                        title: "Pitch = Height",
                        description: "Higher position creates higher pitch sounds"
                    )
                    
                    TutorialRow(
                        icon: "arrow.left.arrow.right",
                        color: .blue,
                        title: "Pan = Position",
                        description: "Left side plays in left ear, right in right ear"
                    )
                    
                    TutorialRow(
                        icon: "waveform.path",
                        color: .purple,
                        title: "Feel Your Art",
                        description: "You'll feel a bump when crossing lines you've drawn"
                    )
                    
                    TutorialRow(
                        icon: "circle.fill",
                        color: .orange,
                        title: "Smart Fill",
                        description: "Hear a chord when you close a shape like a circle"
                    )
                }
                .padding(.horizontal, 24)
                
                // Dismiss button
                Button(action: { isPresented = false }) {
                    Text("Start Drawing")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 18)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color.white)
                        )
                }
                .padding(.horizontal, 40)
                .accessibilityLabel("Start Drawing")
                .accessibilityHint("Double tap to close this tutorial and begin drawing")
            }
            .padding(.vertical, 40)
        }
    }
}

/// Single tutorial instruction row
struct TutorialRow: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundColor(color)
                .frame(width: 32)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.system(size: 15))
                    .foregroundColor(.white.opacity(0.7))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title). \(description)")
    }
}

#Preview {
    ControlPanelView(
        onClear: {},
        onHelp: {},
        drawingCount: 5
    )
    .background(Color.black)
}
