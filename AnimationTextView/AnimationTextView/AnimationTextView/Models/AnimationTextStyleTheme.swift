//
//  AnimationTextStyleTheme.swift
//  AnimationTextView
//
//  Created by Bern on 2025/8/10.
//

import Foundation
import UIKit

struct AnimationTextStyleTheme {
    // MARK: - Basic Properties
    var characterSpace: CGFloat = 0
    var lineSpace: CGFloat = 1.5
    var paragraphSpace: CGFloat = 8
    var font: UIFont = .systemFont(ofSize: 16)
    var textColor: UIColor = .label
    var backgroundColor: UIColor = .clear
  
    // MARK: - Special Fonts
    var headingFonts: [Int: UIFont] = [:]
    var boldFont: UIFont?
    var italicFont: UIFont?
    var codeFont: UIFont?
    var quoteFont: UIFont?
  
    // MARK: - Styles
    var linkStyle = LinkStyle()
    var codeStyle = CodeStyle()
    var quoteStyle = QuoteStyle()
    var listStyle = ListStyle()
  
    // MARK: - Animation
    var animationDuration: TimeInterval = 0.35
    var animationDelay: TimeInterval = 0.02
    var animationType: AnimationType = .fadeInScale
  
    // MARK: - Nested Types
    struct LinkStyle {
        var color: UIColor = .systemBlue
        var font: UIFont?
        var underline: Bool = true
    }
  
    struct CodeStyle {
        var font: UIFont = .monospacedSystemFont(ofSize: 14, weight: .regular)
        var textColor: UIColor = .systemPink
        var backgroundColor: UIColor = .secondarySystemBackground
        var cornerRadius: CGFloat = 4
        var padding: UIEdgeInsets = UIEdgeInsets(top: 2, left: 4, bottom: 2, right: 4)
    }
  
    struct QuoteStyle {
        var borderColor: UIColor = .systemGray3
        var borderWidth: CGFloat = 3
        var leftInset: CGFloat = 16
        var textColor: UIColor = .secondaryLabel
        var backgroundColor: UIColor = .secondarySystemBackground.withAlphaComponent(0.3)
    }
  
    struct ListStyle {
        var bulletColor: UIColor = .label
        var bulletSize: CGFloat = 6
        var indentSize: CGFloat = 24
        var bulletType: BulletType = .disc
      
        enum BulletType {
            case disc
            case circle
            case square
            case decimal
            case custom(String)
            
            var marker: String {
                switch self {
                case .disc: return "•"
                case .circle: return "◦"
                case .square: return "▪"
                case .decimal: return "1."
                case .custom(let marker): return marker
                }
            }
        }
    }
  
    enum AnimationType {
        case fadeIn
        case fadeInScale
        case typewriter
        case slideIn
        case bounce
    }
  
     // MARK: - Factory Methods
    static var `default`: AnimationTextStyleTheme {
        var theme = AnimationTextStyleTheme()
        theme.setupDefaultFonts()
        return theme
    }
  
    static var dark: AnimationTextStyleTheme {
        var theme = AnimationTextStyleTheme()
        theme.textColor = .white
        theme.backgroundColor = .black
        theme.linkStyle.color = .systemCyan
        theme.codeStyle.backgroundColor = UIColor(white: 0.1, alpha: 1)
        theme.setupDefaultFonts()
        return theme
    }
  
    // MARK: - Setup Methods
    mutating func setupDefaultFonts() {
        // Heading fonts with rounded design
        for level in 1...6 {
            let size = CGFloat(28 - (level * 2))
            headingFonts[level] = roundedSystemFont(ofSize: size, weight: .bold)
        }
      
        // Special fonts
        boldFont = roundedSystemFont(ofSize: font.pointSize, weight: .bold)
        italicFont = font.italic()
        codeFont = codeStyle.font
    }
  
    func roundedSystemFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return systemFont
    }
}

// MARK: - UIFont Extensions
extension UIFont {
    func italic() -> UIFont {
        if let descriptor = fontDescriptor.withSymbolicTraits(.traitItalic) {
            return UIFont(descriptor: descriptor, size: pointSize)
        }
        return self
    }

    func bold() -> UIFont {
        if let descriptor = fontDescriptor.withSymbolicTraits(.traitBold) {
            return UIFont(descriptor: descriptor, size: pointSize)
        }
        return self
    }
}
