//
//  SwipeView.swift
//  RevolverMenu
//
//  Created by 川村周也 on 2019/04/09.
//  Copyright © 2019 川村周也. All rights reserved.
//

import UIKit

class SwipeView: UIView {

    var buttons: [CGRect] = []
    var parent: UIView?
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    public convenience init(frame: CGRect, btns: [UIButton]) {
        self.init(frame: frame)
        
        for btn in btns {
            buttons.append(btn.frame)
        }
        
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        //print(#function)
        
        guard !buttons.isEmpty else { return false }
        /*
         let result = !buttons.reduce(false, { (result, rect) -> Bool in
         return result || rect.contains(point)
         })
         */
        for btn in buttons {
            if btn.contains(convert(point, to: parent)) {
                return false
            }
        }
        return true
    }
}
