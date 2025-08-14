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
    // 这个动画现在没有使用
    func animate(layer: CATextLayer) {
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0.0
        opacityAnimation.toValue = 1.0

        let scaleAnimation = CABasicAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 0.3
        scaleAnimation.toValue = 1.0
        
        let shadowRadiusAnimation = CABasicAnimation(keyPath: "shadowRadius")
        shadowRadiusAnimation.fromValue = 6.0
        shadowRadiusAnimation.toValue = 0.0
        shadowRadiusAnimation.duration = 0.45

        let shadowOpacityAnimation = CABasicAnimation(keyPath: "shadowOpacity")
        shadowOpacityAnimation.fromValue = 1.0
        shadowOpacityAnimation.toValue = 0.0
        shadowOpacityAnimation.duration = 0.45

        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [opacityAnimation, scaleAnimation, shadowOpacityAnimation, shadowRadiusAnimation]
        animationGroup.duration = 0.35
        animationGroup.timingFunction = CAMediaTimingFunction(name: .easeOut)

        layer.opacity = 1.0
        layer.transform = CATransform3DIdentity
        layer.filters = nil
        
        layer.add(animationGroup, forKey: "all_in_one_appearance")
    }
    
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
        shadowOpacityAnimation.fromValue = 4
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
