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
    
    public weak var delegate: RevolverMenuItemDelegate?
    
    public var borderColor: CGColor = UIColor.lightGray.cgColor {
        didSet {
            self.layer.borderColor = borderColor
        }
    }
    
    public var borderWidth: CGFloat = 2 {
        didSet {
            self.layer.borderWidth = borderWidth
        }
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public init(_ border: Bool = false) {
        super.init(frame: CGRect(x: 10, y: 10, width: 50, height: 50))
        
        if border {
            self.layer.borderColor = borderColor
            self.layer.borderWidth = borderWidth
        }
        
        self.layer.cornerRadius = self.frame.size.width * 0.5
        self.setTitle("", for: .normal)
        self.addTarget(self, action: #selector(buttonEvent(_:)), for: UIControl.Event.touchUpInside)
    }
    
    public convenience init(itemImage: UIImage? = nil,
                            itemHighLightedImage: UIImage? = nil,
                            backgroundImage: UIImage? = nil,
                            backgroundHighLightedImage: UIImage? = nil,
                            backgroundColor: UIColor?)
    {
        self.init(false)
        self.backgroundColor = backgroundColor
        self.setImage(itemImage, for: .normal)
        self.setImage(itemHighLightedImage, for: .highlighted)
        self.setBackgroundImage(backgroundImage, for: .normal)
        self.setBackgroundImage(backgroundHighLightedImage, for: .highlighted)  
    }
    
    @objc func buttonEvent(_ sender: UIButton) {
        delegate?.tapped(on: self)
    }
    
}
