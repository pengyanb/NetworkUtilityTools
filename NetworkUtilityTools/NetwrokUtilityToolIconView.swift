//
//  NetwrokUtilityToolIconView.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 8/11/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import UIKit

@IBDesignable
class NetwrokUtilityToolIconView: UIView, UIGestureRecognizerDelegate {

    @IBInspectable
    var iconName:String? {
        didSet{
            self.setNeedsDisplay()
        }
    }
    
    var tapHandler : ((String)->Void)?
    
    private lazy var tapRecognizer : UITapGestureRecognizer = { [unowned self] in
        //print("tapRecogizer createed")
        let taprecognizer = UITapGestureRecognizer.init(target: self, action: Selector("iconTapped:"))
        taprecognizer.delegate = self
        return taprecognizer
    }()
    
    private lazy var imageView : UIImageView = { [unowned self] in
        let iv = UIImageView.init()
        iv.addGestureRecognizer(self.tapRecognizer)
        iv.userInteractionEnabled = true
        self.addSubview(iv)
        return iv
    }()
    
    func iconTapped(gesture:UITapGestureRecognizer){
        //print("iconTapped")
        if let handler = tapHandler {
            handler(iconName!)
        }
    }
    
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
        //print("drawRect \(rect)")
        if let iconname = iconName{
            if let image = UIImage.init(named: iconname, inBundle: NSBundle.init(forClass: self.dynamicType), compatibleWithTraitCollection: nil)
            {
                let imageSize = self.bounds.width < self.bounds.height ? self.bounds.width : self.bounds.height
                imageView.frame = CGRect(x: (self.bounds.width - imageSize) / 2, y: (self.bounds.height - imageSize) / 2, width: imageSize, height: imageSize)
                imageView.image = image
            }
        }
        
    }

}
