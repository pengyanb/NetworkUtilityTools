//
//  PingResult.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 23/12/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import Foundation

class PingResult{
    var responseTime:Int=0
    var responseTTL:Int=0
    var responseAddress:String?
    var sent = false
    var received = false
    
    var pingSuccessed = false
    
    init(){
        
    }
}