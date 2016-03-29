//
//  TcpClientOptionsView.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 4/12/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import UIKit

class TcpClientOptionsView: UIView {

    @IBOutlet weak var serverIpAddressTextField: UITextField!
    
    @IBOutlet weak var serverPortNumberTextField: UITextField!
    
    @IBOutlet weak var encodePicker: UIPickerView!
    
    @IBOutlet weak var startButton: UIButton!

    
    override func sizeThatFits(size: CGSize) -> CGSize {
        let serverIpAddressTextFieldSize = serverIpAddressTextField.sizeThatFits(size)
        let serverPortNumberTextFieldSize = serverPortNumberTextField.sizeThatFits(size)
        let encodePickerSize = encodePicker.sizeThatFits(size)
        let startButtonSize = startButton.sizeThatFits(size)
        
        return CGSize(width: size.width, height: serverIpAddressTextFieldSize.height + serverPortNumberTextFieldSize.height + encodePickerSize.height + startButtonSize.height)
    }
    
    /*
    // Only override drawRect: if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func drawRect(rect: CGRect) {
        // Drawing code
    }
    */

}
