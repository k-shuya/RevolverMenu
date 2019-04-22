//
//  RMItemImage.swift
//  RevolverMenu
//
//  Created by 川村周也 on 2019/04/15.
//  Copyright © 2019 川村周也. All rights reserved.
//

import UIKit

public class RMItemImage {
    
    public var itemImage: UIImage?
    public var itemHighLightedImage: UIImage?
    public var backgroundImage: UIImage?
    public var backgroundHighLightedImage: UIImage?
    
    public var backgroundColor: UIColor?
    
    public init() {
        itemImage = nil
        itemHighLightedImage = nil
        backgroundImage = nil
        backgroundHighLightedImage = nil
        backgroundColor = UIColor.black
    }
    
    public func setImage(itemImage: UIImage, itemHighLightedImage: UIImage? = nil, backgroundImage: UIImage? = nil, backgroundHighLightedImage: UIImage? = nil, backgroundColor: UIColor? = nil) {
        self.itemImage = itemImage
        self.itemHighLightedImage = itemHighLightedImage
        self.backgroundImage = backgroundImage
        self.backgroundHighLightedImage = backgroundHighLightedImage
        self.backgroundColor = backgroundColor
    }

}
