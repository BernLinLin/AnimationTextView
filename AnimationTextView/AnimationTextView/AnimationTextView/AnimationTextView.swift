//
//  AnimationTextView.swift
//  AnimationTextView
//
//  Created by Bern on 2025/8/10.
//
/*
 这里的主要流程为
 使用CATextLayer 遍历出每个文本，及每个文字都是一个CATextLayer，
 1、这里需要计算文本累计判断是否满足Markdown格式
 2、需为每一个 CATextLayer添加动效，
 动画效果为（主主要三个）：
     1、不透明度动画: 从 0.0 (透明) 到 1.0 (不透明)
     2、缩放动画: 从 0.5 倍大小到 1.0 倍 (正常大小)
     3、阴影半径动画：从一个较大的半径变为 0 (无阴影)
 这里如果使用 Text或者UIKit 在大篇文本的情况都会造成内存爆增 如果后面有其他方案任可以优化，或者从其他算法纬度优化展示逻辑
 
 */


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
