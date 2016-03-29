//
//  TcpServerMessageInfo.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 14/12/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import Foundation

class TcpServerMessageInfo : CustomStringConvertible {
    var ipAddress:String?
    var data:NSData?
    var timestamp:NSDate?
    var message:String?
    var type:MESSAGE_TYPE?
    var clientTag:Int = -1
    
    enum MESSAGE_TYPE{
        case STATUS
        case WRITE
        case READ
    }
    
    var description:String{
        get{
            if let mType = self.type{
                switch mType{
                case .STATUS:
                    return "STATUS[\(getTimeStamp())]: \(self.message!)"
                case .READ:
                    return "READ[\(getTimeStamp())]: \(getDataStringWithEncodingType(CONSTANTS.ENCODING_ISO_Latin1))"
                case .WRITE:
                    return "WRITE[\(getTimeStamp())]: \(self.message)"
                }
            }
            else{
                return ""
            }
        }
    }
    
    lazy private var formatter:NSDateFormatter = {
        var df = NSDateFormatter.init()
        df.dateFormat = "yyyy-MM-dd hh:mm:ss"
        return df
    }()
    
    init(){
        
    }
    
    func getTimeStamp()->String{
        if timestamp != nil{
            return formatter.stringFromDate(timestamp!)
        }
        return ""
    }
    
    func getDataStringWithEncodingType(encoding:CONSTANTS_ENUM)->String{
        if data != nil{
            if let result = String.init(data:data!, encoding:encoding.getAssociatedUInt()){
                return result
            }
            else
            {
                return "Error: unable to decode data with \"\(encoding.getAssociatedString())\" format"
            }
        }
        else
        {
            return "Error: no data available to be decoded"
        }
    }
}