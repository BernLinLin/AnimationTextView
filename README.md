AnimationTextView
<p align="center">
  <img src="https://img.shields.io/badge/platform-iOS-blue.svg?style=flat" alt="Platform iOS" />
  <img src="https://img.shields.io/badge/Swift-5.0-orange.svg?style=flat" alt="Swift 5.0" />
  <img src="https://img.shields.io/badge/iOS-16.0%2B-blue.svg?style=flat" alt="iOS 16.0+" />
  <img src="https://img.shields.io/badge/license-MIT-green.svg?style=flat" alt="License MIT" />
</p>
一个功能强大且可自定义的 iOS 动画文本视图，支持 Markdown 渲染和逐字符动画效果。非常适合创建引人入胜的阅读体验、交互式教程或动态内容展示。
English Version
✨ 特性

🎯 逐字符动画 - 每个字符都带有流畅的动画效果
📝 完整的 Markdown 支持 - 标题、粗体、斜体、链接、代码块、引用等
🎨 高度可定制的主题 - 多种内置主题，轻松自定义
📋 文本选择 - 长按选择文本，可调节选择手柄
🔗 交互式链接 - 点击处理链接交互
📱 兼容 SwiftUI 和 UIKit - 与两种框架无缝协作
⚡ 高性能 - 优化的渲染和增量更新
🎭 多种动画样式 - 淡入、缩放、打字机、滑入和弹跳效果

📸 效果展示
<p align="center">
  <img src="screenshots/demo1.gif" width="250" alt="演示 1" />
  <img src="screenshots/demo2.gif" width="250" alt="演示 2" />
  <img src="screenshots/demo3.gif" width="250" alt="演示 3" />
</p>
📦 安装
手动安装

下载或克隆此仓库
将 AnimationTextView 文件夹拖入你的 Xcode 项目
确保勾选 "Copy items if needed"


🚀 快速开始

SwiftUI 使用

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

UIKit 使用

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
