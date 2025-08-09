//
//  AnimationSelectionHandleView.swift
//  AnimationTextView
//
//  Created by Bern on 2025/8/10.
//

import UIKit

class AnimationSelectionHandleView: UIView {
    
    // MARK: - Types
    enum HandleType {
        case start
        case end
    }
    
    // MARK: - Properties
    let type: HandleType
    var handleColor: UIColor = .systemBlue {
        didSet { setNeedsDisplay() }
    }
    
    private let handleSize: CGFloat = 12
    private let lineLength: CGFloat = 20
    private let touchAreaSize: CGFloat = 44
    
    // MARK: - Initialization
    init(type: HandleType) {
        self.type = type
        super.init(frame: CGRect(x: 0, y: 0, width: touchAreaSize, height: touchAreaSize))
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .clear
        isUserInteractionEnabled = true
    }
    
    // MARK: - Drawing
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setFillColor(handleColor.cgColor)
        context.setStrokeColor(handleColor.cgColor)
        context.setLineWidth(2)
        
        let centerX = touchAreaSize / 2
        
        switch type {
        case .start:
            drawStartHandle(in: context, centerX: centerX)
        case .end:
            drawEndHandle(in: context, centerX: centerX)
        }
    }
    
    private func drawStartHandle(in context: CGContext, centerX: CGFloat) {
        // Draw circle at top
        let circleRect = CGRect(
            x: centerX - handleSize/2,
            y: 0,
            width: handleSize,
            height: handleSize
        )
        context.fillEllipse(in: circleRect)
        
        // Draw line downward
        context.move(to: CGPoint(x: centerX, y: handleSize))
        context.addLine(to: CGPoint(x: centerX, y: handleSize + lineLength))
        context.strokePath()
    }
    
    private func drawEndHandle(in context: CGContext, centerX: CGFloat) {
        // Draw line upward
        context.move(to: CGPoint(x: centerX, y: touchAreaSize - handleSize - lineLength))
        context.addLine(to: CGPoint(x: centerX, y: touchAreaSize - handleSize))
        context.strokePath()
        
        // Draw circle at bottom
        let circleRect = CGRect(
            x: centerX - handleSize/2,
            y: touchAreaSize - handleSize,
            width: handleSize,
            height: handleSize
        )
        context.fillEllipse(in: circleRect)
    }
    
    // MARK: - Touch Handling
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Expand touch area for easier interaction
        return bounds.insetBy(dx: -10, dy: -10).contains(point)
    }
    
    // MARK: - Layout
    func positionHandle(at point: CGPoint, for handleType: HandleType) {
        switch handleType {
        case .start:
            // Position so circle is at the selection start point
            frame.origin = CGPoint(
                x: point.x - touchAreaSize/2,
                y: point.y - 5
            )
        case .end:
            // Position so circle is at the selection end point
            frame.origin = CGPoint(
                x: point.x - touchAreaSize/2,
                y: point.y - touchAreaSize + handleSize + 5
            )
        }
    }
}
