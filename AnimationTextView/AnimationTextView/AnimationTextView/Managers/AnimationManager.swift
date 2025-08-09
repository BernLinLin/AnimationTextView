//
//  AnimationManager.swift
//  AnimationTextView
//
//  Created by Bern on 2025/8/10.
//

import UIKit

class AnimationManager {
    
    // MARK: - Properties
    var theme = AnimationTextStyleTheme.default
    
    // MARK: - Public Methods
    func animate(layer: CALayer, delay: TimeInterval = 0) {
        switch theme.animationType {
        case .fadeIn:
            animateFadeIn(layer: layer, delay: delay)
        case .fadeInScale:
            animateFadeInScale(layer: layer, delay: delay)
        case .typewriter:
            animateTypewriter(layer: layer, delay: delay)
        case .slideIn:
            animateSlideIn(layer: layer, delay: delay)
        case .bounce:
            animateBounce(layer: layer, delay: delay)
        }
    }
    
    // MARK: - Private Animation Methods
    private func animateFadeIn(layer: CALayer, delay: TimeInterval) {
        layer.opacity = 0
        
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.fromValue = 0
        animation.toValue = 1
        animation.duration = theme.animationDuration
        animation.beginTime = CACurrentMediaTime() + delay
        animation.fillMode = .backwards
        animation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        layer.add(animation, forKey: "fadeIn")
        layer.opacity = 1
    }
    
    private func animateFadeInScale(layer: CALayer, delay: TimeInterval) {
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
        shadowOpacityAnimation.fromValue = 0.8
        shadowOpacityAnimation.toValue = 0
        
        let shadowRadiusAnimation = CABasicAnimation(keyPath: "shadowRadius")
        shadowRadiusAnimation.fromValue = 8
        shadowRadiusAnimation.toValue = 0
        
        // Configure shadow
        layer.shadowColor = theme.textColor.cgColor
        layer.shadowOffset = .zero
        
        // Group animations
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [
            opacityAnimation,
            scaleAnimation,
            shadowOpacityAnimation,
            shadowRadiusAnimation
        ]
        animationGroup.duration = theme.animationDuration
        animationGroup.beginTime = CACurrentMediaTime() + delay
        animationGroup.fillMode = .backwards
        animationGroup.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        layer.add(animationGroup, forKey: "fadeInScale")
        layer.opacity = 1
    }
    
    private func animateTypewriter(layer: CALayer, delay: TimeInterval) {
        layer.opacity = 0
        
        // Clip animation
        let maskLayer = CALayer()
        maskLayer.backgroundColor = UIColor.black.cgColor
        maskLayer.frame = CGRect(x: 0, y: 0, width: 0, height: layer.bounds.height)
        layer.mask = maskLayer
        
        // Expand mask animation
        let widthAnimation = CABasicAnimation(keyPath: "bounds.size.width")
        widthAnimation.fromValue = 0
        widthAnimation.toValue = layer.bounds.width
        widthAnimation.duration = theme.animationDuration
        widthAnimation.beginTime = CACurrentMediaTime() + delay
        widthAnimation.fillMode = .backwards
        widthAnimation.timingFunction = CAMediaTimingFunction(name: .linear)
        
        maskLayer.add(widthAnimation, forKey: "typewriter")
        
        // Opacity animation
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0
        opacityAnimation.toValue = 1
        opacityAnimation.duration = 0.1
        opacityAnimation.beginTime = CACurrentMediaTime() + delay
        opacityAnimation.fillMode = .backwards
        
        layer.add(opacityAnimation, forKey: "opacity")
        
        // Remove mask after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + theme.animationDuration) {
            layer.mask = nil
        }
        
        layer.opacity = 1
        maskLayer.frame.size.width = layer.bounds.width
    }
    
    private func animateSlideIn(layer: CALayer, delay: TimeInterval) {
        layer.opacity = 0
        
        // Position animation
        let positionAnimation = CABasicAnimation(keyPath: "position.x")
        positionAnimation.fromValue = layer.position.x - 50
        positionAnimation.toValue = layer.position.x
        
        // Opacity animation
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0
        opacityAnimation.toValue = 1
        
        // Group animations
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [positionAnimation, opacityAnimation]
        animationGroup.duration = theme.animationDuration
        animationGroup.beginTime = CACurrentMediaTime() + delay
        animationGroup.fillMode = .backwards
        animationGroup.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        layer.add(animationGroup, forKey: "slideIn")
        layer.opacity = 1
    }
    
    private func animateBounce(layer: CALayer, delay: TimeInterval) {
        layer.opacity = 0
        
        // Create bounce effect with keyframes
        let positionAnimation = CAKeyframeAnimation(keyPath: "position.y")
        let originalY = layer.position.y
        positionAnimation.values = [
            originalY - 20,
            originalY + 5,
            originalY - 2,
            originalY
        ]
        positionAnimation.keyTimes = [0, 0.6, 0.8, 1.0]
        
        // Opacity animation
        let opacityAnimation = CABasicAnimation(keyPath: "opacity")
        opacityAnimation.fromValue = 0
        opacityAnimation.toValue = 1
        opacityAnimation.duration = theme.animationDuration * 0.3
        
        // Scale animation for squash and stretch
        let scaleXAnimation = CAKeyframeAnimation(keyPath: "transform.scale.x")
        scaleXAnimation.values = [0.8, 1.1, 0.95, 1.0]
        scaleXAnimation.keyTimes = [0, 0.6, 0.8, 1.0]
        
        let scaleYAnimation = CAKeyframeAnimation(keyPath: "transform.scale.y")
        scaleYAnimation.values = [1.2, 0.9, 1.05, 1.0]
        scaleYAnimation.keyTimes = [0, 0.6, 0.8, 1.0]
        
        // Group animations
        let animationGroup = CAAnimationGroup()
        animationGroup.animations = [
            positionAnimation,
            opacityAnimation,
            scaleXAnimation,
            scaleYAnimation
        ]
        animationGroup.duration = theme.animationDuration
        animationGroup.beginTime = CACurrentMediaTime() + delay
        animationGroup.fillMode = .backwards
        animationGroup.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        layer.add(animationGroup, forKey: "bounce")
        layer.opacity = 1
    }
    
    // MARK: - Batch Animation
    func animateLayers(_ layers: [CALayer], baseDelay: TimeInterval = 0) {
        for (index, layer) in layers.enumerated() {
            let delay = baseDelay + (Double(index) * theme.animationDelay)
            animate(layer: layer, delay: delay)
        }
    }
}
