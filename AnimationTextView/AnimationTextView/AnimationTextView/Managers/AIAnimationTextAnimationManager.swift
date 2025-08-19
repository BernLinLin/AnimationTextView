//
//  AIAnimationTextAnimationManager.swift
//  HLHS
//
//  Created by Bern on 2025/8/12.
//

/*
 可在该文件添加不同的动画效果
 */

import Foundation
import QuartzCore
import UIKit

class AIAnimationTextAnimationManager {
    func animateFadeInScale(layer: CALayer) {
        layer.opacity = 0
        
        // Opacity animation
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0
        opacityAnimation.toValue = 1
        
        // Scale animation
        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 0.5
        scaleAnimation.toValue = 1.0
        
        // Shadow animation for glow effect
        let shadowOpacityAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        shadowOpacityAnimation.fromValue = 50
        shadowOpacityAnimation.toValue = 0
        
        let shadowRadiusAnimation = CABasicAnimation(keyPath: "shadowRadius")
        shadowRadiusAnimation.fromValue = 3.5
        shadowRadiusAnimation.toValue = 0
        
        // Configure shadow
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = .zero
        
        // Group animations
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [
            opacityAnimation,
            scaleAnimation,
            shadowOpacityAnimation,
            shadowRadiusAnimation
        ]
        animationGroup.duration = 0.4
        animationGroup.beginTime = CACurrentMediaTime() + 0.02
        animationGroup.fillMode = .backwards
        animationGroup.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        layer.add(animationGroup, forKey: "fadeInScale")
        layer.opacity = 1
    }
}
