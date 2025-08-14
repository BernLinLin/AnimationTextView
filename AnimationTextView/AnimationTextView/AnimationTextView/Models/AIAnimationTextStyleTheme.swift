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
    
    struct LinkStyle {
        var color: UIColor = .blue
        var font: UIFont?
    }
    
    func roundedSystemFont(ofSize size: CGFloat, weight: UIFont.Weight) -> UIFont {
        let systemFont = UIFont.systemFont(ofSize: size, weight: weight)
        if let descriptor = systemFont.fontDescriptor.withDesign(.rounded) {
            return UIFont(descriptor: descriptor, size: size)
        }
        return systemFont
    }
}


