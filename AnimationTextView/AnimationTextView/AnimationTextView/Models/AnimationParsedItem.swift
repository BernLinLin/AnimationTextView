//
//  AnimationParsedItem.swift
//  AnimationTextView
//
//  Created by Bern on 2025/8/10.
//

import Foundation
import UIKit

// MARK: - ParsedItem
struct AnimationParsedItem: Equatable, Identifiable {
    let id = UUID()
    var text: String?  // Single character for text type
    var attributes: TextAttributes
    var type: ItemType = .text
    
    enum ItemType: Equatable {
        case text           // Single character
        case horizontalRule
    }
    
    static func == (lhs: AnimationParsedItem, rhs: AnimationParsedItem) -> Bool {
        return lhs.text == rhs.text &&
               lhs.attributes == rhs.attributes &&
               lhs.type == rhs.type
    }
}

// MARK: - TextAttributes
struct TextAttributes: Equatable, Hashable {
    var font: UIFont = .systemFont(ofSize: 16)
    var color: UIColor = .label
    var backgroundColor: UIColor = .clear
    var style: TextStyle = []
    var headingLevel: Int = 0
    var blockquoteLevel: Int = 0
    var listLevel: Int = 0
    var link: URL?
    var alignment: NSTextAlignment = .left
    
    struct TextStyle: OptionSet, Hashable {
        let rawValue: Int
        
        static let bold = TextStyle(rawValue: 1 << 0)
        static let italic = TextStyle(rawValue: 1 << 1)
        static let strikethrough = TextStyle(rawValue: 1 << 2)
        static let code = TextStyle(rawValue: 1 << 3)
        static let underline = TextStyle(rawValue: 1 << 4)
    }
    
    var dictionary: [NSAttributedString.Key: Any] {
        var attrs: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: color,
            .backgroundColor: backgroundColor
        ]
        
        if style.contains(.strikethrough) {
            attrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        }
        
        if style.contains(.underline) {
            attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        
        if let link = link {
            attrs[.link] = link
            attrs[.foregroundColor] = UIColor.systemBlue
            attrs[.underlineStyle] = NSUnderlineStyle.single.rawValue
        }
        
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = alignment
        attrs[.paragraphStyle] = paragraphStyle
        
        return attrs
    }
}

// MARK: - TextChunk
struct TextChunk: Identifiable {
    let id = UUID()
    let text: String
    let attributes: TextAttributes
    var frame: CGRect = .zero
    
    var attributedString: NSAttributedString {
        return NSAttributedString(string: text, attributes: attributes.dictionary)
    }
    
    func size(constrainedTo width: CGFloat) -> CGSize {
        let constraintRect = CGSize(width: width, height: .greatestFiniteMagnitude)
        let boundingBox = attributedString.boundingRect(
            with: constraintRect,
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        )
        return boundingBox.size
    }
}
