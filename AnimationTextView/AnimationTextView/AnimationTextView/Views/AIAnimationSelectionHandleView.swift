//
//  AIAnimationSelectionHandleView.swift
//  HLHS
//
//  Created by Bern on 2025/8/12.
//

import UIKit

class AIAnimationSelectionHandleView: UIView {
    enum HandleType {
        case start
        case end
    }
    
    let type: HandleType
    private let handleSize: CGFloat = 12
    private let touchAreaSize: CGFloat = 44
    
    init(type: HandleType) {
        self.type = type
        super.init(frame: CGRect(x: 0, y: 0, width: touchAreaSize, height: touchAreaSize))
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setFillColor(UIColor.systemBlue.cgColor)
        context.setStrokeColor(UIColor.systemBlue.cgColor)
        context.setLineWidth(2)
        
        let centerX = touchAreaSize / 2
        
        if type == .start {
            let circle = UIBezierPath(ovalIn: CGRect(
                x: centerX - handleSize/2,
                y: 0,
                width: handleSize,
                height: handleSize
            ))
            context.addPath(circle.cgPath)
            context.fillPath()
            
            context.move(to: CGPoint(x: centerX, y: handleSize))
            context.addLine(to: CGPoint(x: centerX, y: handleSize + 20))
            context.strokePath()
            
        } else {
            context.move(to: CGPoint(x: centerX, y: touchAreaSize - handleSize - 20))
            context.addLine(to: CGPoint(x: centerX, y: touchAreaSize - handleSize))
            context.strokePath()
            
            let circle = UIBezierPath(ovalIn: CGRect(
                x: centerX - handleSize/2,
                y: touchAreaSize - handleSize,
                width: handleSize,
                height: handleSize
            ))
            context.addPath(circle.cgPath)
            context.fillPath()
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        return bounds.insetBy(dx: -10, dy: -10).contains(point)
    }
}
