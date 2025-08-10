//
//  AnimationSelectionManager.swift
//  AnimationTextView
//
//  Created by Bern on 2025/8/10.
//

import UIKit

// MARK: - SelectionDelegate
protocol AnimationSelectionDelegate: AnyObject {
    func selectionDidChange(_ range: NSRange?)
    func selectionShouldBegin(at point: CGPoint) -> Bool
    func textInRange(_ range: NSRange) -> String?
}

class AnimationSelectionManager {
    
    // MARK: - Properties
    weak var delegate: AnimationSelectionDelegate?
    weak var selectionView: AnimationTextSelectionView?
    weak var startHandle: AnimationSelectionHandleView?
    weak var endHandle: AnimationSelectionHandleView?
    
    private(set) var selectedRange: NSRange?
    private(set) var isSelecting = false
    
    // Selection state
    private var selectionAnchorIndex: Int?
    private var selectionActiveIndex: Int?
    
    // Character frames provider
    var characterFramesProvider: (() -> [CGRect])?
    
    // Handle dragging
    private var isDraggingStartHandle = false
    private var isDraggingEndHandle = false
    
    // Parent scroll view management
    weak var parentScrollView: UIScrollView?
    private var originalScrollEnabled: Bool = true
    private var scrollViewObservation: NSKeyValueObservation?
    
    // Handle gestures
    private var startHandlePanGesture: UIPanGestureRecognizer?
    private var endHandlePanGesture: UIPanGestureRecognizer?
    
    // Computed properties
    var hasSelection: Bool {
        return selectedRange != nil && selectedRange!.length > 0
    }
    
    var selectedText: String? {
        guard let range = selectedRange else { return nil }
        return delegate?.textInRange(range)
    }
    
    var selectionRect: CGRect? {
        guard let range = selectedRange,
              let frames = characterFramesProvider?() else { return nil }
        
        guard range.location < frames.count else { return nil }
        
        let endIndex = min(range.location + range.length, frames.count)
        let selectedFrames = Array(frames[range.location..<endIndex])
        
        guard !selectedFrames.isEmpty else { return nil }
        
        return selectedFrames.reduce(selectedFrames[0]) { $0.union($1) }
    }
    
    // MARK: - Initialization
    init() {
        setupNotifications()
    }
    
    deinit {
        scrollViewObservation?.invalidate()
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Setup
    private func setupNotifications() {
        // Listen for app state changes if needed
    }
    
    func setParentView(_ view: UIView) {
        // Find parent ScrollView
        var superview = view.superview
        while superview != nil {
            if let scrollView = superview as? UIScrollView {
                parentScrollView = scrollView
                originalScrollEnabled = scrollView.isScrollEnabled
                break
            }
            superview = superview?.superview
        }
        
        setupHandleGestures()
    }
    
    private func setupHandleGestures() {
        if startHandlePanGesture == nil {
            startHandlePanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleHandlePan(_:)))
            startHandle?.addGestureRecognizer(startHandlePanGesture!)
        }
        
        if endHandlePanGesture == nil {
            endHandlePanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleHandlePan(_:)))
            endHandle?.addGestureRecognizer(endHandlePanGesture!)
        }
    }
    
    // MARK: - Public Methods
    func updateLayout() {
        updateSelectionView()
    }
    
    func clearSelection() {
        let wasSelecting = isSelecting
        
        selectedRange = nil
        isSelecting = false
        selectionAnchorIndex = nil
        selectionActiveIndex = nil
        
        selectionView?.clearSelection()
        startHandle?.isHidden = true
        endHandle?.isHidden = true
        
        if wasSelecting {
            enableParentScrollView(true)
        }
        
        delegate?.selectionDidChange(nil)
    }
    
    // MARK: - Gesture Handling
    func handleTap(at point: CGPoint) {
        if hasSelection && !isPointInSelection(point) {
            clearSelection()
        }
    }
    
    func handleLongPress(at point: CGPoint) {
        guard delegate?.selectionShouldBegin(at: point) == true else { return }
        
        enableParentScrollView(false)
        
        if let index = characterIndexAt(point: point) {
            selectionAnchorIndex = index
            selectionActiveIndex = index
            
            let wordRange = wordRangeAt(characterIndex: index)
            selectedRange = wordRange
            
            if wordRange.length > 1 {
                selectionAnchorIndex = wordRange.location
                selectionActiveIndex = wordRange.location + wordRange.length - 1
            }
            
            isSelecting = true
            
            updateSelectionView()
            delegate?.selectionDidChange(wordRange)
        } else {
            enableParentScrollView(true)
        }
    }
    
    func handlePan(from startPoint: CGPoint, to endPoint: CGPoint, state: UIGestureRecognizer.State) {
        switch state {
        case .began:
            if let index = characterIndexAt(point: startPoint) {
                if selectionAnchorIndex == nil {
                    selectionAnchorIndex = index
                    selectionActiveIndex = index
                }
                isSelecting = true
                enableParentScrollView(false)
            }
            
        case .changed:
            guard isSelecting,
                  let anchorIndex = selectionAnchorIndex,
                  let currentIndex = characterIndexAt(point: endPoint) else { return }
            
            selectionActiveIndex = currentIndex
            
            let minIndex = min(anchorIndex, currentIndex)
            let maxIndex = max(anchorIndex, currentIndex)
            
            selectedRange = NSRange(location: minIndex, length: maxIndex - minIndex + 1)
            updateSelectionView()
            
        case .ended, .cancelled:
            if let range = selectedRange {
                delegate?.selectionDidChange(range)
            }
            
        default:
            break
        }
    }
    
    @objc private func handleHandlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: gesture.view?.superview)
        
        switch gesture.state {
        case .began:
            isDraggingStartHandle = (gesture.view == startHandle)
            isDraggingEndHandle = (gesture.view == endHandle)
            enableParentScrollView(false)
            
        case .changed:
            guard let currentRange = selectedRange,
                  let newIndex = characterIndexAt(point: location) else { return }
            
            var newRange: NSRange?
            
            if isDraggingStartHandle {
                let endIndex = currentRange.location + currentRange.length - 1
                if newIndex <= endIndex {
                    newRange = NSRange(location: newIndex, length: endIndex - newIndex + 1)
                } else {
                    newRange = NSRange(location: endIndex, length: newIndex - endIndex + 1)
                    isDraggingStartHandle = false
                    isDraggingEndHandle = true
                }
            } else if isDraggingEndHandle {
                let startIndex = currentRange.location
                if newIndex >= startIndex {
                    newRange = NSRange(location: startIndex, length: newIndex - startIndex + 1)
                } else {
                    newRange = NSRange(location: newIndex, length: startIndex - newIndex + 1)
                    isDraggingStartHandle = true
                    isDraggingEndHandle = false
                }
            }
            
            if let range = newRange, range.length > 0 {
                selectedRange = range
                updateSelectionView()
            }
            
        case .ended, .cancelled:
            isDraggingStartHandle = false
            isDraggingEndHandle = false
            if let range = selectedRange {
                delegate?.selectionDidChange(range)
            }
            
        default:
            break
        }
    }
    
    // MARK: - Private Methods
    private func enableParentScrollView(_ enable: Bool) {
        guard let scrollView = parentScrollView else { return }
        
        if enable {
            scrollViewObservation?.invalidate()
            scrollViewObservation = nil
            
            scrollView.isScrollEnabled = originalScrollEnabled
            scrollView.panGestureRecognizer.isEnabled = originalScrollEnabled
            scrollView.isUserInteractionEnabled = true
            
            NotificationCenter.default.post(name: .textSelectionDidEnd, object: nil)
        } else {
            originalScrollEnabled = scrollView.isScrollEnabled
            
            scrollView.setContentOffset(scrollView.contentOffset, animated: false)
            
            scrollView.isScrollEnabled = false
            scrollView.panGestureRecognizer.isEnabled = false
            
            scrollViewObservation = scrollView.observe(\.isScrollEnabled, options: [.new]) { [weak self] scrollView, _ in
                guard let self = self, self.isSelecting else { return }
                if scrollView.isScrollEnabled {
                    scrollView.isScrollEnabled = false
                    scrollView.panGestureRecognizer.isEnabled = false
                }
            }
            
            NotificationCenter.default.post(name: .textSelectionDidBegin, object: nil)
        }
    }
    
    private func updateSelectionView() {
        guard let range = selectedRange,
              let frames = characterFramesProvider?() else {
            selectionView?.clearSelection()
            startHandle?.isHidden = true
            endHandle?.isHidden = true
            return
        }
        
        guard range.location < frames.count else { return }
        
        let startIndex = range.location
        let endIndex = min(range.location + range.length, frames.count)
        
        guard startIndex < endIndex else { return }
        
        let selectedFrames = Array(frames[startIndex..<endIndex])
        selectionView?.updateSelection(rects: selectedFrames)
        
        if let firstFrame = selectedFrames.first {
            startHandle?.positionHandle(at: firstFrame.origin, for: .start)
            startHandle?.isHidden = false
        }
        
        if let lastFrame = selectedFrames.last {
            let endPoint = CGPoint(x: lastFrame.maxX, y: lastFrame.maxY)
            endHandle?.positionHandle(at: endPoint, for: .end)
            endHandle?.isHidden = false
        }
    }
    
    private func characterIndexAt(point: CGPoint) -> Int? {
        guard let frames = characterFramesProvider?() else { return nil }
        
        // Direct hit test
        for (index, frame) in frames.enumerated() {
            if frame.contains(point) {
                return index
            }
        }
        
        // Find nearest character
        var closestIndex: Int?
        var closestDistance: CGFloat = .greatestFiniteMagnitude
        
        for (index, frame) in frames.enumerated() {
            let distance: CGFloat
            
            if point.y >= frame.minY && point.y <= frame.maxY {
                distance = abs(point.x - frame.midX)
            } else {
                distance = hypot(point.x - frame.midX, point.y - frame.midY)
            }
            
            if distance < closestDistance {
                closestDistance = distance
                closestIndex = index
            }
        }
        
        return closestIndex
    }
    
    private func isPointInSelection(_ point: CGPoint) -> Bool {
        guard let range = selectedRange,
              let frames = characterFramesProvider?() else { return false }
        
        let startIndex = range.location
        let endIndex = min(range.location + range.length, frames.count)
        
        for i in startIndex..<endIndex {
            if i < frames.count && frames[i].contains(point) {
                return true
            }
        }
        
        return false
    }
    
    private func wordRangeAt(characterIndex: Int) -> NSRange {
        // Simple single character selection for now
        // Implement proper word boundary detection if needed
        return NSRange(location: characterIndex, length: 1)
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let textSelectionDidBegin = Notification.Name("AnimationTextView.textSelectionDidBegin")
    static let textSelectionDidEnd = Notification.Name("AnimationTextView.textSelectionDidEnd")
}
