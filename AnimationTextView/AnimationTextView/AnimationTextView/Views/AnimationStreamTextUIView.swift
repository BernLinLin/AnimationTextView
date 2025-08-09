//
//  AnimationStreamTextUIView.swift
//  AnimationTextView
//
//  Created by Bern on 2025/8/10.
//

import UIKit

class AnimationStreamTextUIView: UIView {
    
    // MARK: - Public Properties
    var theme = AnimationTextStyleTheme.default {
        didSet { updateTheme() }
    }
    var onLinkTapped: ((URL) -> Void)?
    var isSelectable: Bool = true {
        didSet { updateSelectability() }
    }
    var animationEnabled: Bool = true
    
    // MARK: - Private Properties
    private let layoutManager: AnimationTextLayoutManager
    private let selectionManager: AnimationSelectionManager
    private let animationManager: AnimationManager
    private let parser: MarkdownParser
    private let gestureHandler: AnimationGestureHandler
    
    private var characterLayers: [CATextLayer] = []
    private var decorationLayers: [CALayer] = []
    private var currentAnimationParsedItems: [AnimationParsedItem] = []
    private var characterFrames: [CGRect] = []
    
    private var calculatedHeight: CGFloat = 0
    
    // MARK: - Subviews
    private let selectionView: AnimationTextSelectionView
    private let startHandle: AnimationSelectionHandleView
    private let endHandle: AnimationSelectionHandleView
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        // Initialize subviews
        self.selectionView = AnimationTextSelectionView()
        self.startHandle = AnimationSelectionHandleView(type: .start)
        self.endHandle = AnimationSelectionHandleView(type: .end)
        
        // Initialize managers
        self.layoutManager = AnimationTextLayoutManager()
        self.selectionManager = AnimationSelectionManager()
        self.animationManager = AnimationManager()
        self.parser = MarkdownParser()
        self.gestureHandler = AnimationGestureHandler()
        
        super.init(frame: frame)
        
        setupView()
        setupManagers()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupView() {
        backgroundColor = .clear
        isUserInteractionEnabled = true
        
        // Add subviews
        addSubview(selectionView)
        addSubview(startHandle)
        addSubview(endHandle)
        
        // Configure handles
        startHandle.isHidden = true
        endHandle.isHidden = true
    }
    
    private func setupManagers() {
        // Configure layout manager
        layoutManager.theme = theme
        
        // Configure selection manager
        selectionManager.selectionView = selectionView
        selectionManager.startHandle = startHandle
        selectionManager.endHandle = endHandle
        selectionManager.delegate = self
        selectionManager.characterFramesProvider = { [weak self] in
            return self?.characterFrames ?? []
        }
        
        // Configure animation manager
        animationManager.theme = theme
        
        // Configure gesture handler
        gestureHandler.delegate = self
    }
    
    override func didMoveToSuperview() {
        super.didMoveToSuperview()
        // 设置父视图，以便查找 ScrollView
        selectionManager.setParentView(self)
    }
    
    private func setupGestures() {
        gestureHandler.setupGestures(on: self)
    }
    
    // MARK: - Public Methods
    func updateText(_ newText: String) {
        Task {
            let items = await parser.parse(newText)
            
            await MainActor.run {
                self.performUpdate(with: items)
            }
        }
    }
    
    // MARK: - Private Methods
    private func performUpdate(with newAnimationParsedItems: [AnimationParsedItem]) {
        // 使用原有的增量更新逻辑
        let commonPrefixCount = zip(currentAnimationParsedItems, newAnimationParsedItems).prefix(while: { $0 == $1 }).count
        
        if commonPrefixCount == newAnimationParsedItems.count && newAnimationParsedItems.count == currentAnimationParsedItems.count {
            return
        }
        
        // Remove old character layers
        let itemsToRemove = currentAnimationParsedItems.suffix(from: commonPrefixCount)
        let charLayersToRemoveCount = itemsToRemove.filter { $0.type == .text && $0.text != "\n" }.count
        
        if charLayersToRemoveCount > 0 && characterLayers.count >= charLayersToRemoveCount {
            characterLayers.suffix(charLayersToRemoveCount).forEach { $0.removeFromSuperlayer() }
            characterLayers.removeLast(charLayersToRemoveCount)
        }
        
        // Add new character layers
        let itemsToAdd = newAnimationParsedItems.suffix(from: commonPrefixCount)
        let shouldAnimate = commonPrefixCount > 0 && animationEnabled
        
        for item in itemsToAdd {
            if item.type == .text, let text = item.text, text != "\n", text.count == 1 {
                let characterLayer = createCharacterLayer(for: text, with: item.attributes)
                self.layer.addSublayer(characterLayer)
                characterLayers.append(characterLayer)
                
                if shouldAnimate {
                    animationManager.animate(layer: characterLayer)
                }
            }
        }
        
        currentAnimationParsedItems = newAnimationParsedItems
        selectionManager.clearSelection()
        setNeedsLayout()
    }
    
    private func createCharacterLayer(for text: String, with attributes: TextAttributes) -> CATextLayer {
        let layer = CATextLayer()
        let attributedString = NSAttributedString(string: text, attributes: attributes.dictionary)
        layer.string = attributedString
        layer.contentsScale = UIScreen.main.scale
        layer.alignmentMode = .left
        layer.anchorPoint = CGPoint(x: 0, y: 0)
        return layer
    }
    
    private func updateTheme() {
        layoutManager.theme = theme
        animationManager.theme = theme
        setNeedsLayout()
    }
    
    private func updateSelectability() {
        gestureHandler.isEnabled = isSelectable
        if !isSelectable {
            selectionManager.clearSelection()
        }
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        
        selectionView.frame = bounds
        
        // Clear decoration layers
        decorationLayers.forEach { $0.removeFromSuperlayer() }
        decorationLayers.removeAll()
        
        // Layout characters using the layout manager
        let layoutResult = layoutManager.layoutCharacters(
            currentAnimationParsedItems,
            layers: characterLayers,
            in: bounds
        )
        
        // Apply layout to character layers
        for (index, frame) in layoutResult.characterFrames.enumerated() {
            guard index < characterLayers.count else { break }
            characterLayers[index].frame = frame
        }
        
        // Cache character frames for selection
        characterFrames = layoutResult.characterFrames
        
        // Add decorations
        for decoration in layoutResult.decorations {
            let decorationLayer = createDecorationLayer(for: decoration)
            self.layer.addSublayer(decorationLayer)
            decorationLayers.append(decorationLayer)
        }
        
        // Update calculated height
        if calculatedHeight != layoutResult.totalHeight {
            calculatedHeight = layoutResult.totalHeight
            invalidateIntrinsicContentSize()
        }
        
        // Update selection
        selectionManager.updateLayout()
    }
    
    override var intrinsicContentSize: CGSize {
        return CGSize(width: UIView.noIntrinsicMetric, height: layoutManager.calculatedHeight)
    }
    
    // MARK: - Decoration Creation
    private func createDecorationLayer(for decoration: TextDecoration) -> CALayer {
        switch decoration.type {
        case .horizontalRule:
            return createHorizontalRuleLayer(at: decoration.frame.origin.y)
            
        case .blockquoteLine(let level):
            return createBlockquoteLineLayer(decoration.frame, level: level)
            
        case .listMarker(let marker):
            return createListMarkerLayer(marker, frame: decoration.frame)
        }
    }
    
    private func createHorizontalRuleLayer(at y: CGFloat) -> CAShapeLayer {
        let layer = CAShapeLayer()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: 0, y: y))
        path.addLine(to: CGPoint(x: bounds.width, y: y))
        layer.path = path.cgPath
        layer.lineWidth = 1.0
        layer.strokeColor = theme.textColor.withAlphaComponent(0.3).cgColor
        return layer
    }
    
    private func createBlockquoteLineLayer(_ frame: CGRect, level: Int) -> CAShapeLayer {
        let layer = CAShapeLayer()
        let path = UIBezierPath()
        path.move(to: CGPoint(x: frame.origin.x, y: frame.origin.y))
        path.addLine(to: CGPoint(x: frame.origin.x, y: frame.origin.y + frame.height))
        layer.path = path.cgPath
        layer.strokeColor = theme.textColor.withAlphaComponent(0.4).cgColor
        layer.lineWidth = 2.0
        return layer
    }
    
    private func createListMarkerLayer(_ marker: String, frame: CGRect) -> CATextLayer {
        let layer = createCharacterLayer(for: marker, with: TextAttributes())
        layer.frame = frame
        layer.alignmentMode = .right
        return layer
    }
}

// MARK: - SelectionDelegate
extension AnimationStreamTextUIView: AnimationSelectionDelegate {
    func selectionDidChange(_ range: NSRange?) {
        if range != nil {
            becomeFirstResponder()
            showMenu()
        }
    }
    
    func selectionShouldBegin(at point: CGPoint) -> Bool {
        return isSelectable
    }
    
    func textInRange(_ range: NSRange) -> String? {
        return layoutManager.textInRange(range, from: currentAnimationParsedItems)
    }
}

// MARK: - GestureHandlerDelegate
extension AnimationStreamTextUIView: AnimationGestureHandlerDelegate {
    func gestureHandlerDidTap(at point: CGPoint) {
        // Check for link tap
        if let charIndex = characterIndexAt(location: point) {
            var currentIndex = 0
            for item in currentAnimationParsedItems {
                if item.type == .text, item.text != "\n" {
                    if currentIndex == charIndex {
                        if let url = item.attributes.link {
                            onLinkTapped?(url)
                            return
                        }
                        break
                    }
                    currentIndex += 1
                }
            }
        }
        
        selectionManager.handleTap(at: point)
    }
    
    func gestureHandlerDidLongPress(at point: CGPoint) {
        selectionManager.handleLongPress(at: point)
    }
    
    func gestureHandlerDidPan(from startPoint: CGPoint, to endPoint: CGPoint, state: UIGestureRecognizer.State) {
        selectionManager.handlePan(from: startPoint, to: endPoint, state: state)
    }
    
    func gestureHandlerShouldRecognizeSimultaneously() -> Bool {
        return !selectionManager.isSelecting
    }
    
    private func characterIndexAt(location: CGPoint) -> Int? {
        for (index, frame) in characterFrames.enumerated() {
            if frame.contains(location) {
                return index
            }
        }
        
        // Find nearest if no direct hit
        var closestIndex: Int?
        var closestDistance: CGFloat = .greatestFiniteMagnitude
        
        for (index, frame) in characterFrames.enumerated() {
            let centerX = frame.midX
            let centerY = frame.midY
            let distance = sqrt(pow(location.x - centerX, 2) + pow(location.y - centerY, 2))
            
            if location.y >= frame.minY && location.y <= frame.maxY {
                let horizontalDistance = abs(location.x - centerX)
                if horizontalDistance < closestDistance {
                    closestDistance = horizontalDistance
                    closestIndex = index
                }
            } else if distance < closestDistance {
                closestDistance = distance
                closestIndex = index
            }
        }
        
        return closestIndex
    }
}

// MARK: - UIResponder
extension AnimationStreamTextUIView {
    override var canBecomeFirstResponder: Bool {
        return isSelectable
    }
    
    override func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if action == #selector(copy(_:)) {
            return selectionManager.hasSelection
        }
        return false
    }
    
    @objc override func copy(_ sender: Any?) {
        guard let text = selectionManager.selectedText else { return }
        UIPasteboard.general.string = text
        selectionManager.clearSelection()
        showCopyFeedback()
    }
    
    private func showCopyFeedback() {
        let feedback = UINotificationFeedbackGenerator()
        feedback.notificationOccurred(.success)
        
        let label = UILabel()
        label.text = "已复制"
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
    
    private func showMenu() {
        guard let rect = selectionManager.selectionRect else { return }
        
        let menuController = UIMenuController.shared
        menuController.showMenu(from: self, rect: rect)
    }
}
