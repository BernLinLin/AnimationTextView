//
//  AIAnimationTextSelectionView.swift
//  HLHS
//
//  Created by Bern on 2025/8/12.
//

import UIKit

class AIAnimationTextSelectionView: UIView {
    var selectionRects: [CGRect] = []
    var selectionColor: UIColor = UIColor.systemBlue.withAlphaComponent(0.3)
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        isUserInteractionEnabled = false
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setFillColor(selectionColor.cgColor)
        for rect in selectionRects {
            context.fill(rect)
        }
    }
    
    func updateSelection(rects: [CGRect]) {
        selectionRects = rects
        setNeedsDisplay()
    }
    
    func clearSelection() {
        selectionRects = []
        setNeedsDisplay()
    }
}
