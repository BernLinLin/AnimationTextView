//
//  AIAnimationTextStyleTheme.swift
//  HLHS
//
//  Created by Bern on 2025/8/12.
//

import Foundation
import UIKit

// MARK: - Models

struct AIAnimationTextStyleTheme {
    var characterSpace: CGFloat = 0
    var headingSpacing: CGFloat = 0.0
    var lineSpace: CGFloat = 2.0
    var lineBreakSpace: CGFloat = 2.0
    var font: UIFont = .systemFont(ofSize: 16)
    var textColor: UIColor = .label
    var headingFonts: [Int: UIFont] = [:]
    var boldFont: UIFont?
    var italicFont: UIFont?
    var codeFont: UIFont?
    
    var linkStyle = LinkStyle()
    var codeStyle = CodeStyle()
    var quoteStyle = QuoteStyle()
    var listStyle = ListStyle()
    
    struct LinkStyle {
        var color: UIColor = .blue
        var font: UIFont?
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
    
    func roundedSystemFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return systemFont
    }
}


