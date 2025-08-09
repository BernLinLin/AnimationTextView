//
//  MarkdownParser.swift
//  AnimationTextView
//
//  Markdown parsing logic - Character by character
//

import Foundation
import UIKit

protocol MarkdownParsing {
    func parse(_ text: String) async -> [AnimationParsedItem]
    func parseSync(_ text: String) -> [AnimationParsedItem]
}

class MarkdownParser: MarkdownParsing {
    
    // MARK: - Properties
    private let theme: AnimationTextStyleTheme
    
    // MARK: - Regular Expressions
    private let hrRegex = try! NSRegularExpression(pattern: #"^ {0,3}([-*_])( *\1){2,}\s*$"#)
    private let linkRegex = try! NSRegularExpression(pattern: #"\!*\[([^\]]+)\]\(([^)]+)\)"#)
    
    // MARK: - Initialization
    init(theme: AnimationTextStyleTheme = .default) {
        self.theme = theme
    }
    
    // MARK: - Public Methods
    func parse(_ text: String) async -> [AnimationParsedItem] {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let items = self.parseSync(text)
                continuation.resume(returning: items)
            }
        }
    }
    
    func parseSync(_ text: String) -> [AnimationParsedItem] {
        var items: [AnimationParsedItem] = []
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        var inCodeBlock = false
        
        for (lineIndex, line) in lines.enumerated() {
            let lineString = String(line)
            
            // Check for horizontal rule
            if hrRegex.firstMatch(in: lineString, options: [], range: NSRange(location: 0, length: lineString.utf16.count)) != nil {
                items.append(AnimationParsedItem(attributes: TextAttributes(), type: .horizontalRule))
                if lineIndex < lines.count - 1 {
                    items.append(AnimationParsedItem(text: "\n", attributes: TextAttributes(), type: .text))
                }
                continue
            }
            
            // Handle code blocks
            if lineString.starts(with: "```") {
                inCodeBlock.toggle()
                continue
            }
            
            // Parse line content
            var baseAttributes = TextAttributes()
            baseAttributes.style = inCodeBlock ? [.code] : []
            
            let content = parseBlockAttributes(from: Substring(line), attributes: &baseAttributes)
            
            // Handle links
            var lastIndex = content.startIndex
            let fullRange = NSRange(content.startIndex..<content.endIndex, in: content)
            
            linkRegex.enumerateMatches(in: String(content), options: [], range: fullRange) { (match, _, _) in
                guard let match = match,
                      let matchRange = Range(match.range, in: content),
                      let textRange = Range(match.range(at: 1), in: content),
                      let urlRange = Range(match.range(at: 2), in: content) else { return }
                
                // Add text before link
                items.append(contentsOf: self.parseInline(content[lastIndex..<matchRange.lowerBound], baseAttributes: baseAttributes))
                
                // Add link text
                var linkAttributes = baseAttributes
                linkAttributes.link = URL(string: String(content[urlRange]))
                linkAttributes.color = self.theme.linkStyle.color
                linkAttributes.style.insert(.underline)
                
                items.append(contentsOf: self.parseInline(content[textRange], baseAttributes: linkAttributes))
                
                lastIndex = matchRange.upperBound
            }
            
            // Add remaining text
            items.append(contentsOf: parseInline(content[lastIndex..<content.endIndex], baseAttributes: baseAttributes))
            
            // Add line break
            if lineIndex < lines.count - 1 {
                items.append(AnimationParsedItem(text: "\n", attributes: TextAttributes(), type: .text))
            }
        }
        
        return items
    }
    
    // MARK: - Private Methods
    private func parseBlockAttributes(from content: Substring, attributes: inout TextAttributes) -> Substring {
        var remainingContent = content
        
        // Headers
        var headingLevel = 0
        var tempContent = remainingContent
        while tempContent.starts(with: "#") {
            headingLevel += 1
            tempContent = tempContent.dropFirst()
        }
        
        if headingLevel > 0 && tempContent.starts(with: " ") {
            attributes.headingLevel = headingLevel
            if let headingFont = theme.headingFonts[headingLevel] {
                attributes.font = headingFont
            }
            remainingContent = tempContent.dropFirst()
        }
        
        // Blockquotes
        var blockLevel = 0
        tempContent = remainingContent
        var consumed = 0
        
        while consumed < tempContent.count {
            let char = tempContent[tempContent.index(tempContent.startIndex, offsetBy: consumed)]
            if char == ">" {
                blockLevel += 1
                consumed += 1
                if tempContent.count > consumed && tempContent[tempContent.index(tempContent.startIndex, offsetBy: consumed)] == " " {
                    consumed += 1
                }
            } else if char.isWhitespace {
                consumed += 1
            } else {
                break
            }
        }
        
        attributes.blockquoteLevel = blockLevel
        if blockLevel > 0 {
            attributes.color = theme.quoteStyle.textColor
        }
        remainingContent = tempContent.dropFirst(consumed)
        
        // Lists
        if let markerRange = remainingContent.range(of: #"^(\*|-|\d+\.)\s+"#, options: .regularExpression) {
            remainingContent = remainingContent.suffix(from: markerRange.upperBound)
            attributes.listLevel = (consumed / 4) + 1
        }
        
        return remainingContent
    }
    
    private func parseInline(_ content: Substring, baseAttributes: TextAttributes) -> [AnimationParsedItem] {
        var items: [AnimationParsedItem] = []
        var currentAttributes = baseAttributes
        var i = content.startIndex
        
        while i < content.endIndex {
            let remaining = content[i...]
            let char = content[i]
            
            // Check for markdown syntax
            if remaining.hasPrefix("**") {
                currentAttributes.style.formSymmetricDifference(.bold)
                currentAttributes.font = currentAttributes.style.contains(.bold) ?
                    (theme.boldFont ?? baseAttributes.font.bold()) : baseAttributes.font
                i = content.index(i, offsetBy: 2)
                continue
            }
            
            if remaining.hasPrefix("~~") {
                currentAttributes.style.formSymmetricDifference(.strikethrough)
                i = content.index(i, offsetBy: 2)
                continue
            }
            
            if char == "*" || char == "_" {
                currentAttributes.style.formSymmetricDifference(.italic)
                currentAttributes.font = currentAttributes.style.contains(.italic) ?
                    (theme.italicFont ?? baseAttributes.font.italic()) : baseAttributes.font
                i = content.index(after: i)
                continue
            }
            
            if char == "`" {
                currentAttributes.style.formSymmetricDifference(.code)
                if currentAttributes.style.contains(.code) {
                    currentAttributes.font = theme.codeFont ?? theme.codeStyle.font
                    currentAttributes.color = theme.codeStyle.textColor
                    currentAttributes.backgroundColor = theme.codeStyle.backgroundColor
                } else {
                    currentAttributes.font = baseAttributes.font
                    currentAttributes.color = baseAttributes.color
                    currentAttributes.backgroundColor = baseAttributes.backgroundColor
                }
                i = content.index(after: i)
                continue
            }
            
            // Add character
            items.append(AnimationParsedItem(
                text: String(char),
                attributes: currentAttributes,
                type: .text
            ))
            
            i = content.index(after: i)
        }
        
        return items
    }
}
