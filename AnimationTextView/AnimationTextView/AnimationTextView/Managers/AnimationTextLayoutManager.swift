//
//  AnimationTextLayoutManager.swift
//  AnimationTextView
//
//  Created by Bern on 2025/8/10.
//

import UIKit

class AnimationTextLayoutManager {
    
    // MARK: - Properties
    var theme = AnimationTextStyleTheme.default
    private(set) var calculatedHeight: CGFloat = 0
    
    // MARK: - Layout Result
    struct CharacterLayoutResult {
        let characterFrames: [CGRect]
        let decorations: [TextDecoration]
        let totalHeight: CGFloat
    }
    
    // MARK: - Public Methods
    
    /// Layout characters one by one, matching original implementation
    func layoutCharacters(_ items: [AnimationParsedItem],
                         layers: [CATextLayer],
                         in bounds: CGRect) -> CharacterLayoutResult {
        
        var characterFrames: [CGRect] = []
        var decorations: [TextDecoration] = []
        
        var currentY: CGFloat = 0
        let indentSize: CGFloat = 25.0
        let lines = splitIntoLines(items: items)
        var charLayerIndex = 0
        
        for line in lines {
            var currentX: CGFloat = 0
            var maxLineHeight: CGFloat = theme.font.lineHeight
            
            guard let firstItem = line.first else {
                currentY += maxLineHeight * theme.lineSpace
                continue
            }
            
            // Handle horizontal rule
            if firstItem.type == .horizontalRule {
                currentY += maxLineHeight * 0.6
                decorations.append(TextDecoration(
                    type: .horizontalRule,
                    frame: CGRect(x: 0, y: currentY, width: bounds.width, height: 1)
                ))
                currentY += maxLineHeight * 0.6
                continue
            }
            
            // Calculate line indent
            let attributes = firstItem.attributes
            let lineIndent = CGFloat(attributes.blockquoteLevel + attributes.listLevel) * indentSize
            currentX = lineIndent
            
            // Add line decorations
            decorations.append(contentsOf: createLineDecorations(
                for: attributes,
                at: currentY,
                indent: lineIndent,
                lineHeight: maxLineHeight
            ))
            
            // Layout each character in the line
            for item in line {
                guard item.type == .text,
                      let text = item.text,
                      text != "\n" else { continue }
                guard charLayerIndex < layers.count else { break }
                
                let currentLayer = layers[charLayerIndex]
                guard let attrString = currentLayer.string as? NSAttributedString,
                      attrString.length > 0 else {
                    charLayerIndex += 1
                    continue
                }
                
                // Get character size
                let stringAttrs = attrString.attributes(at: 0, effectiveRange: nil)
                let charSize = (attrString.string as NSString).size(withAttributes: stringAttrs)
                
                // Check for line wrap
                if currentX + charSize.width > bounds.width && currentX > lineIndent {
                    currentY += maxLineHeight * theme.lineSpace
                    currentX = lineIndent
                    maxLineHeight = theme.font.lineHeight
                }
                
                // Create character frame
                let frame = CGRect(
                    x: currentX,
                    y: currentY,
                    width: charSize.width,
                    height: charSize.height
                )
                
                characterFrames.append(frame)
                
                currentX += charSize.width
                maxLineHeight = max(maxLineHeight, charSize.height)
                charLayerIndex += 1
            }
            
            currentY += maxLineHeight * theme.lineSpace
        }
        
        calculatedHeight = currentY
        
        return CharacterLayoutResult(
            characterFrames: characterFrames,
            decorations: decorations,
            totalHeight: calculatedHeight
        )
    }
    
    /// Get text in the specified range from parsed items
    func textInRange(_ range: NSRange, from items: [AnimationParsedItem]) -> String? {
        var result = ""
        var charIndex = 0
        
        for item in items {
            if item.type == .text, let text = item.text, text != "\n" {
                if charIndex >= range.location && charIndex < range.location + range.length {
                    result.append(text)
                }
                charIndex += 1
            } else if item.text == "\n" &&
                      charIndex >= range.location &&
                      charIndex < range.location + range.length {
                result.append("\n")
            }
        }
        
        return result.isEmpty ? nil : result
    }
    
    /// Find word boundaries at character index
    func wordRangeAt(characterIndex: Int, in items: [AnimationParsedItem]) -> NSRange {
        var start = characterIndex
        var end = characterIndex
        _ = 0
        
        // Convert items to text array for easier processing
        var characters: [Character] = []
        for item in items {
            if item.type == .text, let text = item.text, text != "\n" {
                characters.append(Character(text))
            }
        }
        
        guard characterIndex < characters.count else {
            return NSRange(location: characterIndex, length: 1)
        }
        
        // Find word start
        while start > 0 {
            let prevChar = characters[start - 1]
            if prevChar.isWhitespace || prevChar.isPunctuation {
                break
            }
            start -= 1
        }
        
        // Find word end
        while end < characters.count - 1 {
            let nextChar = characters[end + 1]
            if nextChar.isWhitespace || nextChar.isPunctuation {
                break
            }
            end += 1
        }
        
        return NSRange(location: start, length: end - start + 1)
    }
    
    // MARK: - Private Methods
    
    private func splitIntoLines(items: [AnimationParsedItem]) -> [[AnimationParsedItem]] {
        return items.split(whereSeparator: { $0.text == "\n" }).map { Array($0) }
    }
    
    private func createLineDecorations(for attributes: TextAttributes,
                                     at y: CGFloat,
                                     indent: CGFloat,
                                     lineHeight: CGFloat) -> [TextDecoration] {
        var decorations: [TextDecoration] = []
        
        // List marker
        if attributes.listLevel > 0 {
            let marker = "•"  // Default bullet
            decorations.append(TextDecoration(
                type: .listMarker(marker),
                frame: CGRect(
                    x: indent - 20,
                    y: y,
                    width: 15,
                    height: lineHeight
                )
            ))
        }
        
        // Blockquote lines
        if attributes.blockquoteLevel > 0 {
            for i in 1...attributes.blockquoteLevel {
                let xPos = (CGFloat(i) * 25.0) - 15.0
                decorations.append(TextDecoration(
                    type: .blockquoteLine(level: i),
                    frame: CGRect(
                        x: xPos,
                        y: y,
                        width: 2,
                        height: lineHeight * 1.1
                    )
                ))
            }
        }
        
        return decorations
    }
}

// MARK: - TextDecoration
struct TextDecoration {
    enum DecorationType {
        case horizontalRule
        case blockquoteLine(level: Int)
        case listMarker(String)
    }
    
    let type: DecorationType
    let frame: CGRect
}
