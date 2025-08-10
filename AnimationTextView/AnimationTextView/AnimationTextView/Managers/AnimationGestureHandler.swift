//
//  AnimationGestureHandler.swift
//  AnimationTextView
//
//  Created by Bern on 2025/8/10.
//

import UIKit

// MARK: - AnimationGestureHandlerDelegate
protocol AnimationGestureHandlerDelegate: AnyObject {
    func gestureHandlerDidTap(at point: CGPoint)
    func gestureHandlerDidLongPress(at point: CGPoint)
    func gestureHandlerDidPan(from startPoint: CGPoint, to endPoint: CGPoint, state: UIGestureRecognizer.State)
    func gestureHandlerShouldRecognizeSimultaneously() -> Bool
}

class AnimationGestureHandler: NSObject {
    
    // MARK: - Properties
    weak var delegate: AnimationGestureHandlerDelegate?
    var isEnabled: Bool = true
    var onLinkTap: ((URL) -> Void)?
    
    private weak var targetView: UIView?
    private var longPressGesture: UILongPressGestureRecognizer!
    private var panGesture: UIPanGestureRecognizer!
    private var tapGesture: UITapGestureRecognizer!
    
    // Track pan gesture start point
    private var panStartPoint: CGPoint?
    
    // MARK: - Setup
    func setupGestures(on view: UIView) {
        targetView = view
        
        // Long press for selection
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.5
        longPressGesture.delegate = self
        view.addGestureRecognizer(longPressGesture)
        
        // Pan for selection adjustment
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        
        // Tap for links and clearing selection
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tapGesture.delegate = self
        view.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Gesture Actions
    @objc private func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        guard isEnabled else { return }
        
        let location = gesture.location(in: gesture.view)
        
        switch gesture.state {
        case .began:
            delegate?.gestureHandlerDidLongPress(at: location)
            
        default:
            break
        }
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard isEnabled else { return }
        
        let location = gesture.location(in: gesture.view)
        
        switch gesture.state {
        case .began:
            panStartPoint = location
            delegate?.gestureHandlerDidPan(from: location, to: location, state: .began)
            
        case .changed:
            guard let startPoint = panStartPoint else { return }
            delegate?.gestureHandlerDidPan(from: startPoint, to: location, state: .changed)
            
        case .ended, .cancelled, .failed:
            guard let startPoint = panStartPoint else { return }
            delegate?.gestureHandlerDidPan(from: startPoint, to: location, state: gesture.state)
            panStartPoint = nil
            
        default:
            break
        }
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard isEnabled else { return }
        
        let location = gesture.location(in: gesture.view)
        delegate?.gestureHandlerDidTap(at: location)
    }
    
    // MARK: - Public Methods
    func disableScrollViewInteraction(_ disable: Bool) {
        guard let view = targetView else { return }
        
        var superview = view.superview
        while superview != nil {
            if let scrollView = superview as? UIScrollView {
                scrollView.isScrollEnabled = !disable
                scrollView.panGestureRecognizer.isEnabled = !disable
                break
            }
            superview = superview?.superview
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension AnimationGestureHandler: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == longPressGesture {
            if otherGestureRecognizer is UIPanGestureRecognizer,
               otherGestureRecognizer.view is UIScrollView {
                return false
            }
            return true
        }
        
        if gestureRecognizer == panGesture {
            if otherGestureRecognizer is UIPanGestureRecognizer,
               otherGestureRecognizer.view is UIScrollView {
                return false
            }
            return delegate?.gestureHandlerShouldRecognizeSimultaneously() ?? true
        }
        
        return false
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if !isEnabled {
            return false
        }
        
        if gestureRecognizer == panGesture {
            return true
        }
        
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if (gestureRecognizer == panGesture || gestureRecognizer == longPressGesture),
           otherGestureRecognizer.view is UIScrollView {
            return false
        }
        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if (gestureRecognizer == panGesture || gestureRecognizer == longPressGesture),
           otherGestureRecognizer.view is UIScrollView {
            if let delegate = delegate,
               !delegate.gestureHandlerShouldRecognizeSimultaneously() {
                return true
            }
        }
        return false
    }
}
