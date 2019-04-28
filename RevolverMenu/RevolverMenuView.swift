//
//  RevolverMenuView.swift
//  RevolverMenu
//
//  Created by 川村周也 on 2019/04/08.
//  Copyright © 2019 川村周也. All rights reserved.
//

import UIKit

public enum direction {
    case upLeft
    case upRight
    case downLeft
    case downRight
}

enum rotate {
    case right
    case left
}

public protocol RevolverMenuViewDelegate: class {
    func didSelect(on menu: RevolverMenuView, index: Int)
    func willExpand()
    /*
     func rotateWillStart()
     func rotateDidStart()
     func willExpand()
     func didExpand()
     func willContract()
     func didContract()
     */
    
}

public class RevolverMenuView: UIView {
    
    public weak var delegate: RevolverMenuViewDelegate?
    
    struct CornerPoints {
        let upLeft: CGPoint = CGPoint(x: 35, y: 35)
        let upRight: CGPoint = CGPoint(x: UIScreen.main.bounds.width - 35, y: 35)
        let downLeft: CGPoint = CGPoint(x: 35, y: UIScreen.main.bounds.height - 35)
        let downRight: CGPoint = CGPoint(x: UIScreen.main.bounds.width - 35, y: UIScreen.main.bounds.height - 35)
        
        let center: CGPoint = CGPoint(x: UIScreen.main.bounds.width/2, y: UIScreen.main.bounds.height/2)
    }
    
    private var menuButton: RevolverMenuItem = RevolverMenuItem()
    
    private var menuCenter: CGPoint = CornerPoints().downRight {
        didSet {
            menuButton.center = menuCenter
        }
    }
    
    private var items: [RevolverMenuItem] = []
    private var buttons: [RevolverMenuItem] = (0 ..< 12).map({ _ in RevolverMenuItem() })
    
    private var currentPage: Int = 0
    private var isSelectedButton = false
    
    private var scrollerLayer = CAShapeLayer()
    private var circleLayer = CAShapeLayer()
    
    public var menuBorderColor: CGColor = UIColor.lightGray.cgColor
    public var menuScrollerCollor: CGColor = UIColor.darkGray.cgColor
    
    public var menuBorderWidth: CGFloat = 2
    public var displayCount: Int = 4
    public var expandMargin: CGFloat = 120.0
    public var rotateDuration: TimeInterval = 0.4
    
    public var setUserInteraction: ((Bool) -> Void)?
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.isUserInteractionEnabled = true
        
        enableAutoLayout()
        moveContractedPosision()
        hiddenButton()
    }
    
    public convenience init(frame: CGRect, menuItem: RevolverMenuItem, items: [RevolverMenuItem], direction: direction) {
        self.init(frame: frame)
        
        self.items = items
        self.menuButton = menuItem
        
        menuButton.delegate = self
        
        switch direction {
        case .upLeft:
            menuCenter = CornerPoints().upLeft
            
        case .upRight:
            menuCenter = CornerPoints().upRight
            
        case .downLeft:
            menuCenter = CornerPoints().downLeft
            
        case .downRight:
            menuCenter = CornerPoints().downRight
            //menuCenter = CornerPoints().center
            
        }
        
        reloadItems()
        initButtons()
    }
    
    private func drawSector() {
        circleLayer.removeFromSuperlayer()
        scrollerLayer.removeFromSuperlayer()
        
        let rad = menuButton.bounds.width/2 + menuBorderWidth
        
        let circlePath: UIBezierPath = UIBezierPath();
        circlePath.move(to: menuCenter)
        circlePath.addArc(withCenter: menuCenter,
                          radius: rad,
                          startAngle: 0,
                          endAngle: CGFloat(-Double.pi * 2.0),
                          clockwise: false)
        
        circleLayer.fillColor = menuBorderColor
        circleLayer.path = circlePath.cgPath
        
        self.layer.insertSublayer(circleLayer, at: 0)
        
        let angle: CGFloat = CGFloat(2.0 * Double.pi / ceil(Double(items.count)/4.0))
        let start: CGFloat = CGFloat(-Double.pi / 2.0) - angle * CGFloat(currentPage) // 開始の角度
        let end: CGFloat = start - angle // 終了の角度
        let path: UIBezierPath = UIBezierPath()
        let arcCenter: CGPoint = CGPoint(x: 25, y: 25)
        
        path.move(to: arcCenter)
        path.addArc(withCenter: arcCenter,
                    radius: rad,
                    startAngle: start,
                    endAngle: end,
                    clockwise: false)
        
        scrollerLayer.frame = CGRect(x: menuCenter.x-25, y: menuCenter.y-25, width: 50, height: 50)
        scrollerLayer.fillColor = menuScrollerCollor
        scrollerLayer.path = path.cgPath
        self.layer.insertSublayer(scrollerLayer, at: 1)
    }
    
    private func rotateScroller(_ direction: rotate) {
        let angle: CGFloat = CGFloat(2.0 * Double.pi / ceil(Double(items.count)/4.0))
        var fromVal: CGFloat = angle * CGFloat(currentPage)
        var toVal: CGFloat = angle * CGFloat(currentPage+1)
        
        if direction == .right {
            fromVal = -angle * CGFloat(currentPage)
            toVal = -angle * CGFloat(currentPage+1)
        } else {
            fromVal = -angle * CGFloat(currentPage)
            toVal = -angle * CGFloat(currentPage-1)
        }
        
        let animation: CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation")
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.fromValue = fromVal
        animation.toValue = toVal
        animation.duration = 0.2
        
        scrollerLayer.add(animation, forKey: "animation")
    }
    
    private func initButtons(){
        
        menuButton.center = menuCenter
        menuButton.borderWidth = 0
        
        for (index, button) in buttons.enumerated() {
            self.addSubview(button)
            button.center = menuCenter
            button.tag = index
            button.delegate = self
        }
        self.drawSector()
        self.addSubview(menuButton)
        
    }
    
    func initGesture(view: UIView) {
        let swipeDirections: [UISwipeGestureRecognizer.Direction] = [.right,.left, .up, .down]
        
        swipeDirections.forEach{
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe(sender:)))
            swipe.direction = $0
            view.addGestureRecognizer(swipe)
        }
    }
    
    @objc func didSwipe(sender: UISwipeGestureRecognizer) {
        if sender.direction == .right || sender.direction == .up {
            if currentPage != Int(ceil(Double(items.count)/4.0) - 1) {
                reloadItems()
                //rightAnimation()
                rotateAnimation(.right)
            }
        } else if sender.direction == .left || sender.direction == .down {
            if currentPage != 0 {
                reloadItems()
                //leftAnimation()
                rotateAnimation(.left)
            }
        }
    }
    
    func createGestureView() {
        let clearFrame = CGRect(x: self.frame.width-250, y: self.frame.height-250, width: 250, height: 250)
        var allBtns = buttons
        allBtns.append(menuButton)
        
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
        var positions: [CGPoint] = []
        buttons.forEach {
            positions.append($0.center)
            $0.removeFromSuperview()
            
        }
        for itemIndex in (currentPage * 4 - 4)...(currentPage * 4 + 7) {
            
            let index = itemIndex-(currentPage * 4 - 4)
            
            if itemIndex < 0 || itemIndex >= items.count {
                buttons[index] = RevolverMenuItem()
            } else {
                buttons[index] = items[itemIndex]
            }
            buttons[index].center = positions[index]
            buttons[index].tag = index
            buttons[index].delegate = self
        }
        //initButtons(startItem: menuButton)
        buttons.forEach { self.insertSubview($0, belowSubview: menuButton) }
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
                self.moveContractedPosision()
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
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.4, options: .curveEaseIn, animations: {
                self.moveExpandedPosision()
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
    
    /// ボタンを広げる
    private func moveExpandedPosision() {
        buttons.forEach{
            if (4...7) ~= $0.tag {
                $0.center = calcExpandedPosition($0.tag)
            }
        }
    }
    
    private func calcExpandedPosition(_ index: Int) -> CGPoint {
        let angle = Double.pi * 2 / Double(displayCount * 3) // 2π ÷ ボタンの個数 = ボタン同士の角度
        return CGPoint(x: menuCenter.x + expandMargin * CGFloat(cos(Double(index-1) * angle)), y: menuCenter.y - expandMargin * CGFloat(sin(Double(index-1) * angle)))
    }
    
    private func moveContractedPosision() {
        buttons.forEach { $0.center = menuCenter }
    }
    
    func rotateAnimation(_ direction: rotate){
        var paging: () -> Void
        var movement: Double = 0
        var isClockwise: Bool = true
        
        if direction == .right {
            paging = { self.currentPage += 1 }
            movement = -2/3
            isClockwise = false
        } else {
            paging = { self.currentPage -= 1 }
            movement = 2/3
            isClockwise = true
        }
        
        for (index, button) in buttons.enumerated() {
            button.layer.removeAnimation(forKey: "end")
            let animation: CAKeyframeAnimation = self.animation()
            let path: CGMutablePath = CGMutablePath()
            let stPoint: CGPoint = button.center
            let angle: Double = Double(index-1) / 6.0
            
            path.move(to: stPoint)
            path.addArc(center: menuCenter,
                        radius: expandMargin,
                        startAngle: CGFloat(-Double.pi * (angle)),
                        endAngle: CGFloat(-Double.pi * (angle + movement)),
                        clockwise: isClockwise)
            animation.path = path
            button.layer.add(animation, forKey: "start")
        }
        rotateScroller(direction)
        paging()
    }
    
    func animation() -> CAKeyframeAnimation {
        let animation: CAKeyframeAnimation = CAKeyframeAnimation(keyPath: "position")
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.isRemovedOnCompletion = false
        animation.duration = rotateDuration
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
        if item == menuButton {
            selectedTargetMenu()
        }
        
        if (4...7) ~= item.tag && (currentPage * 4 + (item.tag - 4)) < items.count {
            delegate?.didSelect(on: self, index: currentPage * 4 + (item.tag - 4))
        }
    }
    
}
