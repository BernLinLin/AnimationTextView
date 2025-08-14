//
//  AIAnimationTextViewModel.swift
//  HLHS
//
//  Created by Bern on 2025/8/12.
//

import Foundation

class AIAnimationTextViewModel: ObservableObject {
    @Published var text: String = ""
    @Published var theme: AIAnimationTextStyleTheme = AIAnimationTextStyleTheme()
    @Published var parsedItems: [AIAnimationTextParsedItem] = []
    @Published var selectedRange: NSRange?
    
    private let parser = AIAnimationMarkdownParser()
    
    func updateText(_ newText: String) {
        text = newText
        parsedItems = parser.parse(text: newText)
    }
    
    func getSelectedText() -> String? {
        guard let range = selectedRange else { return nil }
        
        var selectedText = ""
        var charIndex = 0
        
        for item in parsedItems {
            if item.type == .character, let char = item.char, char != "\n" {
                if charIndex >= range.location && charIndex < range.location + range.length {
                    selectedText.append(char)
                }
                charIndex += 1
            } else if item.char == "\n" && charIndex >= range.location && charIndex < range.location + range.length {
                selectedText.append("\n")
            }
        }
        
        return selectedText.isEmpty ? nil : selectedText
    }
}
