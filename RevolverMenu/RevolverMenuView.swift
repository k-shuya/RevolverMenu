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
    func willExpand()
}

public class RevolverMenuView: UIView {
    
    public weak var delegate: RevolverMenuViewDelegate?
    
    private var items: [RMItemImage] = []
    private var buttons: [RevolverMenuItem] = (0 ..< 12).map({ _ in RevolverMenuItem() })
    private var startButton: RevolverMenuItem = RevolverMenuItem()
    
    private var startPoint = CGPoint(x: UIScreen.main.bounds.width - 30, y: UIScreen.main.bounds.height - 30)
    
    private var isSelectedButton = false
    
    public var expandMargin: CGFloat = 120.0
    public var displayCount: Int = 4
    public var duration: TimeInterval = 0.4
    public var currentPage: Int = 0
    
    private var scrollerLayer = CAShapeLayer()
    
    public var setUserInteraction: ((Bool) -> Void)?
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.isUserInteractionEnabled = true
        
        enableAutoLayout()
        moveMenuButtonPosision()
        hiddenButton()
    }
    
    public convenience init(frame: CGRect, startItem: RevolverMenuItem, items: [RMItemImage], direction: direction) {
        self.init(frame: frame)
        
        self.items = items
        self.startButton = startItem
        
        startButton.delegate = self
        
        switch direction {
        case .right:
            startPoint = CGPoint(x: UIScreen.main.bounds.width - 35, y: UIScreen.main.bounds.height - 35)
            // startPoint = CGPoint(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/2)
        case .left:
            startPoint = CGPoint(x: 30, y: UIScreen.main.bounds.height - 30)
        }
        
        reloadItems()
        initButtons(startItem: startItem)
        
    }
    
    private func drawSector() {
        scrollerLayer.removeFromSuperlayer()
        let angle = (2.0 * Double.pi / ceil(Double(items.count)/4.0))
        let start: CGFloat = CGFloat(-Double.pi / 2.0 - angle * Double(currentPage)) // 開始の角度
        let end: CGFloat = CGFloat(-Double.pi / 2.0 - angle * Double(currentPage+1)) // 終了の角度
        
        let path: UIBezierPath = UIBezierPath();
        path.move(to: startPoint)
        path.addArc(withCenter: startPoint,
                    radius: 27,
                    startAngle: start,
                    endAngle: end,
                    clockwise: false)
        
        scrollerLayer.fillColor = UIColor.cyan.cgColor
        scrollerLayer.path = path.cgPath
        
        self.layer.insertSublayer(scrollerLayer, at: 1)
    }
    
    private func initButtons(startItem: RevolverMenuItem){
        
        let circleLayer = CAShapeLayer()
        let path: UIBezierPath = UIBezierPath();
        path.move(to: startPoint)
        path.addArc(withCenter: startPoint,
                    radius: 27,
                    startAngle: 0,
                    endAngle: CGFloat(-Double.pi * 2.0),
                    clockwise: false)
        
        circleLayer.fillColor = UIColor.lightGray.cgColor
        circleLayer.path = path.cgPath
        
        startItem.center = startPoint
        startItem.backgroundColor = UIColor.black
        
        for (index, button) in buttons.enumerated() {
            self.addSubview(button)
            button.center = startPoint
            button.tag = index
            button.delegate = self
        }
        self.layer.insertSublayer(circleLayer, at: 0)
        self.drawSector()
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
        if sender.direction == .right || sender.direction == .up {
            if currentPage != Int(ceil(Double(items.count)/4.0) - 1) {
                reloadItems()
                rightAnimation()
            }
        }
        else if sender.direction == .left || sender.direction == .down {
            if currentPage != 0 {
                reloadItems()
                leftAnimation()
            }
        }
        drawSector()
    }
    
    func createGestureView() {
        let clearFrame = CGRect(x: self.frame.width-250, y: self.frame.height-250, width: 250, height: 250)
        var allBtns = buttons
        allBtns.append(startButton)
        
        let clearView = SwipeView(frame: clearFrame, btns: allBtns)
        
        clearView.isUserInteractionEnabled = true
        clearView.parent = self
        
        initGesture(view: clearView)
        
        self.addSubview(clearView)
        //setUserInteraction?(false)
    }
    
    func removeGestureView() {
        self.subviews.last?.removeFromSuperview()
    }
    
    private func reloadItems() {
        for index in (currentPage * 4 - 4)...(currentPage * 4 + 7) {
            if index < 0 {
                buttons[index-(currentPage * 4 - 4)].setItem(image: RMItemImage())
            } else if index >= items.count {
                buttons[index-(currentPage * 4 - 4)].setItem(image: RMItemImage())
            } else {
                buttons[index-(currentPage * 4 - 4)].setItem(image: items[index])
            }
        }
    }
    
    /// メニューを押下
    private func selectedTargetMenu() {
        // 残っているアニメーションを無効化
        buttons.forEach{ $0.layer.removeAllAnimations() }
        reloadItems()
        
        if isSelectedButton {
            buttons.forEach{
                guard (4...7) ~= $0.tag else {
                    $0.alpha = 0
                    return
                }
            }
            UIView.animate(withDuration: 0.25, animations: {
                self.moveMenuButtonPosision()
                self.hiddenButton()
                self.removeGestureView()
            })
        } else {
            buttons.forEach{
                guard (4...7) ~= $0.tag else {
                    $0.center = calcExpandedPosition($0.tag)
                    return
                }
            }
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.3, options: .curveEaseIn, animations: {
                self.moveDefaultButtonPosision()
                self.showButton()
                self.createGestureView()
            })
        }
        isSelectedButton = !isSelectedButton
        //setUserInteraction?(!isSelectedButton)
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
    
    /// ボタンを広げる
    private func moveDefaultButtonPosision() {
        buttons.forEach{
            if (4...7) ~= $0.tag {
                $0.center = calcExpandedPosition($0.tag)
            }
        }
    }
    
    private func calcExpandedPosition(_ index: Int) -> CGPoint {
        let angle = Double.pi * 2 / Double(displayCount * 3) // 2π ÷ ボタンの個数 = ボタン同士の角度
        return CGPoint(x: startPoint.x + expandMargin * CGFloat(cos(Double(index-1) * angle)), y: startPoint.y - expandMargin * CGFloat(sin(Double(index-1) * angle)))
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
            let angle: Double = Double(index-1) / 6.0
            
            path.move(to: stPoint)
            path.addArc(center: startPoint,
                        radius: expandMargin,
                        startAngle: CGFloat(-Double.pi * (angle)),
                        endAngle: CGFloat(-Double.pi * (angle - 2/3)),
                        clockwise: false)
            animation.path = path
            button.layer.add(animation, forKey: "start")
        }
        currentPage += 1
    }
    
    func leftAnimation() {
        for (index, button) in buttons.enumerated() {
            button.layer.removeAnimation(forKey: "end")
            let animation: CAKeyframeAnimation = self.animation()
            let path: CGMutablePath = CGMutablePath()
            let stPoint: CGPoint = button.center
            let angle: Double = Double(index-1) / 6.0
            
            path.move(to: stPoint)
            path.addArc(center: startPoint,
                        radius: expandMargin,
                        startAngle: CGFloat(-Double.pi * (angle)),
                        endAngle: CGFloat(-Double.pi * (angle + 2/3)),
                        clockwise: true)
            animation.path = path
            button.layer.add(animation, forKey: "start")
        }
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
    @objc func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
    }
}

extension RevolverMenuView: RevolverMenuItemDelegate {
    public func tapped(on item: RevolverMenuItem) {
        if item == startButton {
            selectedTargetMenu()
            self.layoutIfNeeded()
        }
        
        if (4...7) ~= item.tag {
            delegate?.didSelect(on: self, index: currentPage * 4 + (item.tag - 4))
        }
    }
    
}
