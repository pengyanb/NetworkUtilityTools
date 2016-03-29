//
//  UdpCapturedInfo.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 11/11/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import Foundation

class UdpCapturedInfo : CustomStringConvertible{
    let ipAddress: String
    let data: NSData
    let timestamp: NSDate
    
    lazy private var formatter:NSDateFormatter = {
        var df = NSDateFormatter.init()
        df.dateFormat = "yyyy-MM-dd hh:mm:ss"
        return df
    }()
    
    var description:String{
        get{
            return "Timestamp: " + formatter.stringFromDate(timestamp) + "\nDate: "+data.hexadecimalString()+"\n\n"
        }
    }
    
    func getTimestamp()->String{
        return formatter.stringFromDate(timestamp)
    }
    func getDataStringWithEncodingType(encoding:CONSTANTS_ENUM)->String
    {
        if encoding.getAssociatedUInt() == 0{
            return getDataHexdecimalString()
        }
        else
        {
            if let result = String.init(data: data, encoding: encoding.getAssociatedUInt()){
                return result
            }
            else{
                return "Error: unable to decode data with \"\(encoding.getAssociatedString())\" format."
            }
        }
    }
    func getDataHexdecimalString()->String{
        return data.hexadecimalString()
    }
    
    init(ipAddress:String, data:NSData, timestamp:NSDate){
        self.ipAddress = ipAddress
        self.data = data
        self.timestamp = timestamp
    }
}