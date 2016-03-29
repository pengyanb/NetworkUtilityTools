//
//  TcpClientScrollView.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 28/11/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import UIKit

class TcpClientScrollView: UIScrollView {
    private var bezierPaths = [String:UIBezierPath]()
    
    func setPath(path: UIBezierPath?, named name:String)
    {
        bezierPaths[name] = path
        setNeedsDisplay()
    }
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        for(_, path) in bezierPaths{
            path.stroke()
        }
    }
}
