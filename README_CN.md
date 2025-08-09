# AnimationTextView

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS-blue.svg?style=flat" alt="Platform iOS" />
  <img src="https://img.shields.io/badge/Swift-5.0-orange.svg?style=flat" alt="Swift 5.0" />
  <img src="https://img.shields.io/badge/iOS-15.0%2B-blue.svg?style=flat" alt="iOS 15.0+" />
  <img src="https://img.shields.io/badge/license-MIT-green.svg?style=flat" alt="License MIT" />
</p>

一个功能强大且可自定义的 iOS 动画文本视图，支持 Markdown 渲染和逐字符动画效果。非常适合创建引人入胜的阅读体验、交互式教程或动态内容展示。

[English Version](README.md)

## ✨ 特性

- 🎯 **逐字符动画** - 每个字符都带有流畅的动画效果
- 📝 **完整的 Markdown 支持** - 标题、粗体、斜体、链接、代码块、引用等
- 🎨 **高度可定制的主题** - 多种内置主题，轻松自定义
- 📋 **文本选择** - 长按选择文本，可调节选择手柄
- 🔗 **交互式链接** - 点击处理链接交互
- 📱 **兼容 SwiftUI 和 UIKit** - 与两种框架无缝协作
- ⚡ **高性能** - 优化的渲染和增量更新
- 🎭 **多种动画样式** - 淡入、缩放、打字机、滑入和弹跳效果

## 📸 效果展示

<p align="center">
  <img src="screenshots/demo1.gif" width="250" alt="演示 1" />
  <img src="screenshots/demo2.gif" width="250" alt="演示 2" />
  <img src="screenshots/demo3.gif" width="250" alt="演示 3" />
</p>

## 📦 安装

### 手动安装

1. 下载或克隆此仓库
2. 将 `AnimationTextView` 文件夹拖入你的 Xcode 项目
3. 确保勾选 "Copy items if needed"

### 文件结构

```
AnimationTextView/
├── AnimationTextView.swift                    // SwiftUI 包装视图
├── Extension/
│   └── UIView+Extensions.swift               // UIView 工具扩展
├── Managers/
│   ├── AnimationGestureHandler.swift         // 手势识别和处理
│   ├── AnimationManager.swift                // 动画效果控制
│   ├── AnimationSelectionManager.swift       // 文本选择逻辑
│   └── AnimationTextLayoutManager.swift      // 逐字符布局管理
├── Models/
│   ├── AnimationParsedItem.swift            // 解析后的文本数据模型
│   └── AnimationTextStyleTheme.swift        // 主题和样式配置
├── Parser/
│   ├── LinkDetector.swift                   // URL 检测和验证
│   └── MarkdownParser.swift                 // Markdown 语法解析
└── Views/
    ├── AnimationSelectionHandleView.swift    // 选择手柄 UI
    ├── AnimationStreamTextUIView.swift       // 主 UIView 实现
    └── AnimationTextSelectionView.swift      // 选择覆盖层视图
```

## 🚀 快速开始

### SwiftUI 使用

```swift
import SwiftUI

struct ContentView: View {
    let markdownText = """
    # 欢迎使用 AnimationTextView
    
    这是一个支持**粗体**和*斜体*的文本视图。
    
    - 功能 1
    - 功能 2
    - 功能 3
    
    [访问 GitHub](https://github.com)
    """
    
    var body: some View {
        ScrollView {
            AnimationTextView(
                text: markdownText,
                theme: .default,
                onLinkTapped: { url in
                    // 处理链接点击
                    UIApplication.shared.open(url)
                }
            )
            .padding()
        }
    }
}
```

### UIKit 使用

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
        // 添加约束...
        
        textView.updateText("# 你好世界\n\n这是 **AnimationTextView**！")
    }
}
```

## 📝 支持的 Markdown 语法

- **标题** - `# H1` 到 `###### H6`
- **强调** - `**粗体**`、`*斜体*`、`~~删除线~~`
- **链接** - `[文本](url)`
- **代码** - `` `行内代码` `` 和代码块
- **引用** - `> 引用文本`
- **列表** - `- 项目` 或 `1. 项目`
- **分隔线** - `---`

## 📋 文本选择

- **长按**开始选择
- **拖动**调整选择范围
- **手柄**精确调节选择
- 支持**复制**功能和系统菜单
- 自动检测和处理滚动视图

## 🤖 AI 流式输出

AnimationTextView 非常适合用于展示 AI 生成的内容，逐字符动画效果完美模拟了 AI 模型的输出方式，创造出引人入胜的用户体验。

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
        // 添加约束...
    }
    
    func startAIStreaming() {
        // 模拟 AI 流式响应
        streamAIResponse { chunk in
            DispatchQueue.main.async {
                self.streamedText += chunk
                self.textView.updateText(self.streamedText)
            }
        }
    }
}
```

## 🤝 贡献

欢迎贡献代码！请随时提交 Pull Request。

1. Fork 此项目
2. 创建你的功能分支 (`git checkout -b feature/AmazingFeature`)
3. 提交你的更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启一个 Pull Request

## 📄 许可证

此项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 👏 致谢

- 受多个文本动画库启发
- Markdown 解析基于 CommonMark 规范
- 使用 Swift 用 ❤️ 构建

### 关于 iOS 18+ TextRenderer 的说明

iOS 18 在 SwiftUI 中引入了新的 `TextRenderer` API，可以实现类似的逐字符动画效果：

```swift
// 仅支持 iOS 18+
Text("Hello, World!")
    .textRenderer(AnimatedTextRenderer())
```

然而，AnimationTextView 的设计目标是支持更广泛的设备（iOS 15+），让更多用户能够使用。我们的实现提供了：

- ✅ **更广泛的兼容性** - 支持 iOS 15+ 而不仅仅是 iOS 18+
- ✅ **更多控制** - 完全自定义动画时序和效果
- ✅ **UIKit 支持** - 不局限于 SwiftUI
- ✅ **高级功能** - 文本选择、自定义主题等更多特性

如果您的应用专门针对 iOS 18+，可以考虑使用原生的 `TextRenderer`。但如果需要更广泛的设备支持和更多功能，AnimationTextView 是更好的选择。
