//
//  RevolverMenuView.swift
//  RevolverMenu
//
//  Created by 川村周也 on 2019/04/08.
//  Copyright © 2019 川村周也. All rights reserved.
//

import UIKit

enum direction {
    case right
    case left
}

class RevolverMenuView: UIView {
    
    private var items: [RevolverMenuItem] = []
    private var buttons: [RevolverMenuItem]  = [RevolverMenuItem](repeating: RevolverMenuItem(), count: 12) {
        didSet {
            
        }
    }
    
    private var startPoint = CGPoint(x: UIScreen.main.bounds.width - 30, y: UIScreen.main.bounds.height - 30)
    
    public var expandMargin: CGFloat = 120.0
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.isUserInteractionEnabled = true
        
        reloadItems()
        
        initPoints()
        
        
        enableAutoLayout()
        moveMenuButtonPosision()
        hiddenButton()
        
    }
    
    public convenience init(frame: CGRect, startItem: RevolverMenuItem, items:[RevolverMenuItem], direction: direction) {
        self.init(frame: frame)
        
        self.items = items
        
        switch direction {
        case .right:
            startPoint = CGPoint(x: UIScreen.main.bounds.width - 30, y: UIScreen.main.bounds.height - 30)
        case .left:
            startPoint = CGPoint(x: 30, y: UIScreen.main.bounds.height - 30)
        }
        
        initButtons(startItem: startItem, items: items)
        
    }
    
    private func initButtons(startItem: RevolverMenuItem, items:[RevolverMenuItem]){
        
        startItem.center = startPoint
        
        for (index, button) in buttons.enumerated() {
            self.addSubview(button)
            button.center = CGPoint(x: startPoint.x + expandMargin * CGFloat(cos(-Double.pi/6)), y: startPoint.y - expandMargin * CGFloat(sin(-Double.pi/6)))
        }
        
    }
    
    private func reloadItems() {
        displayItems.removeAll()
        for index in (4 * currentPage)...(4 * currentPage) + 4 {
            if index >= items.count {
                displayItems.append(UIImage())
            } else {
                displayItems.append(items[index])
            }
        }
    }
    
    /// 該当のメニューを選択する
    private func selectedTargetMenu() {
        
        if isSelectedButton {
            
            UIView.animate(withDuration: 0.3, animations: {
                self.moveMenuButtonPosision()
                self.hiddenButton()
                self.removeGestureView()
            })
        } else {
            
            UIView.animate(withDuration: 0.3, animations: {
                self.moveDefaultButtonPosision()
                self.showButton()
                self.createGestureView()
            })
        }
        isSelectedButton = !isSelectedButton
        setUserInteraction?(!isSelectedButton)
        
    }
    
    /// AutoLayoutを有効にする
    private func enableAutoLayout() {
        buttons.forEach { $0.translatesAutoresizingMaskIntoConstraints = true }
        menuButton.translatesAutoresizingMaskIntoConstraints = true
    }
    
    /// ボタンを表示する
    private func showButton() {
        buttons.forEach { $0.alpha = 1 }
    }
    
    /// ボタンを非表示にする
    private func hiddenButton() {
        buttons.forEach { $0.alpha = 0 }
    }
    
    /// ボタンを元の場所に移動する
    private func moveDefaultButtonPosision() {
        for (index, button) in buttons.enumerated() {
            button.center = calcExpandedPosition(index)
        }
    }
    
    private func calcExpandedPosition(_ index: Int) -> CGPoint {
        return CGPoint(x: startPoint.x + expandMargin * CGFloat(cos(-Double.pi/6)), y: startPoint.y - expandMargin * CGFloat(sin(-Double.pi/6)))
    }
    
    /// ボタンをメニューの場所へ移動する
    private func moveMenuButtonPosision() {
        buttons.forEach { $0.center = startPoint }
    }
    
    private func changeButtonItem() {
        reloadItems()
        
        for btn in buttons {
            btn.setImage(displayItems[buttons.index(of: btn)!], for: .normal)
        }
        
    }
    
    func upAnimation() {
        
        for out_btn in out_buttons {
            out_btn.layer.removeAnimation(forKey: "end")
            let animation: CAKeyframeAnimation = self.animation()
            let path: CGMutablePath = CGMutablePath()
            let stPoint: CGPoint = out_btn.center
            let angle: Double = Double(out_buttons.index(of: out_btn)!) / 6.0
            
            path.move(to: stPoint)
            path.addArc(center: startPoint,
                        radius: expandMargin,
                        startAngle: CGFloat(-Double.pi * (7/6 + angle)),
                        endAngle: CGFloat(-Double.pi * (1/2 + angle)),
                        clockwise: false)
            animation.path = path
            out_btn.layer.add(animation, forKey: "start")
        }
        
        for btn in buttons {
            btn.layer.removeAnimation(forKey: "end")
            let animation: CAKeyframeAnimation = self.animation()
            let path: CGMutablePath = CGMutablePath()
            let stPoint: CGPoint = btn.center
            let angle: Double = Double(buttons.index(of: btn)!) / 6.0
            
            path.move(to: stPoint)
            path.addArc(center: startPoint,
                        radius: expandMargin,
                        startAngle: CGFloat(-Double.pi * (1/2 + angle)),
                        endAngle: CGFloat(-Double.pi * (-1/6 + angle)),
                        clockwise: false)
            animation.path = path
            btn.layer.add(animation, forKey: "start")
        }
        
        //changeBackCalor()
        nextImage = present
        currentPage += 1
    }
    
    func downAnimation() {
        
        for in_btn in in_buttons {
            in_btn.layer.removeAnimation(forKey: "end")
            let animation: CAKeyframeAnimation = self.animation()
            let path: CGMutablePath = CGMutablePath()
            let stPoint: CGPoint = in_btn.center
            let angle: Double = Double(in_buttons.index(of: in_btn)!) / 6.0
            
            path.move(to: stPoint)
            path.addArc(center: startPoint,
                        radius: expandMargin,
                        startAngle: CGFloat(-Double.pi * (-1/6 + angle)),
                        endAngle: CGFloat(-Double.pi * (1/2 + angle)),
                        clockwise: true)
            animation.path = path
            in_btn.layer.add(animation, forKey: "start")
            
        }
        
        for btn in buttons {
            btn.layer.removeAnimation(forKey: "end")
            let animation: CAKeyframeAnimation = self.animation()
            let path: CGMutablePath = CGMutablePath()
            let stPoint: CGPoint = btn.center
            let angle: Double = Double(buttons.index(of: btn)!) / 6.0
            
            path.move(to: stPoint)
            path.addArc(center: startPoint,
                        radius: expandMargin,
                        startAngle: CGFloat(-Double.pi * (2/3 + angle)),
                        endAngle: CGFloat(-Double.pi * (7/6 + angle)),
                        clockwise: true)
            animation.path = path
            btn.layer.add(animation, forKey: "start")
            
        }
        
        //changeBackCalor()
        nextImage = star
        currentPage -= 1
        
    }

}

extension RevolverMenuView: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        changeButtonItem()
    }
}
