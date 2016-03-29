//
//  ClassExtensions.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 5/11/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import Foundation
import UIKit
extension UINavigationController{
    public override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        if let interfaceOrientationMask = visibleViewController?.supportedInterfaceOrientations(){
            return interfaceOrientationMask
        }
        else
        {
            return UIInterfaceOrientationMask.All
        }
    }
    public override func shouldAutorotate() -> Bool {
        return true
        /*
        if let shouldRotate = visibleViewController?.shouldAutorotate(){
            return shouldRotate
        }
        else{
            return true
        }*/
    }
}

extension String{
    func isValidIPv4()->Bool{
        let validIpAddressRegex = "^(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])$"
        if let _ = self.rangeOfString(validIpAddressRegex, options: .RegularExpressionSearch, range: self.startIndex..<self.endIndex, locale: nil)
        {
            return true
        }
        else
        {
            return false
        }
    }
}

extension NSData{
    func hexadecimalString()->String{
        let dataBuffer = UnsafePointer<UInt8>(self.bytes)
        if dataBuffer == nil{
            return ""
        }
        let dataLength = self.length
        var hexString = ""
        for var i=0; i<dataLength; i++
        {
            hexString += String(format: "%02X ",  dataBuffer.advancedBy(i).memory)
        }
        return hexString
    }
}