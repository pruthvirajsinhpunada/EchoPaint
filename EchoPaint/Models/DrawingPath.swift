//
//  DrawingPath.swift
//  EchoPaint
//
//  Model for storing drawn strokes
//

import Foundation
import CoreGraphics

/// Represents a single continuous stroke on the canvas
struct DrawingPath: Identifiable {
    let id = UUID()
    var points: [CGPoint]
    let strokeWidth: CGFloat
    let createdAt: Date
    
    init(points: [CGPoint] = [], strokeWidth: CGFloat = 8.0) {
        self.points = points
        self.strokeWidth = strokeWidth
        self.createdAt = Date()
    }
    
    mutating func addPoint(_ point: CGPoint) {
        points.append(point)
    }
    
    /// Check if a point is within threshold distance of this path
    func containsPoint(_ point: CGPoint, threshold: CGFloat) -> Bool {
        for pathPoint in points {
            let distance = hypot(point.x - pathPoint.x, point.y - pathPoint.y)
            if distance <= threshold {
                return true
            }
        }
        return false
    }
    
    /// Check if the stroke forms a closed shape (endpoints meet)
    /// - Parameters:
    ///   - threshold: Maximum distance between start and end points to consider "closed"
    ///   - minPoints: Minimum points required to prevent false positives from tiny loops
    /// - Returns: True if the shape is closed
    func isClosedShape(threshold: CGFloat = 40.0, minPoints: Int = 20) -> Bool {
        guard points.count >= minPoints,
              let first = points.first,
              let last = points.last else {
            return false
        }
        
        let distance = hypot(last.x - first.x, last.y - first.y)
        return distance <= threshold
    }
}

/// Manages all drawn paths on the canvas
class DrawingStore: ObservableObject {
    @Published var paths: [DrawingPath] = []
    @Published var currentPath: DrawingPath?
    
    /// Start a new stroke
    func beginPath(at point: CGPoint, strokeWidth: CGFloat = 8.0) {
        var path = DrawingPath(strokeWidth: strokeWidth)
        path.addPoint(point)
        currentPath = path
    }
    
    /// Continue the current stroke
    func continuePath(to point: CGPoint) {
        currentPath?.addPoint(point)
    }
    
    /// Finish the current stroke and add to paths array
    func endPath() {
        if let path = currentPath, path.points.count > 1 {
            paths.append(path)
        }
        currentPath = nil
    }
    
    /// Check if a point intersects any existing path
    func isPointOnExistingPath(_ point: CGPoint, threshold: CGFloat = 15.0) -> Bool {
        for path in paths {
            if path.containsPoint(point, threshold: threshold) {
                return true
            }
        }
        return false
    }
    
    /// Clear all paths
    func clearAll() {
        paths.removeAll()
        currentPath = nil
    }
    
    /// Get total number of points across all paths
    var totalPointCount: Int {
        paths.reduce(0) { $0 + $1.points.count }
    }
}
