//
//  AIAnimationTextView.swift
//  HLHS
//
//  Created by Bern on 2025/8/12.
//

import SwiftUI
import UIKit

struct AIAnimationTextView: UIViewRepresentable {
    let text: String
    let theme: AIAnimationTextStyleTheme
    var menuType: AIAnimationMenuType = .system
    var onLinkTapped: ((URL) -> Void)? = nil
    var onIntelligentRecognition: ((String) -> Void)? = nil
    
    class Coordinator {
        var previousParsedItems: [AIAnimationTextParsedItem] = []
        var lastText: String?
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator()
    }

    func makeUIView(context: Context) -> AIAnimationTextUIView {
        let uiView = AIAnimationTextUIView()
        uiView.theme = theme
        uiView.menuType = menuType
        uiView.onLinkTapped = onLinkTapped
        uiView.onIntelligentRecognition = onIntelligentRecognition
        return uiView
    }

    func updateUIView(_ uiView: AIAnimationTextUIView, context: Context) {
        if context.coordinator.lastText == text {
            return
        }
        
        context.coordinator.lastText = text
        uiView.theme = theme
        uiView.onLinkTapped = onLinkTapped
        uiView.onIntelligentRecognition = onIntelligentRecognition
        uiView.updateText(
            newText: text,
            previousItems: &context.coordinator.previousParsedItems
        )
    }
}
