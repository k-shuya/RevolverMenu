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
        [(0.0, 0.0), (1.0/4.0, -1.0/2.0), (7.0/12.0, -1.0/3.0), (3.0/4.0, -1.0/4.0), (1.0/3.0, -1.0/6.0)],
    ]
    
    private var scrollerLayer = CAShapeLayer()
    private var circleLayer = CAShapeLayer()
    
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
        
        menuButton.delegate = self
        
        switch self.direction {
        case .downRight:
            //menuCenter = CornerPoints().downRight
            menuCenter = CornerPoints().center
        case .downLeft:
            menuCenter = CornerPoints().downLeft
            //menuCenter = CornerPoints().center
        case .upRight:
            menuCenter = CornerPoints().upRight
        case .upLeft:
            menuCenter = CornerPoints().upLeft
        }
        
        if self.direction.rawValue%2 == 0 {
            pagingNext = .right
            pagingBack = .left
        } else {
            pagingNext = .left
            pagingBack = .right
        }
        
        reloadItems()
        initButtons()
    }
    
    private func initDisplayCount(_ displayCount: Int) {
        self.displayCount = displayCount
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
        self.drawScroller()
        self.addSubview(menuButton)
    }
    
    // MARK: - Scroller
    
    private func drawScroller() {
        circleLayer.removeFromSuperlayer()
        scrollerLayer.removeFromSuperlayer()
        
        let rad = menuButton.bounds.width/2 + menuBorderWidth
        
        let circlePath: UIBezierPath = UIBezierPath();
        circlePath.move(to: menuCenter)
        circlePath.addArc(withCenter: menuCenter,
                          radius: rad,
                          startAngle: 0,
                          endAngle: CGFloat.pi * 2.0,
                          clockwise: true)
        
        circleLayer.fillColor = menuBorderColor
        circleLayer.path = circlePath.cgPath
        
        self.layer.insertSublayer(circleLayer, at: 0)
        
        let angle: CGFloat = 2.0 * CGFloat.pi / ceil(CGFloat(items.count)/CGFloat(displayCount))
        let start: CGFloat = -CGFloat.pi / 2.0 * -cos(CGFloat.pi * CGFloat(direction.rawValue/2))
        let end: CGFloat = start - angle * CGFloat(pagingNext.rawValue)
        let path: UIBezierPath = UIBezierPath()
        let arcCenter: CGPoint = CGPoint(x: 25, y: 25)
        
        path.move(to: arcCenter)
        path.addArc(withCenter: arcCenter,
                    radius: rad,
                    startAngle: start,
                    endAngle: end,
                    clockwise: true)
        
        scrollerLayer.frame = CGRect(x: menuCenter.x-25, y: menuCenter.y-25, width: 50, height: 50)
        scrollerLayer.fillColor = menuScrollerCollor
        scrollerLayer.path = path.cgPath
        self.layer.insertSublayer(scrollerLayer, at: 1)
    }
    
    private func rotateScroller(_ rotateDirection: Rotate) {
        scrollerLayer.removeAllAnimations()
        print(currentPage)
        let angle: CGFloat = 2.0 * CGFloat.pi / ceil(CGFloat(items.count)/CGFloat(displayCount))
        let fromVal: CGFloat = -angle * CGFloat(currentPage)
        let toVal: CGFloat = -angle * CGFloat(currentPage + rotateDirection.rawValue)
        
        let animation: CABasicAnimation = CABasicAnimation(keyPath: "transform.rotation")
        animation.isRemovedOnCompletion = false
        animation.fillMode = CAMediaTimingFillMode.forwards
        animation.fromValue = fromVal
        animation.toValue = toVal
        animation.duration = 0.2
        
        scrollerLayer.add(animation, forKey: "animation")
    }
    
    // MARK: - GestureView
    
    func initGesture(view: UIView) {
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
        
        initGesture(view: clearView)
        
        self.addSubview(clearView)
        //setUserInteraction?(false)
    }
    
    func removeGestureView() {
        self.subviews.last?.removeFromSuperview()
    }
    
    @objc func didSwipe(sender: UISwipeGestureRecognizer) {
        
        var rotateDirection: Rotate = .right
        
        switch sender.direction {
        case .up:
            rotateDirection = pagingNext
        case .down:
            rotateDirection = pagingBack
        case .right:
            if direction.rawValue/2 == direction.rawValue%2 {
                rotateDirection = pagingNext
            } else {
                rotateDirection = pagingBack
            }
        case .left:
            if direction.rawValue/2 != direction.rawValue%2 {
                rotateDirection = pagingNext
            } else {
                rotateDirection = pagingBack
            }
        default:
            break
        }
        
        if (rotateDirection == pagingNext && currentPage == Int(ceil(Double(items.count)/Double(displayCount)) - 1)) || (rotateDirection == pagingBack && currentPage == 0) {
            return
        } else {
            reloadItems()
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
        for itemIndex in (displayCount * (currentPage - 1))...(displayCount * (currentPage + 2) - 1) {
            
            let index = itemIndex-(displayCount * (currentPage - 1))
            
            if itemIndex < 0 || itemIndex >= items.count {
                buttons[index] = RevolverMenuItem(backgroundColor: UIColor.white)
            } else {
                buttons[index] = items[itemIndex]
            }
            buttons[index].center = positions[index]
            buttons[index].tag = index
            buttons[index].delegate = self
        }
        buttons.forEach { self.insertSubview($0, belowSubview: menuButton) }
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
    
    /// AutoLayoutを有効にする
    private func enableAutoLayout() {
        buttons.forEach { $0.translatesAutoresizingMaskIntoConstraints = true }
        menuButton.translatesAutoresizingMaskIntoConstraints = true
    }
    
    private func showButton() {
        buttons.forEach { $0.alpha = 1 }
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
            //movement = interval * CGFloat(displayCount) * CGFloat(rotateDirection.rawValue)
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
        rotateScroller(rotateDirection)
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

// MARK: - delegate

extension RevolverMenuView: CAAnimationDelegate {
    @objc func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        buttons.forEach{
            if anim == $0.layer.animation(forKey: "rotate") {
                //reloadItems({})
            }
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
