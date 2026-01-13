//
//  CanvasView.swift
//  EchoPaint
//
//  UIKit-based drawing canvas wrapped for SwiftUI
//

import SwiftUI
import UIKit

/// SwiftUI wrapper for the drawing canvas
struct CanvasView: UIViewRepresentable {
    @ObservedObject var drawingStore: DrawingStore
    let soundEngine: SoundEngine
    let hapticEngine: HapticEngine
    
    func makeUIView(context: Context) -> DrawingCanvasUIView {
        let canvasView = DrawingCanvasUIView()
        canvasView.drawingStore = drawingStore
        canvasView.soundEngine = soundEngine
        canvasView.hapticEngine = hapticEngine
        canvasView.backgroundColor = .black
        
        // Accessibility
        canvasView.isAccessibilityElement = true
        canvasView.accessibilityLabel = "Drawing Canvas"
        canvasView.accessibilityHint = "Touch and drag to draw. Sound pitch changes with vertical position. Sound pans left and right with horizontal position. You will feel a bump when crossing lines you've already drawn."
        canvasView.accessibilityTraits = .allowsDirectInteraction
        
        return canvasView
    }
    
    func updateUIView(_ uiView: DrawingCanvasUIView, context: Context) {
        uiView.setNeedsDisplay()
    }
}

/// The actual UIView that handles touch events and drawing
class DrawingCanvasUIView: UIView {
    
    // MARK: - Properties
    
    var drawingStore: DrawingStore?
    var soundEngine: SoundEngine?
    var hapticEngine: HapticEngine?
    
    private var wasOnExistingLine: Bool = false
    
    // Drawing appearance
    private let strokeColor: UIColor = .white
    private let strokeWidth: CGFloat = 6.0
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }
    
    private func setup() {
        isMultipleTouchEnabled = false
        backgroundColor = .black
    }
    
    // MARK: - Touch Handling
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        
        // Start new path
        drawingStore?.beginPath(at: point, strokeWidth: strokeWidth)
        
        // Start audio
        soundEngine?.beginTone()
        updateAudio(at: point)
        
        // Start haptic
        hapticEngine?.beginDrawingHaptic()
        
        setNeedsDisplay()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        
        // Continue path
        drawingStore?.continuePath(to: point)
        
        // Update audio based on position
        updateAudio(at: point)
        
        // Check for line intersection
        checkLineIntersection(at: point)
        
        setNeedsDisplay()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        // Check for shape closure before ending path
        if let currentPath = drawingStore?.currentPath,
           currentPath.isClosedShape() {
            // Shape is closed! Trigger celebration
            soundEngine?.playShapeClosedChord()
            hapticEngine?.playShapeClosed()
            
            // Announce for VoiceOver users
            if UIAccessibility.isVoiceOverRunning {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    UIAccessibility.post(notification: .announcement, argument: "Shape closed")
                }
            }
        }
        
        // End path
        drawingStore?.endPath()
        
        // Stop audio
        soundEngine?.endTone()
        
        // Stop haptic
        hapticEngine?.endDrawingHaptic()
        
        wasOnExistingLine = false
        setNeedsDisplay()
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        touchesEnded(touches, with: event)
    }
    
    // MARK: - Audio & Haptic Updates
    
    private func updateAudio(at point: CGPoint) {
        let normalizedX = point.x / bounds.width
        let normalizedY = 1.0 - (point.y / bounds.height) // Invert Y
        let isOnLine = drawingStore?.isPointOnExistingPath(point) ?? false
        
        soundEngine?.updateTone(
            normalizedX: normalizedX,
            normalizedY: normalizedY,
            onExistingLine: isOnLine
        )
    }
    
    private func checkLineIntersection(at point: CGPoint) {
        let isOnLine = drawingStore?.isPointOnExistingPath(point) ?? false
        
        // Only trigger bump when transitioning onto a line
        if isOnLine && !wasOnExistingLine {
            hapticEngine?.playBump()
        }
        
        wasOnExistingLine = isOnLine
    }
    
    // MARK: - Drawing
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Clear background
        context.setFillColor(UIColor.black.cgColor)
        context.fill(rect)
        
        // Set stroke style
        context.setStrokeColor(strokeColor.cgColor)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        
        // Draw completed paths
        if let paths = drawingStore?.paths {
            for path in paths {
                drawPath(path, in: context)
            }
        }
        
        // Draw current path
        if let currentPath = drawingStore?.currentPath {
            drawPath(currentPath, in: context)
        }
    }
    
    private func drawPath(_ path: DrawingPath, in context: CGContext) {
        guard path.points.count > 1 else { return }
        
        context.setLineWidth(path.strokeWidth)
        context.beginPath()
        context.move(to: path.points[0])
        
        for i in 1..<path.points.count {
            context.addLine(to: path.points[i])
        }
        
        context.strokePath()
    }
}
