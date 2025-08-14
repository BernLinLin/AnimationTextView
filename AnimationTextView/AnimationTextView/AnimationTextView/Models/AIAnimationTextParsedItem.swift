//
//  AIAnimationTextParsedItem.swift
//  HLHS
//
//  Created by Bern on 2025/8/12.
//

import Foundation

struct AIAnimationTextParsedItem: Equatable {
    var char: Character? = nil
    var attributes = Attributes()
    var type: ItemType = .character
    
    enum ItemType {
        case character
        case horizontalRule
    }
    
    struct Attributes: Equatable, Hashable {
        var isBold: Bool = false
        var isItalic: Bool = false
        var isStrikethrough: Bool = false
        var isCode: Bool = false
        var headingLevel: Int = 0
        var blockquoteLevel: Int = 0
        var listLevel: Int = 0
        var listMarker: String?
        var linkURL: String?
    }
}

enum AIAnimationTextAlign {
    case left
    case center
    case right
}
