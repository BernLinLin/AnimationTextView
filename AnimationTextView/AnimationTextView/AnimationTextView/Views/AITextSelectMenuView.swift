//
//  AITextSelectMenu.swift
//  HLHS
//
//  Created by Bern on 2025/8/12.
//

import UIKit

class AITextSelectMenu: UIView {
    struct MenuItem {
        let icon: String
        let title: String?
        let action: () -> Void
    }
    
    private var stackView: UIStackView!
    private var containerView: UIView!
    private var items: [MenuItem] = []
    private var arrowImageView: UIImageView! // 使用图片视图
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        // 容器视图
        containerView = UIView()
        containerView.backgroundColor = .systemBackground
        containerView.layer.cornerRadius = 12
        containerView.clipsToBounds = true
        addSubview(containerView)
        
        // 创建箭头图片视图
        arrowImageView = UIImageView()
        arrowImageView.contentMode = .center
        addSubview(arrowImageView)
        
        // 为整个视图添加阴影
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 6)
        layer.shadowRadius = 15
        layer.shadowOpacity = 0.3
        layer.masksToBounds = false
        
        // 堆栈视图
        stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .equalSpacing // 改为 equalSpacing
        stackView.alignment = .center
        stackView.spacing = 20 // 设置按钮之间的间距
        containerView.addSubview(stackView)
        
        // 布局
        containerView.translatesAutoresizingMaskIntoConstraints = false
        stackView.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            containerView.topAnchor.constraint(equalTo: topAnchor),
            containerView.centerXAnchor.constraint(equalTo: centerXAnchor), // 居中
            containerView.widthAnchor.constraint(equalToConstant: 144),
            containerView.heightAnchor.constraint(equalToConstant: 58),
            
            stackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 12),
            stackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -12),
            stackView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor)
        ])
    }
    
    private func createArrowImage(pointingUp: Bool) -> UIImage? {
        let size = CGSize(width: 20, height: 10)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let _ = UIGraphicsGetCurrentContext() else { return nil }
        
        // 设置颜色为系统背景色
        UIColor.systemBackground.setFill()
        
        let path = UIBezierPath()
        if pointingUp {
            // 箭头指向上方
            path.move(to: CGPoint(x: 0, y: 10))
            path.addLine(to: CGPoint(x: 10, y: 0))
            path.addLine(to: CGPoint(x: 20, y: 10))
        } else {
            // 箭头指向下方
            path.move(to: CGPoint(x: 0, y: 0))
            path.addLine(to: CGPoint(x: 10, y: 10))
            path.addLine(to: CGPoint(x: 20, y: 0))
        }
        path.close()
        path.fill()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return image
    }
    
    private func updateArrow(pointingTo targetX: CGFloat, isPointingUp: Bool) {
        // 设置箭头图片
        arrowImageView.image = createArrowImage(pointingUp: isPointingUp)
        
        // 设置箭头位置
        if isPointingUp {
            // 菜单在下方，箭头在顶部
            arrowImageView.frame = CGRect(x: targetX - 10, y: -10, width: 20, height: 10)
        } else {
            // 菜单在上方，箭头在底部
            arrowImageView.frame = CGRect(x: targetX - 10, y: 58, width: 20, height: 10)
        }
    }
    
    func setMenuItems(_ items: [MenuItem]) {
        self.items = items
        
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for (_, item) in items.enumerated() {
            let button = createMenuButton(item: item)
            stackView.addArrangedSubview(button)
        }
    }
    
    private func createMenuButton(item: MenuItem) -> UIButton {
        let button = UIButton(type: .system)
        button.tintColor = .label
        
        var config = UIButton.Configuration.plain()

        let customImage = UIImage(named: item.icon)?.withRenderingMode(.alwaysTemplate)
        config.image = customImage
        
        // 检查标题是否存在且不为空
        if let title = item.title, !title.isEmpty {
            config.imagePlacement = .top
            config.imagePadding = 4
            config.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 4, bottom: 4, trailing: 4)
            
            config.attributedTitle = AttributedString(title, attributes: AttributeContainer([
                .font: UIFont.systemFont(ofSize: 12),
                .foregroundColor: UIColor.label
            ]))
            
        } else {
            config.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0)
        }
        
        button.configuration = config
        
        // 设置按钮的固定大小
        button.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 50),
            button.heightAnchor.constraint(equalToConstant: 50)
        ])

        button.addAction(UIAction { _ in
            item.action()
            self.hide()
        }, for: .touchUpInside)
        
        return button
    }
    
    func showWithFallback(from view: UIView, primaryRect: CGRect, fallbackRect: CGRect) {
        guard let window = view.window else { return }
        
        window.addSubview(self)
        
        // 固定菜单宽度
        let totalWidth: CGFloat = 144
        let menuHeight: CGFloat = 68 // 58 + 10 为箭头留空间
        let margin: CGFloat = 15
        
        // 转换坐标到window
        let convertedPrimaryRect = view.convert(primaryRect, to: window)
        let convertedFallbackRect = view.convert(fallbackRect, to: window)
        
        var x: CGFloat
        var y: CGFloat
        var useBottomPosition = false
        var targetX: CGFloat = 0
        
        // 先尝试在第一行上方显示
        y = convertedPrimaryRect.minY - menuHeight - margin
        
        // 检查上方是否有足够空间
        if y < window.safeAreaInsets.top + 10 {
            // 上方空间不足，改为在最后一行下方显示
            y = convertedFallbackRect.maxY + margin + 5
            useBottomPosition = true
        }
        
        // 计算 x 坐标和箭头位置
        if useBottomPosition {
            // 菜单在下方，箭头应该指向最后一行的末尾
            // 优先让箭头指向选中文本的右端
            let idealArrowX = convertedFallbackRect.maxX
            
            // 计算菜单的理想位置（让箭头在中间位置）
            x = idealArrowX - totalWidth / 2
            
            // 如果菜单会超出屏幕，调整位置
            if x < 10 {
                x = 10
                targetX = idealArrowX - x // 箭头相对于菜单的位置
            } else if x + totalWidth > window.bounds.width - 10 {
                x = window.bounds.width - totalWidth - 10
                targetX = idealArrowX - x // 箭头相对于菜单的位置
            } else {
                targetX = totalWidth / 2 // 箭头在菜单中间
            }
            
            // 确保箭头在菜单范围内
            targetX = max(15, min(targetX, totalWidth - 15))
            
        } else {
            // 菜单在上方，箭头指向第一行的开始位置
            let idealArrowX = convertedPrimaryRect.minX
            
            // 计算菜单的理想位置
            x = idealArrowX - totalWidth / 2
            
            // 如果菜单会超出屏幕，调整位置
            if x < 10 {
                x = 10
                targetX = idealArrowX - x
            } else if x + totalWidth > window.bounds.width - 10 {
                x = window.bounds.width - totalWidth - 10
                targetX = idealArrowX - x
            } else {
                targetX = totalWidth / 2
            }
            
            // 确保箭头在菜单范围内
            targetX = max(15, min(targetX, totalWidth - 15))
        }
        
        // 确保底部显示时不超出屏幕
        if useBottomPosition && y + menuHeight > window.bounds.height - window.safeAreaInsets.bottom - 10 {
            y = convertedPrimaryRect.minY - menuHeight - margin
            useBottomPosition = false
            
            // 重新计算箭头位置（改为上方显示）
            let idealArrowX = convertedPrimaryRect.minX
            x = idealArrowX - totalWidth / 2
            
            if x < 10 {
                x = 10
                targetX = idealArrowX - x
            } else if x + totalWidth > window.bounds.width - 10 {
                x = window.bounds.width - totalWidth - 10
                targetX = idealArrowX - x
            } else {
                targetX = totalWidth / 2
            }
            
            targetX = max(15, min(targetX, totalWidth - 15))
        }
        
        frame = CGRect(x: x, y: y, width: totalWidth, height: menuHeight)
        
        // 更新箭头
        updateArrow(pointingTo: targetX, isPointingUp: useBottomPosition)
        
        alpha = 0
        transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
        
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            self.alpha = 1
            self.transform = .identity
        }
    }
    
    func show(from view: UIView, at rect: CGRect) {
        showWithFallback(from: view, primaryRect: rect, fallbackRect: rect)
    }
    
    func hide() {
        UIView.animate(withDuration: 0.15, animations: {
            self.alpha = 0
            self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            self.removeFromSuperview()
        }
    }
}
