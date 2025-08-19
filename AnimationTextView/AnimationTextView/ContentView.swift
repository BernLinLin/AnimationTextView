//
//  ContentView.swift
//  AnimationTextView
//
//  Created by Bern on 2025/8/10.
//

import SwiftUI
import UIKit

struct ContentView: View {
    private var animationTheme: AIAnimationTextStyleTheme {
        var theme = AIAnimationTextStyleTheme()
        theme.lineSpace = 1.2
        theme.font = .systemFont(ofSize: 16, weight: .regular)
        theme.textColor = .black
    
        theme.headingFonts[1] = theme.roundedSystemFont(ofSize: 25, weight: .bold)
        theme.headingFonts[2] = theme.roundedSystemFont(ofSize: 25, weight: .bold)
        
        theme.boldFont = .systemFont(ofSize: 16, weight: .semibold)
        theme.italicFont = .italicSystemFont(ofSize: 16)
        
        theme.linkStyle.color = UIColor.systemBlue
        theme.linkStyle.font = .systemFont(ofSize: 16, weight: .semibold)
        
        return theme
    }
    
    @State private var displayText = ""
    
    private let fullMarkdownText = """
            # Welcome to AnimationText
            
            This is a high-performance text animation view built with `CATextLayer`.
            
            ## Key Features
            
            * Supports **bold**, *italic*, `code`, and ~~strikethrough~~.
            * Supports links, for example, [Visit my GitHub](https://github.com/BernLinLin/AnimationTextView.git).
            * Supports unordered lists:
                * List item 1
                * List item 2
            * Supports ordered lists:
                1. First point
                2. Second point
            > This is a blockquote, used to emphasize important information.
            
            ---
            
            Long-press the text to select and copy.
            """
    
    @State private var timer: Timer?
    @State private var currentIndex = 0
    
    var body: some View {
        VStack {
            ScrollView {
                AIAnimationTextView(
                    text: displayText,
                    theme: animationTheme,
                    onLinkTapped: { url in
                        debugPrint("@___click: \(url)")
                    }
                )
                .padding()
            }
            
            Spacer()
            
            HStack(spacing: 20) {
                Button("Start Animation") {
                    startStreaming()
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("Display") {
                    stopStreaming()
                    displayText = fullMarkdownText
                }
                .padding()
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
                
                Button("Clear") {
                    stopStreaming()
                    displayText = ""
                }
                .padding()
                .background(Color.gray)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .padding(.bottom)
        }
    }
}

private extension ContentView {
    func startStreaming() {
       stopStreaming()
       displayText = ""
       currentIndex = 0
       
        timer = Timer.scheduledTimer(withTimeInterval: 0.02, repeats: true) { _ in
           if currentIndex < fullMarkdownText.count {
               let index = fullMarkdownText.index(fullMarkdownText.startIndex, offsetBy: currentIndex)
               displayText.append(fullMarkdownText[index])
               currentIndex += 1
           } else {
               stopStreaming()
           }
       }
   }
       
    func stopStreaming() {
        timer?.invalidate()
        timer = nil
    }
}

#Preview {
    ContentView()
}
