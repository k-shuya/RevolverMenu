//
//  RevolverMenuItem.swift
//  RevolverMenu
//
//  Created by 川村周也 on 2019/04/08.
//  Copyright © 2019 川村周也. All rights reserved.
//

import UIKit

class RevolverMenuItem: UIButton {
    
    public var backColor = UIColor.black
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    init() {
        super.init(frame: CGRect(x: 10, y: 10, width: 10, height: 10))
        self.layer.cornerRadius = self.frame.size.width * 0.1
        self.backgroundColor = self.backColor
        
    }

}
