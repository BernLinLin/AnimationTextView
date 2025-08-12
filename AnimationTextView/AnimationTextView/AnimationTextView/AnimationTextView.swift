//
//  AnimationTextView.swift
//  AnimationTextView
//
//  Created by Bern on 2025/8/10.
//

import SwiftUI
import UIKit

struct AnimationTextView: UIViewRepresentable {
    let text: String
    var theme: AnimationTextStyleTheme = .default
    var onLinkTapped: ((URL) -> Void)?
    var isSelectable: Bool = true
    var animationEnabled: Bool = true
    
    class Coordinator: NSObject {
        var parent: AnimationTextView
        var previousText: String = ""
        
        init(_ parent: AnimationTextView) {
            self.parent = parent
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(self)
    }
    
    func makeUIView(context: Context) -> AnimationStreamTextUIView {
        let uiView = AnimationStreamTextUIView()
        uiView.theme = theme
        uiView.onLinkTapped = onLinkTapped
        uiView.isSelectable = isSelectable
        uiView.animationEnabled = animationEnabled
        return uiView
    }
    
    func updateUIView(_ uiView: AnimationStreamTextUIView, context: Context) {
        if context.coordinator.previousText != text {
            context.coordinator.previousText = text
            uiView.theme = theme
            uiView.onLinkTapped = onLinkTapped
            uiView.isSelectable = isSelectable
            uiView.animationEnabled = animationEnabled
            uiView.updateText(text)
        }
    }
}

// MARK: - View Modifiers
extension AnimationTextView {
    func textSelection(_ enabled: Bool) -> AnimationTextView {
        var view = self
        view.isSelectable = enabled
        return view
    }
    
    func animationStyle(_ enabled: Bool) -> AnimationTextView {
        var view = self
        view.animationEnabled = enabled
        return view
    }
    
    func onOpenURL(_ action: @escaping (URL) -> Void) -> AnimationTextView {
        var view = self
        view.onLinkTapped = action
        return view
    }
}
