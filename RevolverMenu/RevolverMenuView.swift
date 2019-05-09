//
//  RevolverMenuView.swift
//  RevolverMenu
//
//  Created by 川村周也 on 2019/04/08.
//  Copyright © 2019 川村周也. All rights reserved.
//

import UIKit

public enum Direction: Int {
    case downRight
    case downLeft
    case upRight
    case upLeft
}

enum Rotate: Int {
    case right = 1
    case left = -1
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
    
    struct ReferencePoints {
        var downRight: CGPoint
        var downLeft: CGPoint
        var upRight: CGPoint
        var upLeft: CGPoint
        var center: CGPoint
    }
    
    private var menuButton: RevolverMenuItem = RevolverMenuItem()
    
    private var menuCenter: CGPoint = CGPoint.zero {
        didSet {
            menuButton.center = menuCenter
        }
    }
    
    private var items: [RevolverMenuItem] = []
    private var emptyItems: [RevolverMenuItem] = []
    private var buttons: [RevolverMenuItem] = []
    
    private var direction: Direction = .downRight
    private var pagingNext: Rotate = .right
    private var pagingBack: Rotate = .left
    
    private var displayCount: Int = 4 {
        didSet {
            if displayCount < 1 {
                displayCount = 1
            } else if displayCount > 4 {
                displayCount = 4
            }
        }
    }
    
    private var startAngle: CGFloat = 0
    private var interval: CGFloat = 0
    
    private var currentPage: Int = 0
    private var isSelectedButton = false
    
    private let angles: [[(startAngle: CGFloat, interval: CGFloat)]] = [
        [(0.0, 0.0), (1.0/4.0, 1.0/2.0), (-1.0/12.0, 1.0/3.0), (-1.0/4.0, 1.0/4.0), (-1.0/6.0, 1.0/6.0)],
        [(0.0, 0.0), (3.0/4.0, -1.0/2.0), (13.0/12.0, -1.0/3.0), (-3.0/4.0, -1.0/4.0), (-5.0/6.0, -1.0/6.0)],
        [(0.0, 0.0), (3.0/4.0, 1.0/2.0), (5.0/12.0, 1.0/3.0), (1.0/4.0, 1.0/4.0), (1.0/3.0, 1.0/6.0)],
        [(0.0, 0.0), (1.0/4.0, -1.0/2.0), (7.0/12.0, -1.0/3.0), (3.0/4.0, -1.0/4.0), (2.0/3.0, -1.0/6.0)],
    ]
    
    private var scrollerLayer = CAShapeLayer()
    
    private var scrollerView = UIView()
    
    private var referencePoints: ReferencePoints!
    
    public var menuBorderColor: CGColor = UIColor.lightGray.cgColor
    public var menuScrollerCollor: CGColor = UIColor.darkGray.cgColor
    
    public var menuBorderWidth: CGFloat = 2
    
    public var expandMargin: CGFloat = 120.0
    public var rotateDuration: TimeInterval = 0.4
    
    public var setUserInteraction: ((Bool) -> Void)?
    
    // MARK: - init()
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
        let downRight: CGPoint = CGPoint(x: frame.width - 35, y: frame.height - 35)
        let downLeft: CGPoint = CGPoint(x: 35, y: frame.height - 35)
        let upRight: CGPoint = CGPoint(x: frame.width - 35, y: 35)
        let upLeft: CGPoint = CGPoint(x: 35, y: 35)
        let center: CGPoint = CGPoint(x: frame.width/2, y: frame.height/2)
        
        self.referencePoints = ReferencePoints(downRight: downRight,
                                               downLeft: downLeft,
                                               upRight: upRight,
                                               upLeft: upLeft,
                                               center: center)
        
        self.isUserInteractionEnabled = true
        
        enableAutoLayout()
        moveContractedPoint()
        hiddenButton()
    }
    
    public convenience init(frame: CGRect, menuItem: RevolverMenuItem, items: [RevolverMenuItem], displayCount: Int, direction: Direction) {
        self.init(frame: frame)
        
        self.items = items
        self.menuButton = menuItem
        self.direction = direction
        
        initDisplayCount(displayCount)
        
        self.startAngle = angles[self.direction.rawValue][self.displayCount].startAngle
        self.interval = angles[self.direction.rawValue][self.displayCount].interval
        
        self.buttons = (0 ..< self.displayCount * 3).map({ _ in RevolverMenuItem() })
        self.emptyItems = (0 ..< displayCount - (items.count%displayCount)).map({ _ in RevolverMenuItem(backgroundColor: UIColor.white) })
        
        menuButton.delegate = self
        
        switch self.direction {
        case .downRight:
            menuCenter = referencePoints.downRight
           // menuCenter = referencePoints.center
        case .downLeft:
            menuCenter = referencePoints.downLeft
            //menuCenter = referencePoints.center
        case .upRight:
            menuCenter = referencePoints.upRight
            //menuCenter = referencePoints.center
        case .upLeft:
            menuCenter = referencePoints.upLeft
            //menuCenter = referencePoints.center
        }
        
        if direction == .downRight || direction == .upRight {
            pagingNext = .right
            pagingBack = .left
        } else {
            pagingNext = .left
            pagingBack = .right
        }
        
        reloadItems()
        initButtons()
        initPanGesture(view: self)
    }
    
    private func initDisplayCount(_ displayCount: Int) {
        self.displayCount = displayCount
    }
    
    private func initButtons(){
        menuButton.center = menuCenter
        menuButton.tag = 1000
        menuButton.borderWidth = 0
        
        for (index, button) in buttons.enumerated() {
            self.addSubview(button)
            button.center = menuCenter
            button.tag = index
            button.delegate = self
        }
        self.drawScroller()
        self.addSubview(menuButton)
    }
    
    private func replaceButtons(_ direction: Direction){
        self.subviews.forEach{ $0.removeFromSuperview() }
        
        self.startAngle = angles[self.direction.rawValue][self.displayCount].startAngle
        self.interval = angles[self.direction.rawValue][self.displayCount].interval
        
        switch direction {
        case .downRight:
            menuCenter = referencePoints.downRight
        case .downLeft:
            menuCenter = referencePoints.downLeft
        case .upRight:
            menuCenter = referencePoints.upRight
        case .upLeft:
            menuCenter = referencePoints.upLeft
        }
        
        if direction == .downRight || direction == .upRight {
            pagingNext = .right
            pagingBack = .left
        } else {
            pagingNext = .left
            pagingBack = .right
        }
        
        reloadItems()
        initButtons()
    }
    
    // MARK: - Scroller
    
    private func drawScroller() {
        
        scrollerView = UIView(frame: CGRect(x: menuCenter.x-25, y: menuCenter.y-25, width: 50, height: 50))
        
        let circleLayer = CAShapeLayer()
        
        let rad = menuButton.bounds.width/2 + menuBorderWidth
        let arcCenter: CGPoint = CGPoint(x: 25, y: 25)
        
        let circlePath: UIBezierPath = UIBezierPath();
        circlePath.move(to: arcCenter)
        circlePath.addArc(withCenter: arcCenter,
                          radius: rad,
                          startAngle: 0,
                          endAngle: CGFloat.pi * 2.0,
                          clockwise: true)
        
        circleLayer.fillColor = menuBorderColor
        circleLayer.path = circlePath.cgPath
        
        scrollerView.layer.insertSublayer(circleLayer, at: 0)
        
        let angle: CGFloat = 2.0 * CGFloat.pi / ceil(CGFloat(items.count)/CGFloat(displayCount))
        let start: CGFloat = -CGFloat.pi / 2.0 * cos(CGFloat.pi * CGFloat(direction.rawValue/2))
        let end: CGFloat = start - angle * cos(CGFloat.pi * CGFloat(direction.rawValue%2 + direction.rawValue/2))
        let path: UIBezierPath = UIBezierPath()
        
        var isClockwise: Bool = true
        
        if direction == .downRight || direction == .upLeft {
            isClockwise = false
        }
        
        path.move(to: arcCenter)
        path.addArc(withCenter: arcCenter,
                    radius: rad,
                    startAngle: start,
                    endAngle: end,
                    clockwise: isClockwise)
        
        scrollerLayer.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        scrollerLayer.fillColor = menuScrollerCollor
        scrollerLayer.path = path.cgPath
        
        scrollerView.layer.insertSublayer(scrollerLayer, at: 1)
        
        self.insertSubview(scrollerView, at: 0)
    }
    
    private func rotateScroller(_ rotateDirection: Rotate) {
        scrollerLayer.removeAllAnimations()
        let angle: CGFloat = 2.0 * CGFloat.pi / ceil(CGFloat(items.count)/CGFloat(displayCount))
        let fromVal: CGFloat = -angle * CGFloat(currentPage) * CGFloat(pagingNext.rawValue)
        let toVal: CGFloat = fromVal + angle * CGFloat(rotateDirection.rawValue)
        
        let animation: CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation")
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.fromValue = fromVal
        animation.toValue = toVal
        animation.duration = 0.2
        
        scrollerLayer.add(animation, forKey: "animation")
    }
    
    // MARK: - GestureView
    
    func initSwipeGesture(view: UIView) {
        let swipeDirections: [UISwipeGestureRecognizer.Direction] = [.right,.left, .up, .down]
        
        swipeDirections.forEach{
            let swipe = UISwipeGestureRecognizer(target: self, action: #selector(didSwipe(sender:)))
            swipe.direction = $0
            view.addGestureRecognizer(swipe)
        }
    }
    
    func createGestureView() {
        let clearFrame = CGRect(x: self.frame.width-250, y: self.frame.height-250, width: 250, height: 250)
        var allBtns = buttons
        allBtns.append(menuButton)
        
        let clearView = SwipeView(frame: clearFrame, btns: allBtns)
        
        clearView.isUserInteractionEnabled = true
        clearView.parent = self
        
        initSwipeGesture(view: clearView)
        
        self.addSubview(clearView)
        //setUserInteraction?(false)
    }
    
    func removeGestureView() {
        self.subviews.last?.removeFromSuperview()
    }
    
    @objc func didSwipe(sender: UISwipeGestureRecognizer) {
        
        var rotateDirection: Rotate = .right
        let lastPage: Int = Int(ceil(Double(items.count)/Double(displayCount)) - 1)
        
        switch sender.direction {
        case .up:
            rotateDirection = pagingNext
        case .down:
            rotateDirection = pagingBack
        case .right:
            if direction == .downRight || direction == .upLeft {
                rotateDirection = pagingNext
            } else {
                rotateDirection = pagingBack
            }
        case .left:
            if direction == .downLeft || direction == .upRight {
                rotateDirection = pagingNext
            } else {
                rotateDirection = pagingBack
            }
        default:
            break
        }
        
        if (rotateDirection == pagingNext && currentPage == lastPage) ||
            (rotateDirection == pagingBack && currentPage == 0) {
            return
        } else {
            self.rotateAnimation(rotateDirection)
        }
    }
    
    // MARK: - ReloadItems()
    private func reloadItems() {
        var positions: [CGPoint] = []
        buttons.forEach {
            positions.append($0.center)
            $0.removeFromSuperview()
        }
        items.forEach{ $0.layer.removeAllAnimations() }
        emptyItems.forEach{ $0.layer.removeAllAnimations() }
        for itemIndex in (displayCount * (currentPage - 1))...(displayCount * (currentPage + 2) - 1) {
            let index = itemIndex-(displayCount * (currentPage - 1))
            if itemIndex < 0 || itemIndex >= items.count + items.count%displayCount {
                buttons[index] = RevolverMenuItem(backgroundColor: UIColor.white)
            } else if itemIndex < items.count {
                buttons[index] = items[itemIndex]
            } else {
                buttons[index] = emptyItems[itemIndex-items.count]
            }
            buttons[index].center = positions[index]
            buttons[index].tag = index
            buttons[index].delegate = self
        }
        buttons.forEach {
            //$0.layer.removeAllAnimations()
            self.insertSubview($0, belowSubview: menuButton)
        }
    }
    
    // MARK: - メニューを押下
    
    private func selectedTargetMenu() {
        // 残っているアニメーションを無効化
        buttons.forEach{ $0.layer.removeAllAnimations() }
        reloadItems()
        
        if isSelectedButton {
            buttons.forEach{
                guard (displayCount...(2 * displayCount - 1)) ~= $0.tag else {
                    $0.alpha = 0
                    return
                }
            }
            UIView.animate(withDuration: 0.25, animations: {
                self.moveContractedPoint()
                self.hiddenButton()
                self.removeGestureView()
            })
        } else {
            buttons.forEach{
                guard (displayCount...(2 * displayCount - 1)) ~= $0.tag else {
                    $0.center = calcExpandedPoint($0.tag)
                    $0.alpha = 0
                    return
                }
            }
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.4, initialSpringVelocity: 0.4, options: .curveEaseIn, animations: {
                self.moveExpandedPoint()
                self.showButton()
                self.createGestureView()
            })
        }
        isSelectedButton = !isSelectedButton
        //setUserInteraction?(!isSelectedButton)
    }
    
    // MARK: - ボタンの開閉
    // AutoLayoutを有効にする
    private func enableAutoLayout() {
        buttons.forEach { $0.translatesAutoresizingMaskIntoConstraints = true }
        menuButton.translatesAutoresizingMaskIntoConstraints = true
    }
    
    private func showButton() {
        hiddenButton()
        buttons.forEach {
            if (displayCount...(2 * displayCount - 1)) ~= $0.tag {
                $0.alpha = 1
            }
        }
    }
    
    private func hiddenButton() {
        buttons.forEach { $0.alpha = 0 }
    }
    
    private func moveExpandedPoint() {
        buttons.forEach{
            if (displayCount...(2 * displayCount - 1)) ~= $0.tag {
                $0.center = calcExpandedPoint($0.tag)
            }
        }
    }
    
    private func calcExpandedPoint(_ index: Int) -> CGPoint {
        let x_position = menuCenter.x + expandMargin * cos((startAngle + CGFloat(index) * interval) * CGFloat.pi)
        let y_position = menuCenter.y - expandMargin * sin((startAngle + CGFloat(index) * interval) * CGFloat.pi)
        
        return CGPoint(x: x_position, y: y_position)
    }
    
    private func moveContractedPoint() {
        buttons.forEach { $0.center = menuCenter }
    }
    
    func rotateAnimation(_ rotateDirection: Rotate){
        var paging: () -> Void
        let movement: CGFloat = interval * CGFloat(displayCount) * CGFloat(rotateDirection.rawValue * -pagingNext.rawValue) 
        var isClockwise: Bool = true
        
        if rotateDirection == .right {
            paging = { self.currentPage += self.pagingNext.rawValue }
            isClockwise = false
        } else {
            paging = { self.currentPage += self.pagingBack.rawValue }
            isClockwise = true
        }
        
        if rotateDirection == pagingNext {
            self.bringSubviewToFront(buttons.last!)
        } else {
            self.bringSubviewToFront(buttons.first!)
        }
        
        // showButtonsによって他のボタンが消されている場合必要
        buttons.forEach{ $0.alpha = 1 }
        
        for (index, button) in buttons.enumerated() {
            button.layer.removeAnimation(forKey: "rotate")
            let animation: CAKeyframeAnimation = self.animation()
            let path: CGMutablePath = CGMutablePath()
            let stPoint: CGPoint = button.center
            let angle: CGFloat = startAngle + CGFloat(index) * interval
            
            path.move(to: stPoint)
            path.addArc(center: menuCenter,
                        radius: expandMargin,
                        startAngle: -CGFloat.pi * (angle),
                        endAngle: -CGFloat.pi * (angle + movement),
                        clockwise: isClockwise)
            animation.path = path
            button.layer.add(animation, forKey: "rotate")
        }
        rotateScroller(Rotate(rawValue: rotateDirection.rawValue * -1)!)
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

extension RevolverMenuView {
    func initPanGesture(view: UIView) {
        let pan = UIPanGestureRecognizer(target: self, action: #selector(drag(sender:)))
        menuButton.addGestureRecognizer(pan)
    }
    
    @objc func drag(sender: UIPanGestureRecognizer) {
        //移動量を取得する。
        let move: CGPoint = sender.translation(in: self)
        
        if sender.state == .began {
            hiddenButton()
            if isSelectedButton {
                selectedTargetMenu()
            }
        }
        
        if sender.state == .ended {
            
            let downRightRange: CGRect = CGRect(x: referencePoints.center.x, y: referencePoints.center.y, width: referencePoints.center.x, height: referencePoints.center.y)
            let downLeftRange: CGRect = CGRect(x: 0, y: referencePoints.center.y, width: referencePoints.center.x, height: referencePoints.center.y)
            let upRightRange: CGRect = CGRect(x: referencePoints.center.x, y: 0, width: referencePoints.center.x, height: referencePoints.center.y)
            let upLeftRange: CGRect = CGRect(x: 0, y: 0, width: referencePoints.center.x, height: referencePoints.center.y)
            
            var targetPoint: CGPoint = referencePoints.downRight
            var targetDirection: Direction = .downRight
            
            if downRightRange.contains(sender.view!.center) {
                targetPoint = referencePoints.downRight
                targetDirection = .downRight
            } else if downLeftRange.contains(sender.view!.center) {
                targetPoint = referencePoints.downLeft
                targetDirection = .downLeft
            } else if upRightRange.contains(sender.view!.center) {
                targetPoint = referencePoints.upRight
                targetDirection = .upRight
            } else if upLeftRange.contains(sender.view!.center) {
                targetPoint = referencePoints.upLeft
                targetDirection = .upLeft
            }
            
            UIView.animate(withDuration: 0.3, animations: {
                sender.view!.center.x = targetPoint.x
                sender.view!.center.y = targetPoint.y
                self.scrollerView.center.x = targetPoint.x
                self.scrollerView.center.y = targetPoint.y
            }, completion: { finished in
                self.menuCenter = targetPoint
                self.direction = targetDirection
                self.replaceButtons(targetDirection)
            })
        }
        
        //ドラッグした部品の座標に移動量を加算する。
        sender.view!.center.x += move.x
        sender.view!.center.y += move.y
        scrollerView.center.x += move.x
        scrollerView.center.y += move.y
        
        //移動量を0にする。
        sender.setTranslation(CGPoint.zero, in: self)
    }
}

// MARK: - delegate

extension RevolverMenuView: CAAnimationDelegate {
    @objc func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        if anim == buttons.last!.layer.animation(forKey: "rotate") {
            reloadItems()
            //buttons.forEach{ $0.alpha = 1 }
            showButton()
        }
    }
}

extension RevolverMenuView: RevolverMenuItemDelegate {
    public func tapped(on item: RevolverMenuItem) {
        if item == menuButton {
            selectedTargetMenu()
        }
        
        if (displayCount...(2 * displayCount - 1)) ~= item.tag && (currentPage * displayCount + (item.tag - displayCount)) < items.count {
            delegate?.didSelect(on: self, index: currentPage * displayCount + (item.tag - displayCount))
        }
    }
    
}
