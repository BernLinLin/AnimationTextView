//
//  AnimationSelectionManager.swift
//  AnimationTextView
//
//  Created by Bern on 2025/8/10.
//

import UIKit

// MARK: - AnimationSelectionDelegate
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
    private var selectionAnchorIndex: Int?  // 固定的锚点，不会改变
    private var selectionActiveIndex: Int?  // 活动端点，随拖动改变
    
    // Character frames provider
    var characterFramesProvider: (() -> [CGRect])?
    
    // Handle dragging
    private var isDraggingStartHandle = false
    private var isDraggingEndHandle = false
    
    // Parent scroll view management
    weak var parentScrollView: UIScrollView?
    
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
        
        // Ensure we have valid indices
        guard range.location < frames.count else { return nil }
        
        let endIndex = min(range.location + range.length, frames.count)
        let selectedFrames = Array(frames[range.location..<endIndex])
        
        guard !selectedFrames.isEmpty else { return nil }
        
        return selectedFrames.reduce(selectedFrames[0]) { $0.union($1) }
    }
    
    // MARK: - Initialization
    init() {
        findParentScrollView()
    }
    
    // MARK: - Public Methods
    func updateLayout() {
        updateSelectionView()
    }
    
    func clearSelection() {
        selectedRange = nil
        isSelecting = false
        selectionAnchorIndex = nil
        selectionActiveIndex = nil
        
        selectionView?.clearSelection()
        startHandle?.isHidden = true
        endHandle?.isHidden = true
        
        // 恢复滚动
        enableParentScrollView(true)
        
        delegate?.selectionDidChange(nil)
    }
    
    func setParentView(_ view: UIView) {
        // 查找父视图中的 ScrollView
        var superview = view.superview
        while superview != nil {
            if let scrollView = superview as? UIScrollView {
                parentScrollView = scrollView
                break
            }
            superview = superview?.superview
        }
    }
    
    // MARK: - Gesture Handling
    func handleTap(at point: CGPoint) {
        // Clear selection if tapped outside
        if hasSelection && !isPointInSelection(point) {
            clearSelection()
        }
    }
    
    func handleLongPress(at point: CGPoint) {
        guard delegate?.selectionShouldBegin(at: point) == true else { return }
        
        if let index = characterIndexAt(point: point) {
            // 设置锚点（不会改变）
            selectionAnchorIndex = index
            selectionActiveIndex = index
            
            // Select word at point
            let wordRange = wordRangeAt(characterIndex: index)
            selectedRange = wordRange
            
            // 如果是单词选择，更新锚点和活动点
            if wordRange.length > 1 {
                selectionAnchorIndex = wordRange.location
                selectionActiveIndex = wordRange.location + wordRange.length - 1
            }
            
            isSelecting = true
            
            updateSelectionView()
            delegate?.selectionDidChange(wordRange)
        }
    }
    
    func handlePan(from startPoint: CGPoint, to endPoint: CGPoint, state: UIGestureRecognizer.State) {
        switch state {
        case .began:
            if let index = characterIndexAt(point: startPoint) {
                // 如果还没有选择，设置锚点
                if selectionAnchorIndex == nil {
                    selectionAnchorIndex = index
                    selectionActiveIndex = index
                }
                isSelecting = true
                // 禁用滚动
                enableParentScrollView(false)
            }
            
        case .changed:
            guard isSelecting,
                  let anchorIndex = selectionAnchorIndex,
                  let currentIndex = characterIndexAt(point: endPoint) else { return }
            
            // 更新活动端点
            selectionActiveIndex = currentIndex
            
            // 计算选择范围（从锚点到当前位置）
            let minIndex = min(anchorIndex, currentIndex)
            let maxIndex = max(anchorIndex, currentIndex)
            
            selectedRange = NSRange(location: minIndex, length: maxIndex - minIndex + 1)
            updateSelectionView()
            
        case .ended, .cancelled:
            isSelecting = false
            // 恢复滚动
            enableParentScrollView(true)
            
            if let range = selectedRange {
                delegate?.selectionDidChange(range)
            }
            
        default:
            break
        }
    }
    
    func handleHandleDrag(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: gesture.view?.superview)
        
        switch gesture.state {
        case .began:
            isDraggingStartHandle = (gesture.view == startHandle)
            isDraggingEndHandle = (gesture.view == endHandle)
            // 禁用滚动
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
                    // Swap handles
                    newRange = NSRange(location: endIndex, length: newIndex - endIndex + 1)
                    isDraggingStartHandle = false
                    isDraggingEndHandle = true
                }
            } else if isDraggingEndHandle {
                let startIndex = currentRange.location
                if newIndex >= startIndex {
                    newRange = NSRange(location: startIndex, length: newIndex - startIndex + 1)
                } else {
                    // Swap handles
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
            // 恢复滚动
            enableParentScrollView(true)
            
            if let range = selectedRange {
                delegate?.selectionDidChange(range)
            }
            
        default:
            break
        }
    }
    
    // MARK: - Private Methods
    private func findParentScrollView() {
        // This will be set when the view is added to hierarchy
    }
    
    private func enableParentScrollView(_ enable: Bool) {
        parentScrollView?.isScrollEnabled = enable
        // 同时处理手势识别器
        parentScrollView?.panGestureRecognizer.isEnabled = enable
    }
    
    private func updateSelectionView() {
        guard let range = selectedRange,
              let frames = characterFramesProvider?() else {
            selectionView?.clearSelection()
            startHandle?.isHidden = true
            endHandle?.isHidden = true
            return
        }
        
        // Ensure we have valid indices
        guard range.location < frames.count else { return }
        
        // Get frames for selected range
        let startIndex = range.location
        let endIndex = min(range.location + range.length, frames.count)
        
        guard startIndex < endIndex else { return }
        
        let selectedFrames = Array(frames[startIndex..<endIndex])
        selectionView?.updateSelection(rects: selectedFrames)
        
        // Update handle positions
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
                // Same line - use horizontal distance
                distance = abs(point.x - frame.midX)
            } else {
                // Different line - use full distance
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
        // 这里需要访问实际的文本内容来判断单词边界
        // 暂时返回单个字符选择
        // 在实际实现中，您需要传入文本内容或通过代理获取
        return NSRange(location: characterIndex, length: 1)
    }
}
