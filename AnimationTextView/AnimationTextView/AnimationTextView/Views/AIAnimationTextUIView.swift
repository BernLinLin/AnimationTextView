//
//  AIAnimationTextUIView.swift
//  HLHS
//
//  Created by Bern on 2025/8/12.
//

import Foundation
import UIKit

enum AIAnimationMenuType {
    case system      // 系统菜单
    case custom      // 自定义菜单
}

class AIAnimationTextUIView: UIView {
    // MARK: Properties
    var theme = AIAnimationTextStyleTheme()
    var menuType: AIAnimationMenuType = .system
    var onLinkTapped: ((URL) -> Void)?
    var onIntelligentRecognition: ((String) -> Void)? // 添加智能识别回调
    var textAlign: AIAnimationTextAlign = .left
    
    private var viewModel = AIAnimationTextViewModel()
    private let layoutManager = AIAnimationTextLayoutManager()
    private let animationManager = AIAnimationTextAnimationManager()
    private let selectionManager = AIAnimationTextSelectionManager()
    
    private var characterLayers: [CATextLayer] = []
    private var decorationLayers: [CALayer] = []
    private(set) var currentParsedItems: [AIAnimationTextParsedItem] = []
    
    private var calculatedHeight: CGFloat = 0
    private var selectionView: AIAnimationTextSelectionView!
    private var startHandle: AIAnimationSelectionHandleView!
    private var endHandle: AIAnimationSelectionHandleView!
    private var customMenu: AITextSelectMenu?
    
    private var longPressGesture: UILongPressGestureRecognizer!
    private var panGesture: UIPanGestureRecognizer!
    private var tapGesture: UITapGestureRecognizer!
    private weak var parentScrollView: UIScrollView?
    private var scrollViewContentOffsetObserver: NSKeyValueObservation?
    private var scrollDetectorGesture: UIPanGestureRecognizer?
    
    deinit {
        scrollViewContentOffsetObserver?.invalidate()
        if let scrollView = parentScrollView, let gesture = scrollDetectorGesture {
            scrollView.removeGestureRecognizer(gesture)
        }
        hideMenu()
    }
    
    // MARK: Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: calculatedHeight)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        selectionView.frame = bounds
        
        decorationLayers.forEach { $0.removeFromSuperlayer() }
        decorationLayers.removeAll()
        
        layoutManager.layoutText(
            parsedItems: currentParsedItems,
            characterLayers: characterLayers,
            decorationLayers: &decorationLayers,
            in: self,
            theme: theme
        )
        
        let newHeight = layoutManager.calculatedHeight
        if calculatedHeight != newHeight {
            calculatedHeight = newHeight
            invalidateIntrinsicContentSize()
        }
        
        if viewModel.selectedRange != nil {
            updateSelectionView()
        }
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        // 移除旧的手势
        if let oldGesture = scrollDetectorGesture, let scrollView = parentScrollView {
            scrollView.removeGestureRecognizer(oldGesture)
        }
        
        if window != nil {
            DispatchQueue.main.async {
                self.findAndObserveParentScrollView()
            }
        }
    }
}

// MARK: - Public
extension AIAnimationTextUIView {
    func updateText(newText: String, previousItems: inout [AIAnimationTextParsedItem]) {
        viewModel.updateText(newText)
        let newParsedItems = viewModel.parsedItems
        
        let commonPrefixCount = zip(previousItems, newParsedItems).prefix(while: { $0 == $1 }).count
        
        if commonPrefixCount == newParsedItems.count && newParsedItems.count == previousItems.count {
            return
        }

        let itemsToRemove = previousItems.suffix(from: commonPrefixCount)
        let charLayersToRemoveCount = itemsToRemove.filter { $0.type == .character && $0.char != "\n" }.count

        if charLayersToRemoveCount > 0 && characterLayers.count >= charLayersToRemoveCount {
           characterLayers.suffix(charLayersToRemoveCount).forEach { $0.removeFromSuperlayer() }
           characterLayers.removeLast(charLayersToRemoveCount)
        }

        let itemsToAdd = newParsedItems.suffix(from: commonPrefixCount)
        let shouldAnimate = commonPrefixCount > 0
        
        for itemInfo in itemsToAdd {
            if itemInfo.type == .character, let char = itemInfo.char, char != "\n" {
                let characterLayer = createLayer(for: String(char), with: itemInfo.attributes)
                self.layer.addSublayer(characterLayer)
                characterLayers.append(characterLayer)
               
                if shouldAnimate {
                    animationManager.animateFadeInScale(layer: characterLayer)
                }
            }
        }

        previousItems = newParsedItems
        self.currentParsedItems = newParsedItems
        
        clearSelection()
        setNeedsLayout()
    }
}

// MARK: - Setup
private extension AIAnimationTextUIView {
    func setupViews() {
        isUserInteractionEnabled = true
        backgroundColor = .clear
        
        selectionView = AIAnimationTextSelectionView()
        addSubview(selectionView)
        
        startHandle = AIAnimationSelectionHandleView(type: .start)
        startHandle.isHidden = true
        startHandle.isUserInteractionEnabled = true
        addSubview(startHandle)
        
        endHandle = AIAnimationSelectionHandleView(type: .end)
        endHandle.isHidden = true
        endHandle.isUserInteractionEnabled = true
        addSubview(endHandle)
        
        let startHandlePan = UIPanGestureRecognizer(target: self, action: #selector(handleHandlePan(_:)))
        startHandle.addGestureRecognizer(startHandlePan)
        
        let endHandlePan = UIPanGestureRecognizer(target: self, action: #selector(handleHandlePan(_:)))
        endHandle.addGestureRecognizer(endHandlePan)
    }
    
    func setupGestures() {
        longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 0.5
        addGestureRecognizer(longPressGesture)
        
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        addGestureRecognizer(panGesture)
        
        tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }
}

// MARK: - Layer Creation
private extension AIAnimationTextUIView {
    func createLayer(for text: String, with attributes: AIAnimationTextParsedItem.Attributes) -> CATextLayer {
        let characterLayer = CATextLayer()
        let attributedString = createAttributedString(for: text, with: attributes)
        characterLayer.string = attributedString
        characterLayer.contentsScale = UIScreen.main.scale
        characterLayer.alignmentMode = .left
        characterLayer.anchorPoint = CGPoint(x: 0, y: 0)
        return characterLayer
    }

    func createAttributedString(for text: String, with attributes: AIAnimationTextParsedItem.Attributes) -> NSAttributedString {
        var finalFont: UIFont
        
        if attributes.linkURL != nil, let linkFont = theme.linkStyle.font {
            finalFont = linkFont
        }
        else if attributes.headingLevel > 0, let headingFont = theme.headingFonts[attributes.headingLevel] {
            finalFont = headingFont
        }
        else if attributes.isBold, let boldFont = theme.boldFont {
            finalFont = boldFont
        }
        else if attributes.isItalic, let italicFont = theme.italicFont {
            finalFont = italicFont
        }
        else if attributes.isCode, let codeFont = theme.codeFont {
            finalFont = codeFont
        }
        else {
            finalFont = theme.font
        }

        var stringAttributes: [NSAttributedString.Key: Any] = [
            .font: finalFont,
            .kern: theme.characterSpace
        ]
        
        if let linkURL = attributes.linkURL {
            stringAttributes[.foregroundColor] = theme.linkStyle.color
            if let url = URL(string: linkURL) {
                stringAttributes[.link] = url
            }
        } else {
            stringAttributes[.foregroundColor] = theme.textColor
        }
        
        if attributes.isStrikethrough {
            stringAttributes[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
        }
        
        return NSAttributedString(string: text, attributes: stringAttributes)
    }
}

// MARK: - Private
private extension AIAnimationTextUIView {
    // 根据类型显示菜单
    func showMenuBasedOnType() {
       switch menuType {
       case .system:
           showSystemMenu()
       case .custom:
           showCustomMenu()
       }
    }
    
    // 清除选中和选中之后的弹窗
    func clearSelection() {
        if menuType == .custom {
            customMenu?.hide()
            customMenu = nil
        }
        
        if menuType == .system {
            UIMenuController.shared.hideMenu()
        }
        
        resignFirstResponder()
        viewModel.selectedRange = nil
        selectionView.clearSelection()
        startHandle.isHidden = true
        endHandle.isHidden = true
        selectionManager.isSelecting = false
        disableParentScrollView(false)
    }
    
    // 更新 SelectionView
    func updateSelectionView() {
        guard let range = viewModel.selectedRange else {
            selectionView.clearSelection()
            startHandle.isHidden = true
            endHandle.isHidden = true
            return
        }
        
        let rects = selectionManager.getSelectionRects(
            for: range,
            characterFrames: layoutManager.characterFrames
        )
        
        selectionView.updateSelection(rects: selectionManager.mergeRects(rects))
        
        if let firstRect = rects.first {
            startHandle.frame.origin = CGPoint(
                x: firstRect.minX - startHandle.frame.width / 2,
                y: firstRect.minY - 15
            )
            startHandle.isHidden = false
        }
        
        if let lastRect = rects.last {
            endHandle.frame.origin = CGPoint(
                x: lastRect.maxX - endHandle.frame.width / 2,
                y: lastRect.maxY - endHandle.frame.height + 15
            )
            endHandle.isHidden = false
        }
    }
    
    // 查找并观察父 ScrollView
    func findAndObserveParentScrollView() {
        var currentView = self.superview
        while currentView != nil {
            if let scrollView = currentView as? UIScrollView {
                parentScrollView = scrollView
                
                // 创建滚动检测手势
                let scrollDetector = UIPanGestureRecognizer(target: self, action: #selector(detectScrolling(_:)))
                scrollDetector.delegate = self
                scrollDetector.cancelsTouchesInView = false
                scrollDetector.delaysTouchesBegan = false
                scrollDetector.delaysTouchesEnded = false
                scrollView.addGestureRecognizer(scrollDetector)
                scrollDetectorGesture = scrollDetector
                
                break
            }
            currentView = currentView?.superview
        }
    }

    func isSelectionVisible() -> Bool {
        guard let range = viewModel.selectedRange,
              let scrollView = parentScrollView else { return true }
        
        // 获取选中区域的所有矩形
        let selectionRects = selectionManager.getSelectionRects(
            for: range,
            characterFrames: layoutManager.characterFrames
        )
        
        guard !selectionRects.isEmpty else { return false }
        
        // 计算选中区域的边界
        var selectionBounds = selectionRects[0]
        for rect in selectionRects {
            selectionBounds = selectionBounds.union(rect)
        }
        
        // 将选中区域的坐标转换到 scrollView 的坐标系
        let selectionInScrollView = convert(selectionBounds, to: scrollView)
        
        // 获取 scrollView 的可见区域
        let visibleRect = CGRect(
            x: scrollView.contentOffset.x,
            y: scrollView.contentOffset.y,
            width: scrollView.bounds.width,
            height: scrollView.bounds.height
        )
        
        // 检查选中区域是否与可见区域有交集
        return visibleRect.intersects(selectionInScrollView)
    }
    
    // 检测滚动
    @objc func detectScrolling(_ gesture: UIPanGestureRecognizer) {
        // 如果正在选择文本，不处理滚动
        if selectionManager.isSelecting || selectionManager.isDraggingHandle {
            return
        }
        
        guard let scrollView = gesture.view as? UIScrollView else { return }
        
        switch gesture.state {
        case .changed:
            guard viewModel.selectedRange != nil else { return }
            
            // 只有当滚动速度足够大时才隐藏菜单
            let velocity = gesture.velocity(in: scrollView)
            let translation = gesture.translation(in: scrollView)
            
            // 检查是否真的在滚动（而不是轻微触摸）
            if abs(velocity.y) > 50 || abs(translation.y) > 10 {
                // 先隐藏菜单
                hideMenu()
                
                // 检查选中区域是否还在可见范围内
                if !isSelectionVisible() {
                    clearSelection()
                }
            }
        case .ended, .cancelled:
              // 滚动结束时也检查一次
              if viewModel.selectedRange != nil {
                  DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                      if self.viewModel.selectedRange != nil && !self.isSelectionVisible() {
                          self.clearSelection()
                      }
                  }
              }
              
        default:
            break
        }
    }
    
    // 选中过程中禁止父视图 滑动
    func disableParentScrollView(_ disable: Bool) {
        var superview = self.superview
        while superview != nil {
            if let scrollView = superview as? UIScrollView {
                scrollView.isScrollEnabled = !disable
                if disable {
                    scrollView.panGestureRecognizer.isEnabled = false
                } else {
                    scrollView.panGestureRecognizer.isEnabled = true
                }
                break
            }
            superview = superview?.superview
        }
    }
}

// MARK: - System Menu
extension AIAnimationTextUIView {
    // 显示系统菜单
    private func showSystemMenu() {
        becomeFirstResponder()
        
        guard let range = viewModel.selectedRange,
              range.location < layoutManager.characterFrames.count else { return }
        
        // 获取选中区域的矩形
        let selectionRects = selectionManager.getSelectionRects(
            for: range,
            characterFrames: layoutManager.characterFrames
        )
        
        guard !selectionRects.isEmpty else { return }
        
        // 使用第一个字符的位置作为菜单显示位置
        let menuRect = selectionRects[0]
        
        let menuController = UIMenuController.shared
        menuController.showMenu(from: self, rect: menuRect)
    }
    
    // 重写以支持系统菜单
    override var canBecomeFirstResponder: Bool {
        return menuType == .system
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        guard menuType == .system else { return false }
       
        if action == #selector(copy(_:)) {
            return viewModel.selectedRange != nil
        }
        return false
    }
    
    // 系统复制方法
    @objc override func copy(_ sender: Any?) {
        guard let selectedText = viewModel.getSelectedText() else { return }
        UIPasteboard.general.string = selectedText
        showCopyFeedback() 
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.clearSelection()
        }
    }
    
    private func showCopyFeedback() {
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        
        let label = UILabel()
        label.text = "Copied"
        label.backgroundColor = UIColor.black.withAlphaComponent(0.8)
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        
        addSubview(label)
        label.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.widthAnchor.constraint(equalToConstant: 80),
            label.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        label.alpha = 0
        UIView.animate(withDuration: 0.2, animations: {
            label.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.2, delay: 0.8, options: [], animations: {
                label.alpha = 0
            }) { _ in
                label.removeFromSuperview()
            }
        }
    }
}

// MARK: - Custom Menu
private extension AIAnimationTextUIView {
    // 显示自定义菜单
    func showCustomMenu() {
        guard let range = viewModel.selectedRange,
              range.location < layoutManager.characterFrames.count else { return }
        
        customMenu?.hide()
        
        let menu = AITextSelectMenu()
        
        let menuItems = [
            AITextSelectMenu.MenuItem(
                icon: "search_ai_copy",
                title: nil,
                action: { [weak self] in
                    self?.copy()
                }
            ),
            AITextSelectMenu.MenuItem(
                icon: "search_ai_intelligent_recognition",
                title: nil,
                action: { [weak self] in
                    self?.intelligentRecognition()
                }
            )
        ]
        
        menu.setMenuItems(menuItems)
        
        // 获取选中范围的所有矩形
        let selectionRects = selectionManager.getSelectionRects(
            for: range,
            characterFrames: layoutManager.characterFrames
        )
        
        guard !selectionRects.isEmpty else { return }
        
        // 找到第一行的矩形
        let firstLineY = selectionRects.min(by: { $0.minY < $1.minY })?.minY ?? 0
        let firstLineRects = selectionRects.filter { abs($0.minY - firstLineY) < 1 }
        
        // 计算第一行的边界
        var firstLineBounds = firstLineRects[0]
        for rect in firstLineRects {
            firstLineBounds = firstLineBounds.union(rect)
        }
        
        // 找到最后一行的矩形
        let lastLineY = selectionRects.max(by: { $0.maxY < $1.maxY })?.maxY ?? 0
        let lastLineRects = selectionRects.filter { abs($0.maxY - lastLineY) < 1 }
        
        // 计算最后一行的边界
        var lastLineBounds = lastLineRects[0]
        for rect in lastLineRects {
            lastLineBounds = lastLineBounds.union(rect)
        }
        
        // 传递第一行和最后一行的信息给菜单
        menu.showWithFallback(from: self, primaryRect: firstLineBounds, fallbackRect: lastLineBounds)
        customMenu = menu
    }
    
    // 隐藏自定义选中菜单
    func hideMenu() {
        customMenu?.hide()
        customMenu = nil
    }
    
    // 智能识别
    func intelligentRecognition() {
        guard let selectedText = viewModel.getSelectedText() else { return }
        onIntelligentRecognition?(selectedText)

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.clearSelection()
        }
    }
}

// MARK: - Gesture Handlers
private extension AIAnimationTextUIView {
    @objc func handleLongPress(_ gesture: UILongPressGestureRecognizer) {
        let location = gesture.location(in: self)
        
        switch gesture.state {
        case .began:
            if let charIndex = selectionManager.characterIndexAt(location: location, in: layoutManager.characterFrames) {
                selectionManager.startSelection(at: charIndex, location: location)
                
                let wordRange = selectionManager.wordRangeAt(characterIndex: charIndex, in: currentParsedItems)
                viewModel.selectedRange = wordRange
                updateSelectionView()
                // 根据菜单类型显示相应菜单
                showMenuBasedOnType()
                selectionManager.isSelecting = true
                
                // 延迟重置标志
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    if self.panGesture.state != .began && self.panGesture.state != .changed {
                        self.selectionManager.isSelecting = false
                    }
                }
            }
        default:
            break
        }
    }
    
    @objc func handleHandlePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        
        switch gesture.state {
        case .began:
            selectionManager.isDraggingHandle = true  // 添加这个标记
            selectionManager.startHandleDrag(
                handle: gesture.view == startHandle ? .start : .end
            )
            disableParentScrollView(true)
            
        case .changed:
            if let newRange = selectionManager.updateHandleDrag(
                to: location,
                currentRange: viewModel.selectedRange,
                characterFrames: layoutManager.characterFrames
            ) {
                viewModel.selectedRange = newRange
                updateSelectionView()
            }
            
        case .ended, .cancelled:
            selectionManager.endHandleDrag()
            selectionManager.isDraggingHandle = false  // 重置标记
            disableParentScrollView(false)
            
            if viewModel.selectedRange != nil {
                showMenuBasedOnType()
            }
            
        default:
            break
        }
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: self)
        
        // 如果当前有选择
        if viewModel.selectedRange != nil {
            // 如果点击在选择区域内
            if selectionManager.isLocationInSelection(location, range: viewModel.selectedRange!, characterFrames: layoutManager.characterFrames) {
                // 如果菜单不存在，重新显示菜单
                if menuType == .custom && customMenu == nil {
                    showMenuBasedOnType()
                }
                return
            } else {
                // 点击在选择区域外，清除选择
                clearSelection()
                disableParentScrollView(false)
                return
            }
        }
        
        // 检查是否点击了链接
        if let charIndex = selectionManager.characterIndexAt(location: location, in: layoutManager.characterFrames) {
            var currentIndex = 0
            for item in currentParsedItems {
                if item.type == .character, item.char != "\n" {
                    if currentIndex == charIndex {
                        if let urlString = item.attributes.linkURL,
                           let url = URL(string: urlString) {
                            onLinkTapped?(url)
                            return
                        }
                        break
                    }
                    currentIndex += 1
                }
            }
        }
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard selectionManager.isSelecting else { return }
        
        let location = gesture.location(in: self)
        
        switch gesture.state {
        case .began:
            // 确保标记正在拖动选择
            selectionManager.isDraggingSelection = true
            
            if let charIndex = selectionManager.characterIndexAt(location: location, in: layoutManager.characterFrames) {
                selectionManager.startSelection(at: charIndex, location: location)
            }
            disableParentScrollView(true)
            customMenu?.hide()
            
        case .changed:
            if let newRange = selectionManager.updateSelection(to: location, characterFrames: layoutManager.characterFrames) {
                viewModel.selectedRange = newRange
                updateSelectionView()
            }
            
        case .ended, .cancelled, .failed:
            disableParentScrollView(false)
            selectionManager.endSelection()
            selectionManager.isDraggingSelection = false
            
            if let range = viewModel.selectedRange, range.length == 0 {
                clearSelection()
            } else if viewModel.selectedRange != nil {
                showMenuBasedOnType()
            }
            
        default:
            break
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension AIAnimationTextUIView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer == longPressGesture {
            return true
        }
        
        // 如果是滚动检测手势，允许同时识别
        if gestureRecognizer == scrollDetectorGesture || otherGestureRecognizer == scrollDetectorGesture {
            return true
        }
        
        if gestureRecognizer.view == startHandle || gestureRecognizer.view == endHandle {
            return false
        }
        
        if gestureRecognizer == panGesture && selectionManager.isSelecting {
            return false
        }
        
        return false
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        hideMenu()
        if gestureRecognizer == panGesture {
            return selectionManager.isSelecting
        }
        return true
    }
}
