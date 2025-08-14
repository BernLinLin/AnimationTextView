//
//  AIAnimationTextLayoutManager.swift
//  HLHS
//
//  Created by Bern on 2025/8/12.
//

import Foundation
import UIKit

class AIAnimationTextLayoutManager {
    private(set) var characterFrames: [CGRect] = []
    private(set) var calculatedHeight: CGFloat = 0
    
    func layoutText(
        parsedItems: [AIAnimationTextParsedItem],
        characterLayers: [CATextLayer],
        decorationLayers: inout [CALayer],
        in view: UIView,
        theme: AIAnimationTextStyleTheme
    ) {
        characterFrames.removeAll()
        
        var currentY: CGFloat = 0
        let indentSize: CGFloat = 25.0
        let lines = splitIntoLines(items: parsedItems)
        var charLayerIndex = 0

        for line in lines {
            var currentX: CGFloat = 0
            var maxLineHeight: CGFloat = theme.font.lineHeight
            
            guard let firstItem = line.first else {
                currentY += maxLineHeight * theme.lineSpace + theme.lineBreakSpace
                continue
            }
            
            if firstItem.type == .horizontalRule {
                currentY += maxLineHeight * 0.6
                let ruleLayer = createRuleLayer(at: currentY, width: view.bounds.width, theme: theme)
                view.layer.addSublayer(ruleLayer)
                decorationLayers.append(ruleLayer)
                currentY += maxLineHeight * 0.6
                continue
            }
            
            let attributes = firstItem.attributes
            let lineIndent = CGFloat(attributes.blockquoteLevel + attributes.listLevel) * indentSize
            currentX = lineIndent
            
            drawDecorations(
                for: attributes,
                at: currentY,
                indent: lineIndent,
                isNewLine: true,
                in: view,
                decorationLayers: &decorationLayers,
                theme: theme
            )
            
            for item in line {
                guard item.type == .character, let char = item.char, char != "\n" else { continue }
                guard charLayerIndex < characterLayers.count else { break }
                
                let currentLayer = characterLayers[charLayerIndex]
                guard let attrString = currentLayer.string as? NSAttributedString,
                      attrString.length > 0 else {
                    charLayerIndex += 1
                    continue
                }
                
                let stringAttrs = attrString.attributes(at: 0, effectiveRange: nil)
                let charSize = (attrString.string as NSString).size(withAttributes: stringAttrs)
                
                if currentX + charSize.width > view.bounds.width && currentX > lineIndent {
                    currentY += maxLineHeight * theme.lineSpace
                    currentX = lineIndent
                    maxLineHeight = theme.font.lineHeight
                }
                
                let frame = CGRect(x: currentX, y: currentY, width: charSize.width, height: charSize.height)
                currentLayer.frame = frame
                characterFrames.append(frame)
                
                currentX += charSize.width
                maxLineHeight = max(maxLineHeight, charSize.height)
                charLayerIndex += 1
            }
            
            currentY += maxLineHeight * theme.lineSpace
            currentY += theme.lineBreakSpace
            
            if let firstItem = line.first, firstItem.attributes.headingLevel > 0 {
                currentY += theme.headingSpacing
            }
        }
        
        calculatedHeight = currentY
    }
    
    private func splitIntoLines(items: [AIAnimationTextParsedItem]) -> [[AIAnimationTextParsedItem]] {
        return items.split(whereSeparator: { $0.char == "\n" }).map { Array($0) }
    }
    
    private func createRuleLayer(at y: CGFloat, width: CGFloat, theme: AIAnimationTextStyleTheme) -> CAShapeLayer {
        let ruleLayer = CAShapeLayer()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: y))
        path.addLine(to: CGPoint(x: width, y: y))
        ruleLayer.path = path.cgPath
        ruleLayer.lineWidth = 1.0
        ruleLayer.strokeColor = theme.textColor.withAlphaComponent(0.3).cgColor
        return ruleLayer
    }
    
    private func drawDecorations(
        for attributes: AIAnimationTextParsedItem.Attributes,
        at y: CGFloat,
        indent: CGFloat,
        isNewLine: Bool,
        in view: UIView,
        decorationLayers: inout [CALayer],
        theme: AIAnimationTextStyleTheme
    ) {
        if isNewLine, let marker = attributes.listMarker {
            let markerLayer = createMarkerLayer(marker: marker, attributes: attributes, at: y, indent: indent, theme: theme)
            view.layer.addSublayer(markerLayer)
            decorationLayers.append(markerLayer)
        }
        
        if attributes.blockquoteLevel > 0 {
            for i in 1...attributes.blockquoteLevel {
                let quoteLine = createQuoteLine(level: i, at: y, theme: theme)
                view.layer.addSublayer(quoteLine)
                decorationLayers.append(quoteLine)
            }
        }
    }
    
    private func createMarkerLayer(
        marker: String,
        attributes: AIAnimationTextParsedItem.Attributes,
        at y: CGFloat,
        indent: CGFloat,
        theme: AIAnimationTextStyleTheme
    ) -> CATextLayer {
        let markerLayer = CATextLayer()
        let attrString = createAttributedString(for: marker, with: attributes, theme: theme)
        markerLayer.string = attrString
        markerLayer.contentsScale = UIScreen.main.scale
        markerLayer.alignmentMode = .left
        markerLayer.anchorPoint = CGPoint(x: 0, y: 0)
        
        let markerSize = (marker as NSString).size(withAttributes: attrString.attributes(at: 0, effectiveRange: nil))
        markerLayer.frame = CGRect(x: indent - markerSize.width - 5, y: y, width: markerSize.width, height: markerSize.height)
        
        return markerLayer
    }
    
    private func createQuoteLine(level: Int, at y: CGFloat, theme: AIAnimationTextStyleTheme) -> CAShapeLayer {
        let quoteLine = CAShapeLayer()
        let path = UIBezierPath()
        let xPos = (CGFloat(level) * 25.0) - 15.0
        path.move(to: CGPoint(x: xPos, y: y))
        path.addLine(to: CGPoint(x: xPos, y: y + theme.font.lineHeight * 1.1))
        quoteLine.path = path.cgPath
        quoteLine.strokeColor = theme.textColor.withAlphaComponent(0.4).cgColor
        quoteLine.lineWidth = 2.0
        return quoteLine
    }
    
    private func createAttributedString(for text: String, with attributes: AIAnimationTextParsedItem.Attributes, theme: AIAnimationTextStyleTheme) -> NSAttributedString {
        var finalFont: UIFont = theme.font
        
        if attributes.headingLevel > 0, let headingFont = theme.headingFonts[attributes.headingLevel] {
            finalFont = headingFont
        } else if attributes.isBold, let boldFont = theme.boldFont {
            finalFont = boldFont
        } else if attributes.isItalic, let italicFont = theme.italicFont {
            finalFont = italicFont
        } else if attributes.isCode, let codeFont = theme.codeFont {
            finalFont = codeFont
        }
        
        let stringAttributes: [NSAttributedString.Key: Any] = [
            .font: finalFont,
            .foregroundColor: theme.textColor,
            .kern: theme.characterSpace
        ]
        
        return NSAttributedString(string: text, attributes: stringAttributes)
    }
}
