//
//  TouchPoint.swift
//  EchoPaint
//
//  Model for touch data
//

import Foundation
import CoreGraphics

/// Represents a single touch point with normalized coordinates
struct TouchPoint: Identifiable, Equatable {
    let id = UUID()
    let position: CGPoint
    let timestamp: Date
    
    /// Normalized X position (0.0 = left, 1.0 = right)
    var normalizedX: CGFloat
    
    /// Normalized Y position (0.0 = bottom, 1.0 = top)
    var normalizedY: CGFloat
    
    init(position: CGPoint, canvasSize: CGSize) {
        self.position = position
        self.timestamp = Date()
        self.normalizedX = position.x / canvasSize.width
        // Invert Y so bottom = 0, top = 1 (more intuitive for pitch)
        self.normalizedY = 1.0 - (position.y / canvasSize.height)
    }
    
    static func == (lhs: TouchPoint, rhs: TouchPoint) -> Bool {
        lhs.id == rhs.id
    }
}
