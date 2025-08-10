# AnimationTextView

<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS-blue.svg?style=flat" alt="Platform iOS" />
  <img src="https://img.shields.io/badge/Swift-5.0-orange.svg?style=flat" alt="Swift 5.0" />
  <img src="https://img.shields.io/badge/iOS-15.0%2B-blue.svg?style=flat" alt="iOS 15.0+" />
  <img src="https://img.shields.io/badge/license-MIT-green.svg?style=flat" alt="License MIT" />
</p>

一个功能强大且可自定义的 iOS 动画文本视图，支持 Markdown 渲染和逐字符动画效果。非常适合创建引人入胜的阅读体验、交互式教程或动态内容展示。

[English Version](README.md)

✨ 特性

🎯 逐字符动画 - 每个字符都带有流畅的动画效果
📝 完整 Markdown 支持 - 标题、粗体、斜体、链接、代码块、引用等
🎨 高度可定制主题 - 多种内置主题和简便的主题定制
📋 文本选择 - 长按选择文本，可调节选择范围
🔗 交互式链接 - 点击处理链接交互
📱 SwiftUI & UIKit 兼容 - 与两种框架无缝配合
⚡ 高性能 - 优化渲染，支持增量更新
🎭 多种动画样式 - 淡入、缩放、打字机、滑动和弹跳效果

📸 预览
Show Image
Show Image
📦 安装
手动安装

下载或克隆此仓库
将 AnimationTextView 文件夹拖入您的 Xcode 项目
确保勾选 "Copy items if needed"

文件结构
AnimationTextView/
├── AnimationTextView.swift                    // SwiftUI 包装视图
├── Extension/
│   └── UIView+Extensions.swift               // UIView 实用扩展
├── Managers/
│   ├── AnimationGestureHandler.swift         // 手势识别和处理
│   ├── AnimationManager.swift                // 动画效果控制
│   ├── AnimationSelectionManager.swift       // 文本选择逻辑
│   └── AnimationTextLayoutManager.swift      // 逐字符布局
├── Models/
│   ├── AnimationParsedItem.swift            // 解析文本数据模型
│   └── AnimationTextStyleTheme.swift        // 主题和样式配置
├── Parser/
│   ├── LinkDetector.swift                   // URL 检测和验证
│   └── MarkdownParser.swift                 // Markdown 语法解析
└── Views/
    ├── AnimationSelectionHandleView.swift    // 选择手柄 UI
    ├── AnimationStreamTextUIView.swift       // 主要 UIView 实现
    └── AnimationTextSelectionView.swift      // 选择覆盖视图
🚀 快速开始
SwiftUI 用法
swiftimport SwiftUI

struct ContentView: View {
    let markdownText = """
    # 欢迎使用 AnimationTextView
    
    这是一个支持 **粗体** 和 *斜体* 的文本。
    
    - 特性 1
    - 特性 2
    - 特性 3
    
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
UIKit 用法
swiftimport UIKit

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
📝 支持的 Markdown 语法

标题 - # H1 到 ###### H6
强调 - **粗体**、*斜体*、~~删除线~~
链接 - [文本](url)
代码 - `行内代码` 和代码块
引用 - > 引用块
列表 - - 项目 或 1. 项目
分隔线 - ---

📋 文本选择和复制功能
为什么需要手动实现复制功能？
AnimationTextView 使用 CATextLayer 来实现高性能的逐字符动画渲染。与标准的 UITextView 或 UILabel 不同，CATextLayer 并不提供内置的文本选择和复制功能。因此，我们实现了一个自定义的文本选择系统，在保持流畅动画体验的同时提供必要的文本交互功能。
与原生文本视图的主要区别：

🎨 自定义渲染 - 使用 Core Animation 图层以获得最佳性能
🔧 手动选择 - 自定义实现文本选择逻辑
📋 系统集成 - 与 iOS 复制/粘贴系统无缝集成
⚡ 性能导向 - 在支持文本交互的同时保持 60fps 动画

使用方法

长按 开始选择
拖拽 调整选择范围
手柄 精细调整选择
复制 支持系统菜单
自动检测和处理滚动视图

选择系统自动检测文本边界并提供可自定义选择手柄的视觉反馈，尽管采用了自定义实现，但仍确保原生 iOS 体验。
🤖 AI 流式输出
AnimationTextView 非常适合展示 AI 生成的内容，具有自然的流式效果。逐字符动画模拟了 AI 模型输出文本的方式，创造出引人入胜的用户体验。
swiftclass AIStreamingViewController: UIViewController {
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
🤝 贡献
欢迎贡献！请随时提交 Pull Request。

Fork 项目
创建您的特性分支 (git checkout -b feature/AmazingFeature)
提交您的更改 (git commit -m 'Add some AmazingFeature')
推送到分支 (git push origin feature/AmazingFeature)
打开一个 Pull Request

📄 许可证
此项目基于 MIT 许可证 - 查看 LICENSE 文件了解详情。
👏 致谢

受各种文本动画库启发
Markdown 解析基于 CommonMark 规范
使用 Swift 用 ❤️ 构建

关于 iOS 18+ TextRenderer 的说明
iOS 18 引入了 SwiftUI 中新的 TextRenderer API，可以实现类似的逐字符动画效果：
swift// 仅限 iOS 18+
Text("Hello, World!")
    .textRenderer(AnimatedTextRenderer())
然而，AnimationTextView 旨在支持更广泛的设备（iOS 15+），使更多用户能够使用。我们的实现提供：

✅ 更广泛的兼容性 - 适用于 iOS 15+ 而非 iOS 18+
✅ 更多控制 - 完全自定义动画时间和效果
✅ UIKit 支持 - 不仅限于 SwiftUI
✅ 高级功能 - 文本选择、自定义主题等

如果您的应用专门针对 iOS 18+，您可能会考虑使用原生的 TextRenderer。对于更广泛的设备支持和更多功能，AnimationTextView 是更好的选择。
