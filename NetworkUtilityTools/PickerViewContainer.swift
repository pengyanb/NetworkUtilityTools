//
//  PickerViewContainer.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 29/10/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import UIKit
import QuartzCore

@IBDesignable
class PickerViewContainer: UIView {

    private struct Constant{
        static let CornerRadius = CGFloat.init(5.0)
    }
    
    override func drawRect(rect: CGRect) {
        // Drawing code
        print("[PickerViewContainer drawRect]")
        print("\(self.bounds)")
        CGContextSaveGState(UIGraphicsGetCurrentContext())
        let path = UIBezierPath.init(roundedRect: CGRect(origin: self.bounds.origin, size: CGSize(width: self.bounds.width, height: self.bounds.height)), cornerRadius: Constant.CornerRadius)
        //UIColor.blackColor().setStroke()
        UIColor.init(red: 204.0/255.0, green: 204.0/255.0, blue: 204.0/255.0, alpha: 1.0).setStroke()
        //path.lineWidth = 1.0
        path.stroke()
        path.addClip()
        let mask = CAShapeLayer()
        mask.path = path.CGPath
        layer.mask = mask
        CGContextRestoreGState(UIGraphicsGetCurrentContext())
    }
}
