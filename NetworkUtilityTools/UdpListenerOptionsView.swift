//
//  UdpListenerOptionsView.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 21/11/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import UIKit

class UdpListenerOptionsView: UIView {
    
    @IBOutlet weak var portNumTextField: UITextField!
    
    @IBOutlet weak var decodePickerView: UIPickerView!
    
    @IBOutlet weak var startButton: UIButton!
    
    override func sizeThatFits(size: CGSize) -> CGSize {
        let portNumTextFieldSize = portNumTextField.sizeThatFits(size)
        let decodePickerViewSize = decodePickerView.sizeThatFits(size)
        let startButtonSize = startButton.sizeThatFits(size)
        
        return CGSize(width: size.width, height: portNumTextFieldSize.height + decodePickerViewSize.height + startButtonSize.height)
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
