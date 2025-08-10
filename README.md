# AnimationTextView

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS-blue.svg?style=flat" alt="Platform iOS" />
  <img src="https://img.shields.io/badge/Swift-5.0-orange.svg?style=flat" alt="Swift 5.0" />
  <img src="https://img.shields.io/badge/iOS-15.0%2B-blue.svg?style=flat" alt="iOS 15.0+" />
  <img src="https://img.shields.io/badge/license-MIT-green.svg?style=flat" alt="License MIT" />
</p>

A powerful and customizable animated text view for iOS that supports Markdown rendering with character-by-character animation effects. Perfect for creating engaging reading experiences, interactive tutorials, or dynamic content displays.

[中文版本](README_CN.md)

## ✨ Features

- 🎯 **Character-by-Character Animation** - Each character appears with smooth animation effects
- 📝 **Full Markdown Support** - Headers, bold, italic, links, code blocks, quotes, and more
- 🎨 **Highly Customizable Themes** - Multiple built-in themes and easy theme customization
- 📋 **Text Selection** - Long press to select text with adjustable selection handles
- 🔗 **Interactive Links** - Tap to handle link interactions
- 📱 **SwiftUI & UIKit Compatible** - Works seamlessly with both frameworks
- ⚡ **High Performance** - Optimized rendering with incremental updates
- 🎭 **Multiple Animation Styles** - Fade, scale, typewriter, slide, and bounce effects

## 📸 Screenshots

![Image](https://github.com/user-attachments/assets/4fee3ebf-5c72-4884-ad82-e13b020e4df4)
![Image](https://github.com/user-attachments/assets/3ff8dc23-2e25-4e05-8411-78b6251c1324)

## 📦 Installation

### Manual Installation

1. Download or clone this repository
2. Drag the `AnimationTextView` folder into your Xcode project
3. Make sure to check "Copy items if needed"

### File Structure

```
AnimationTextView/
├── AnimationTextView.swift                    // SwiftUI wrapper view
├── Extension/
│   └── UIView+Extensions.swift               // UIView utility extensions
├── Managers/
│   ├── AnimationGestureHandler.swift         // Gesture recognition and handling
│   ├── AnimationManager.swift                // Animation effects control
│   ├── AnimationSelectionManager.swift       // Text selection logic
│   └── AnimationTextLayoutManager.swift      // Character-by-character layout
├── Models/
│   ├── AnimationParsedItem.swift            // Parsed text data model
│   └── AnimationTextStyleTheme.swift        // Theme and style configuration
├── Parser/
│   ├── LinkDetector.swift                   // URL detection and validation
│   └── MarkdownParser.swift                 // Markdown syntax parsing
└── Views/
    ├── AnimationSelectionHandleView.swift    // Selection handle UI
    ├── AnimationStreamTextUIView.swift       // Main UIView implementation
    └── AnimationTextSelectionView.swift      // Selection overlay view
```

## 🚀 Quick Start

### SwiftUI Usage

```swift
import SwiftUI

struct ContentView: View {
    let markdownText = """
    # Welcome to AnimationTextView
    
    This is a **bold** text with *italic* support.
    
    - Feature 1
    - Feature 2
    - Feature 3
    
    [Visit GitHub](https://github.com)
    """
    
    var body: some View {
        ScrollView {
            AnimationTextView(
                text: markdownText,
                theme: .default,
                onLinkTapped: { url in
                    // Handle link tap
                    UIApplication.shared.open(url)
                }
            )
            .padding()
        }
    }
}
```

### UIKit Usage

```swift
import UIKit

class ViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let textView = AnimationStreamTextUIView()
        textView.theme = .modernTech
        textView.onLinkTapped = { url in
            UIApplication.shared.open(url)
        }
        
        view.addSubview(textView)
        // Add constraints...
        
        textView.updateText("# Hello World\n\nThis is **AnimationTextView**!")
    }
}
```

## 📝 Supported Markdown

- **Headers** - `# H1` through `###### H6`
- **Emphasis** - `**bold**`, `*italic*`, `~~strikethrough~~`
- **Links** - `[text](url)`
- **Code** - `` `inline code` `` and code blocks
- **Quotes** - `> blockquote`
- **Lists** - `- item` or `1. item`
- **Horizontal Rules** - `---`

## 📋 Text Selection

- **Long press** to start selection
- **Drag** to adjust selection range
- **Handles** to fine-tune selection
- **Copy** support with system menu
- Automatic scroll view detection and handling

## 🤖 AI Streaming Output

AnimationTextView is perfect for displaying AI-generated content with a natural streaming effect. The character-by-character animation mimics the way AI models output text, creating an engaging user experience.

```swift
class AIStreamingViewController: UIViewController {
    let textView = AnimationStreamTextUIView()
    var streamedText = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTextView()
        startAIStreaming()
    }
    
    func setupTextView() {
        textView.theme = .modernTech
        textView.animationEnabled = true
        view.addSubview(textView)
        // Add constraints...
    }
    
    func startAIStreaming() {
        // Simulate AI streaming response
        streamAIResponse { chunk in
            DispatchQueue.main.async {
                self.streamedText += chunk
                self.textView.updateText(self.streamedText)
            }
        }
    }
}
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the project
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 👏 Acknowledgments

- Inspired by various text animation libraries
- Markdown parsing based on CommonMark specification
- Built with ❤️ using Swift

### Note on iOS 18+ TextRenderer

iOS 18 introduces the new `TextRenderer` API in SwiftUI that can achieve similar character-by-character animation effects:

```swift
// iOS 18+ only
Text("Hello, World!")
    .textRenderer(AnimatedTextRenderer())
```

However, AnimationTextView is designed to support a wider range of devices (iOS 15+), making it accessible to more users. Our implementation provides:

- ✅ **Broader Compatibility** - Works on iOS 15+ instead of iOS 18+
- ✅ **More Control** - Full customization of animation timing and effects
- ✅ **UIKit Support** - Not limited to SwiftUI
- ✅ **Advanced Features** - Text selection, custom themes, and more

If your app targets iOS 18+ exclusively, you might consider using the native `TextRenderer`. For broader device support and more features, AnimationTextView is the better choice.
