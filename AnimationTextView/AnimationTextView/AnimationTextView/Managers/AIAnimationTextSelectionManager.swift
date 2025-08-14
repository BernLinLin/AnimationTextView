//
//  AIAnimationTextSelectionManager.swift
//  HLHS
//
//  Created by Bern on 2025/8/12.
//

import Foundation

class AIAnimationTextSelectionManager {
    var isSelecting = false
    var isDraggingHandle = false
    var isDraggingSelection = false 
    private var isDraggingStartHandle = false
    private var isDraggingEndHandle = false
    private var selectionStartLocation: CGPoint?
    private var initialSelectionIndex: Int?
    
    enum HandleType {
        case start
        case end
    }
    
    func startSelection(at index: Int, location: CGPoint) {
        initialSelectionIndex = index
        selectionStartLocation = location
    }
    
    func endSelection() {
        selectionStartLocation = nil
        initialSelectionIndex = nil
    }
    
    func startHandleDrag(handle: HandleType) {
        isDraggingStartHandle = (handle == .start)
        isDraggingEndHandle = (handle == .end)
    }
    
    func endHandleDrag() {
        isDraggingStartHandle = false
        isDraggingEndHandle = false
    }
    
    func updateSelection(to location: CGPoint, characterFrames: [CGRect]) -> NSRange? {
        guard let startIndex = initialSelectionIndex,
              let currentIndex = characterIndexAt(location: location, in: characterFrames) else {
            return nil
        }
        
        let minIndex = min(startIndex, currentIndex)
        let maxIndex = max(startIndex, currentIndex)
        
        if minIndex == maxIndex {
            return NSRange(location: minIndex, length: 1)
        } else {
            return NSRange(location: minIndex, length: maxIndex - minIndex + 1)
        }
    }
    
    func updateHandleDrag(to location: CGPoint, currentRange: NSRange?, characterFrames: [CGRect]) -> NSRange? {
        guard let currentRange = currentRange,
              let charIndex = characterIndexAt(location: location, in: characterFrames) else {
            return nil
        }
        
        var newRange: NSRange?
        
        if isDraggingStartHandle {
            let endIndex = currentRange.location + currentRange.length - 1
            if charIndex <= endIndex {
                newRange = NSRange(location: charIndex, length: endIndex - charIndex + 1)
            } else {
                newRange = NSRange(location: endIndex, length: charIndex - endIndex + 1)
                isDraggingStartHandle = false
                isDraggingEndHandle = true
            }
        } else if isDraggingEndHandle {
            let startIndex = currentRange.location
            if charIndex >= startIndex {
                newRange = NSRange(location: startIndex, length: charIndex - startIndex + 1)
            } else {
                newRange = NSRange(location: charIndex, length: startIndex - charIndex + 1)
                isDraggingStartHandle = true
                isDraggingEndHandle = false
            }
        }
        
        return newRange
    }
    
    func characterIndexAt(location: CGPoint, in characterFrames: [CGRect]) -> Int? {
        for (index, frame) in characterFrames.enumerated() {
            if frame.contains(location) {
                return index
            }
        }
        
        var closestIndex: Int?
        var closestDistance: CGFloat = .greatestFiniteMagnitude
        
        for (index, frame) in characterFrames.enumerated() {
            let centerX = frame.midX
            let centerY = frame.midY
            let distance = sqrt(pow(location.x - centerX, 2) + pow(location.y - centerY, 2))
            
            if location.y >= frame.minY && location.y <= frame.maxY {
                let horizontalDistance = abs(location.x - centerX)
                if horizontalDistance < closestDistance {
                    closestDistance = horizontalDistance
                    closestIndex = index
                }
            } else if distance < closestDistance {
                closestDistance = distance
                closestIndex = index
            }
        }
        
        return closestIndex
    }
    
    func wordRangeAt(characterIndex: Int, in parsedItems: [AIAnimationTextParsedItem]) -> NSRange {
        var start = characterIndex
        var end = characterIndex
        var currentIndex = 0
        
        for (_, item) in parsedItems.enumerated() {
            if item.type == .character, let char = item.char, char != "\n" {
                if currentIndex < characterIndex {
                    if char.isWhitespace || char.isPunctuation {
                        start = currentIndex + 1
                    }
                }
                currentIndex += 1
            }
        }
        
        currentIndex = 0
        for item in parsedItems {
            if item.type == .character, let char = item.char, char != "\n" {
                if currentIndex > characterIndex {
                    if char.isWhitespace || char.isPunctuation {
                        break
                    }
                    end = currentIndex
                }
                currentIndex += 1
            }
        }
        
        return NSRange(location: start, length: end - start + 1)
    }
    
    func isLocationInSelection(_ location: CGPoint, range: NSRange, characterFrames: [CGRect]) -> Bool {
        for i in range.location..<(range.location + range.length) {
            if i < characterFrames.count {
                if characterFrames[i].contains(location) {
                    return true
                }
            }
        }
        return false
    }
    
    func getSelectionRects(for range: NSRange, characterFrames: [CGRect]) -> [CGRect] {
        var rects: [CGRect] = []
        
        for i in range.location..<(range.location + range.length) {
            if i < characterFrames.count {
                rects.append(characterFrames[i])
            }
        }
        
        return rects
    }
    
    func mergeRects(_ rects: [CGRect]) -> [CGRect] {
        guard !rects.isEmpty else { return [] }
        
        var mergedRects: [CGRect] = []
        var currentRect = rects[0]
        
        for i in 1..<rects.count {
            let rect = rects[i]
            
            if abs(rect.minY - currentRect.minY) < 1 &&
               abs(rect.minX - currentRect.maxX) < 2 {
                currentRect = currentRect.union(rect)
            } else {
                mergedRects.append(currentRect)
                currentRect = rect
            }
        }
        
        mergedRects.append(currentRect)
        return mergedRects
    }
}
