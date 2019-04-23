//
//  RevolverMenuItem.swift
//  RevolverMenu
//
//  Created by 川村周也 on 2019/04/08.
//  Copyright © 2019 川村周也. All rights reserved.
//

import UIKit

public protocol RevolverMenuItemDelegate: class {
    func tapped(on item: RevolverMenuItem)
}

public class RevolverMenuItem: UIButton {
    
    public var backColor = UIColor.black
    
    public weak var delegate: RevolverMenuItemDelegate?
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public init(_ border: Bool = false) {
        super.init(frame: CGRect(x: 10, y: 10, width: 50, height: 50))
        
        if border {
            self.layer.borderColor = UIColor.lightGray.cgColor
            self.layer.borderWidth = 2
        }
        
        self.layer.cornerRadius = self.frame.size.width * 0.5
        self.backgroundColor = UIColor.black
        self.setTitle("", for: .normal)
        self.addTarget(self, action: #selector(buttonEvent(_:)), for: UIControl.Event.touchUpInside)
    }
    
    @objc func buttonEvent(_ sender: UIButton) {
        delegate?.tapped(on: self)
    }
    
    public func setItem(image: RMItemImage) {
        self.backgroundColor = image.backgroundColor
        self.setImage(image.itemImage, for: .normal)
        self.setImage(image.itemHighLightedImage, for: .highlighted)
        self.setBackgroundImage(image.backgroundImage, for: .normal)
        self.setBackgroundImage(image.backgroundHighLightedImage, for: .highlighted)
    }

}
