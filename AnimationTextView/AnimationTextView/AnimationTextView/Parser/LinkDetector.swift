//
//  LinkDetector.swift
//  AnimationTextView
//
//  Created by Bern on 2025/8/10.
//

import Foundation

class LinkDetector {
    
    // MARK: - Properties
    private let detector: NSDataDetector?
    
    // MARK: - Initialization
    init() {
        self.detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    }
    
    // MARK: - Public Methods
    func detectLinks(in text: String) -> [LinkInfo] {
        guard let detector = detector else { return [] }
        
        var links: [LinkInfo] = []
        let range = NSRange(location: 0, length: text.utf16.count)
        
        detector.enumerateMatches(in: text, options: [], range: range) { result, _, _ in
            if let result = result,
               let url = result.url,
               let range = Range(result.range, in: text) {
                let linkText = String(text[range])
                links.append(LinkInfo(url: url, text: linkText, range: result.range))
            }
        }
        
        return links
    }
    
    func isValidURL(_ string: String) -> Bool {
        if let url = URL(string: string),
           let scheme = url.scheme,
           ["http", "https", "mailto", "tel"].contains(scheme.lowercased()) {
            return true
        }
        return false
    }
    
    func normalizeURL(_ string: String) -> URL? {
        // If already valid URL, return it
        if let url = URL(string: string) {
            return url
        }
        
        // Try adding https:// prefix
        if !string.contains("://") {
            return URL(string: "https://\(string)")
        }
        
        return nil
    }
}

// MARK: - LinkInfo
struct LinkInfo {
    let url: URL
    let text: String
    let range: NSRange
}
