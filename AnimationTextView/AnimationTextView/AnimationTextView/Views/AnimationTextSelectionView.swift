//
//  AnimationTextSelectionView.swift
//  AnimationTextView
//
//  Created by Bern on 2025/8/10.
//

import UIKit

class AnimationTextSelectionView: UIView {
    
    // MARK: - Properties
    var selectionColor: UIColor = UIColor.systemBlue.withAlphaComponent(0.3) {
        didSet { setNeedsDisplay() }
    }
    
    private var selectionRects: [CGRect] = []
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    private func setupView() {
        backgroundColor = .clear
        isUserInteractionEnabled = false
        layer.zPosition = -1 // Ensure selection appears below text
    }
    
    // MARK: - Drawing
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setFillColor(selectionColor.cgColor)
        
        for rect in selectionRects {
            let path = UIBezierPath(roundedRect: rect, cornerRadius: 2)
            context.addPath(path.cgPath)
        }
        
        context.fillPath()
    }
    
    // MARK: - Public Methods
    func updateSelection(rects: [CGRect]) {
        selectionRects = mergeRects(rects)
        setNeedsDisplay()
    }
    
    func clearSelection() {
        selectionRects = []
        setNeedsDisplay()
    }
    
    // MARK: - Private Methods
    private func mergeRects(_ rects: [CGRect]) -> [CGRect] {
        guard !rects.isEmpty else { return [] }
        
        var mergedRects: [CGRect] = []
        var currentRect = rects[0]
        
        for i in 1..<rects.count {
            let rect = rects[i]
            
            // Check if rects are on the same line and adjacent
            if abs(rect.minY - currentRect.minY) < 1 &&
               abs(rect.minX - currentRect.maxX) < 2 {
                // Merge rects
                currentRect = currentRect.union(rect)
            } else {
                // Add current rect and start new one
                mergedRects.append(currentRect)
                currentRect = rect
            }
        }
        
        mergedRects.append(currentRect)
        return mergedRects
    }
}
