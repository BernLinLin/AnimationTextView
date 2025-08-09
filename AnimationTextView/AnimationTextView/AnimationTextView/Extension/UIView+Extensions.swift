//
//  UIView+Extensions.swift
//  AnimationTextView
//
//  Created by Bern on 2025/8/10.
//

import UIKit

// MARK: - UIView Extensions
extension UIView {
    
    /// Find the first superview of the specified type
    func findSuperview<T: UIView>(ofType type: T.Type) -> T? {
        var superview = self.superview
        
        while superview != nil {
            if let typedView = superview as? T {
                return typedView
            }
            superview = superview?.superview
        }
        
        return nil
    }
    
    /// Find all subviews of the specified type
    func findSubviews<T: UIView>(ofType type: T.Type) -> [T] {
        var result: [T] = []
        
        for subview in subviews {
            if let typedView = subview as? T {
                result.append(typedView)
            }
            result.append(contentsOf: subview.findSubviews(ofType: type))
        }
        
        return result
    }
}

// MARK: - CALayer Extensions
extension CALayer {
    
    /// Pause all animations on the layer
    func pauseAnimations() {
        let pausedTime = convertTime(CACurrentMediaTime(), from: nil)
        speed = 0.0
        timeOffset = pausedTime
    }
    
    /// Resume all animations on the layer
    func resumeAnimations() {
        let pausedTime = timeOffset
        speed = 1.0
        timeOffset = 0.0
        beginTime = 0.0
        let timeSincePause = convertTime(CACurrentMediaTime(), from: nil) - pausedTime
        beginTime = timeSincePause
    }
    
    /// Remove all animations
    func removeAllAnimations(completion: (() -> Void)? = nil) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        removeAllAnimations()
        CATransaction.commit()
    }
}

// MARK: - CGRect Extensions
extension CGRect {
    
    /// Center point of the rectangle
    var center: CGPoint {
        return CGPoint(x: midX, y: midY)
    }
    
    /// Check if two rectangles are on the same line (approximately)
    func isOnSameLine(as other: CGRect, tolerance: CGFloat = 2.0) -> Bool {
        return abs(self.midY - other.midY) < tolerance
    }
    
    /// Check if this rectangle is adjacent to another
    func isAdjacent(to other: CGRect, tolerance: CGFloat = 2.0) -> Bool {
        return isOnSameLine(as: other) && abs(self.maxX - other.minX) < tolerance
    }
}

// MARK: - String Extensions
extension String {
    
    /// Get character at index safely
    subscript(safe index: Int) -> Character? {
        guard index >= 0 && index < count else { return nil }
        return self[self.index(startIndex, offsetBy: index)]
    }
    
    /// Get substring with NSRange
    subscript(nsRange: NSRange) -> String? {
        guard let range = Range(nsRange, in: self) else { return nil }
        return String(self[range])
    }
    
    /// Convert to NSString and get size with attributes
    func size(withAttributes attrs: [NSAttributedString.Key: Any]) -> CGSize {
        return (self as NSString).size(withAttributes: attrs)
    }
    
    /// Split into words
    func words() -> [String] {
        return components(separatedBy: .whitespacesAndNewlines).filter { !$0.isEmpty }
    }
}

// MARK: - NSAttributedString Extensions
extension NSAttributedString {
    
    /// Calculate size constrained to width
    func size(constrainedTo width: CGFloat) -> CGSize {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = boundingRect(
            with: constraintRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return boundingBox.size
    }
}

// MARK: - Collection Extensions
extension Collection {
    
    /// Safe subscript that returns nil instead of crashing
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - Array Extensions
extension Array {
    
    /// Split array into chunks of specified size
    func chunked(by size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

// MARK: - DispatchQueue Extensions
extension DispatchQueue {
    
    /// Debounce function execution
    func debounce(delay: TimeInterval, action: @escaping () -> Void) -> () -> Void {
        var workItem: DispatchWorkItem?
        
        return {
            workItem?.cancel()
            workItem = DispatchWorkItem(block: action)
            self.asyncAfter(deadline: .now() + delay, execute: workItem!)
        }
    }
}
