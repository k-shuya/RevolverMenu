//
//  RevolverMenuView.swift
//  RevolverMenu
//
//  Created by 川村周也 on 2019/04/08.
//  Copyright © 2019 川村周也. All rights reserved.
//

import UIKit

public enum direction {
    case right
    case left
}

public protocol RevolverMenuViewDelegate: class {
    func didSelect(on menu: RevolverMenuView, index: Int)
}

public class RevolverMenuView: UIView {
    
    public weak var delegate: RevolverMenuViewDelegate?
    
    private var items: [RevolverMenuItem] = []
    private var buttons: [RevolverMenuItem]  = [RevolverMenuItem](repeating: RevolverMenuItem(), count: 12) {
        didSet {
            
        }
    }
    private var startButton: RevolverMenuItem = RevolverMenuItem()
    
    private var startPoint = CGPoint(x: UIScreen.main.bounds.width - 30, y: UIScreen.main.bounds.height - 30)
    
    private var isSelectedButton = false
    
    public var expandMargin: CGFloat = 120.0
    public var displayCount: Int = 4
    public var duration: TimeInterval = 0.4
    public var currentPage: Int = 0
    
    var setUserInteraction: ((Bool) -> Void)?
    
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.isUserInteractionEnabled = true
        
        reloadItems()
        
        enableAutoLayout()
        moveMenuButtonPosision()
        hiddenButton()
        
    }
    
    public convenience init(frame: CGRect, startItem: RevolverMenuItem, items:[RevolverMenuItem], direction: direction) {
        self.init(frame: frame)
        
        self.items = items
        self.startButton = startItem
        
        startButton.delegate = self
        
        switch direction {
        case .right:
            //startPoint = CGPoint(x: UIScreen.main.bounds.width - 30, y: UIScreen.main.bounds.height - 30)
            startPoint = CGPoint(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/2)
        case .left:
            startPoint = CGPoint(x: 30, y: UIScreen.main.bounds.height - 30)
        }
        
        initButtons(startItem: startItem, items: items)
        
    }
    
    private func initButtons(startItem: RevolverMenuItem, items:[RevolverMenuItem]){
        
        startItem.center = startPoint
        
        for (index, button) in buttons.enumerated() {
            self.addSubview(button)
            button.center = startPoint
            button.tag = index
            button.delegate = self
        }
        
        self.addSubview(startItem)
        
    }
    
    func initGesture(view: UIView) {
        
        let rightSwipe = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe(sender:)))
        let leftSwipe = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe(sender:)))
        let upSwipe = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe(sender:)))
        let downSwipe = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe(sender:)))
        
        rightSwipe.direction = .right
        view.addGestureRecognizer(rightSwipe)
        
        
        leftSwipe.direction = .left
        view.addGestureRecognizer(leftSwipe)
        
        upSwipe.direction = .up
        view.addGestureRecognizer(upSwipe)
        
        
        downSwipe.direction = .down
        view.addGestureRecognizer(downSwipe)
    }
    
    @objc func didSwipe(sender: UISwipeGestureRecognizer) {
        print(#function)
        if sender.direction == .right || sender.direction == .up {
            print("up")
            if currentPage != items.count/4 {
                rightAnimation()
            }
        }
        else if sender.direction == .left || sender.direction == .down {
            print("down")
            if currentPage != 0 {
                leftAnimation()
            }
        }
    }
    
    func createGestureView() {
        let clearFrame = CGRect(x: self.frame.width-250, y: self.frame.height-250, width: 250, height: 250)
        var allBtns = buttons
        allBtns.append(startButton)
        let clearView = SwipeView(frame: clearFrame, btns: allBtns)
        
        clearView.isUserInteractionEnabled = true
        /*
         crearView.alpha = 0.5
         crearView.backgroundColor = UIColor.black
         */
        clearView.parent = self
        
        initGesture(view: clearView)
        
        self.addSubview(clearView)
        //setUserInteraction?(false)
    }
    
    func removeGestureView() {
        self.subviews.last?.removeFromSuperview()
    }
    
    private func reloadItems() {
        buttons.removeAll()
        
        for index in (currentPage * 4 - 4)...(currentPage * 4 + 7) {
            if index < 0 {
                buttons.append(RevolverMenuItem())
            } else if index >= items.count {
                buttons.append(RevolverMenuItem())
            } else {
                buttons.append(items[index])
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
        startButton.translatesAutoresizingMaskIntoConstraints = true
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
        let angle = Double.pi * 2 / Double(displayCount * 3)
        return CGPoint(x: startPoint.x + expandMargin * CGFloat(cos(Double(index) * angle)), y: startPoint.y - expandMargin * CGFloat(sin(Double(index) * angle)))
    }
    
    /// ボタンをメニューの場所へ移動する
    private func moveMenuButtonPosision() {
        buttons.forEach { $0.center = startPoint }
    }
    
    func rightAnimation() {
        
        for (index, button) in buttons.enumerated() {
            button.layer.removeAnimation(forKey: "end")
            let animation: CAKeyframeAnimation = self.animation()
            let path: CGMutablePath = CGMutablePath()
            let stPoint: CGPoint = button.center
            let angle: Double = Double(index) / 6.0
            
            path.move(to: stPoint)
            path.addArc(center: startPoint,
                        radius: expandMargin,
                        startAngle: CGFloat(-Double.pi * (angle)),
                        endAngle: CGFloat(-Double.pi * (angle + 2/3)),
                        clockwise: false)
            animation.path = path
            button.layer.add(animation, forKey: "start")
        }
        
        //changeBackCalor()
        currentPage += 1
    }
    
    func leftAnimation() {
        
        for (index, button) in buttons.enumerated() {
            button.layer.removeAnimation(forKey: "end")
            let animation: CAKeyframeAnimation = self.animation()
            let path: CGMutablePath = CGMutablePath()
            let stPoint: CGPoint = button.center
            let angle: Double = Double(index) / 6.0
            
            path.move(to: stPoint)
            path.addArc(center: startPoint,
                        radius: expandMargin,
                        startAngle: CGFloat(-Double.pi * (angle)),
                        endAngle: CGFloat(-Double.pi * (angle + 2/3)),
                        clockwise: true)
            animation.path = path
            button.layer.add(animation, forKey: "start")
        }
        
        //changeBackCalor()
        currentPage -= 1
        
    }
    
    func animation() -> CAKeyframeAnimation {
        let animation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath: "position")
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false
        animation.duration = duration
        animation.delegate = self
        return animation
    }

}

extension RevolverMenuView: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        reloadItems()
    }
}

extension RevolverMenuView: RevolverMenuItemDelegate {
    public func tapped(on item: RevolverMenuItem) {
        if item == startButton {
            selectedTargetMenu()
        }
        
        if (3...6) ~= item.tag {
            delegate?.didSelect(on: self, index: item.tag - 3)
        }
    }
    
}
