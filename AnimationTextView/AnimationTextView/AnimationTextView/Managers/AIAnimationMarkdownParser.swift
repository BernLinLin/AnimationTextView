//
//  AIAnimationMarkdownParser.swift
//  HLHS
//
//  Created by Bern on 2025/8/12.
//

import Foundation

class AIAnimationMarkdownParser {
    func parse(text: String) -> [AIAnimationTextParsedItem] {
        var items: [AIAnimationTextParsedItem] = []
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
        var inCodeBlock = false
        let hrRegex = try! NSRegularExpression(pattern: #"^ {0,3}([-*_])( *\1){2,}\s*$"#)
        let linkRegex = try! NSRegularExpression(pattern: #"\!*\[([^\]]+)\]\(([^)]+)\)"#)

        for (lineIndex, line) in lines.enumerated() {
            if hrRegex.firstMatch(in: String(line), options: [], range: NSRange(location: 0, length: line.utf16.count)) != nil {
                items.append(AIAnimationTextParsedItem(type: .horizontalRule))
                if lineIndex < lines.count - 1 {
                    items.append(AIAnimationTextParsedItem(char: "\n"))
                }
                continue
            }
            
            if line.starts(with: "```") {
                inCodeBlock.toggle()
                continue
            }
            
            var baseAttributes = AIAnimationTextParsedItem.Attributes()
            baseAttributes.isCode = inCodeBlock
            let content = parseBlockAttributes(from: Substring(line), attributes: &baseAttributes)
            
            var lastIndex = content.startIndex
            let fullRange = NSRange(content.startIndex..<content.endIndex, in: content)
            
            linkRegex.enumerateMatches(in: String(content), options: [], range: fullRange) { (match, _, _) in
                guard let match = match,
                      let matchRange = Range(match.range, in: content),
                      let textRange = Range(match.range(at: 1), in: content),
                      let urlRange = Range(match.range(at: 2), in: content) else { return }
                
                items.append(contentsOf: parseInline(content[lastIndex..<matchRange.lowerBound], baseAttributes: baseAttributes))
                
                var linkAttributes = baseAttributes
                linkAttributes.linkURL = String(content[urlRange])
                items.append(contentsOf: parseInline(content[textRange], baseAttributes: linkAttributes))
                
                lastIndex = matchRange.upperBound
            }
            
            items.append(contentsOf: parseInline(content[lastIndex..<content.endIndex], baseAttributes: baseAttributes))
            
            if lineIndex < lines.count - 1 {
                items.append(AIAnimationTextParsedItem(char: "\n", attributes: .init()))
            }
        }
        return items
    }
    
    private func parseBlockAttributes(from content: Substring, attributes: inout AIAnimationTextParsedItem.Attributes) -> Substring {
        var remainingContent = content
        var headingLevel = 0
        var tempContent = remainingContent
        
        while tempContent.starts(with: "#") {
            headingLevel += 1
            tempContent = tempContent.dropFirst()
        }
        
        if headingLevel > 0 && tempContent.starts(with: " ") {
            attributes.headingLevel = headingLevel
            remainingContent = tempContent.dropFirst()
        }
        
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
            }
            else if char.isWhitespace {
                consumed += 1
            } else {
                break
            }
        }
        
        attributes.blockquoteLevel = blockLevel
        remainingContent = tempContent.dropFirst(consumed)
        
        if let markerRange = remainingContent.range(of: #"^(\*|-|\d+\.)\s+"#, options: .regularExpression) {
            let markerText = String(remainingContent[markerRange]).trimmingCharacters(in: .whitespaces)
            
            if markerText == "*" || markerText == "-" {
                attributes.listMarker = "•"
            } else {
                attributes.listMarker = markerText
            }
            
            remainingContent = remainingContent.suffix(from: markerRange.upperBound)
            attributes.listLevel = (consumed / 4) + 1
        }
        
        return remainingContent
    }
    
    private func parseInline(_ content: Substring, baseAttributes: AIAnimationTextParsedItem.Attributes) -> [AIAnimationTextParsedItem] {
        var items: [AIAnimationTextParsedItem] = []
        var inlineAttributes = baseAttributes
        var i = content.startIndex
        
        while i < content.endIndex {
            let twoCharPrefix = content[i...].prefix(2)
            let oneChar = content[i]

            if twoCharPrefix == "**" {
                inlineAttributes.isBold.toggle()
                i = content.index(i, offsetBy: 2)
                continue
            }
            
            if twoCharPrefix == "~~" {
                inlineAttributes.isStrikethrough.toggle()
                i = content.index(i, offsetBy: 2)
                continue
            }
            
            if oneChar == "*" {
                inlineAttributes.isItalic.toggle()
                i = content.index(i, offsetBy: 1)
                continue
            }
            
            if oneChar == "`" {
                inlineAttributes.isCode.toggle()
                i = content.index(i, offsetBy: 1)
                continue
            }
            
            items.append(AIAnimationTextParsedItem(char: oneChar, attributes: inlineAttributes))
            i = content.index(after: i)
        }
        return items
    }
}
