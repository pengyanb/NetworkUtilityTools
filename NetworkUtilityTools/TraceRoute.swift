//
//  TraceRoute.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 24/12/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import Foundation

class TraceRoute : NSObject, SimplePingDelegate{
    
    //MARK: -variables
    private let dummyData = "TraceRoute - Peng Yanbing(Peter)".dataUsingEncoding(NSASCIIStringEncoding)
    
    var pingResults = [PingResult]()
    private var pingNeedTotalAttempts:Int = 3
    private var pingPerformed:Int = 0
    
    private var hostName:String?
    private var hostAddress:String?
    private var simplePing:SimplePing?
    private var pingTTL:Int32 = 1
    
    private let MAX_TTL:Int32 = 30
    
    private var requestAddress:String?
    private var requestTimestamp:NSTimeInterval?
    private var responseTimestamp:NSTimeInterval?
    
    private var pingTimer:NSTimer?
    
    //MARK: -public API
    func startTraceRouteWithAddress(hostName:String)
    {
        self.hostName = hostName
        pingNeedTotalAttempts = 3
        pingResults = [PingResult]()
        requestAddress = nil
        for var i = 0; i < pingNeedTotalAttempts; i++
        {
            pingResults.append(PingResult.init())
        }
        pingPerformed = 0
        startPingWithAddress(hostName)
    }
    
    //MARK: -private func
    private func startPingWithAddress(hostName:String)
    {
        simplePing?.stop()
        simplePing = nil
        
        if pingTimer == nil{
            pingTimer = NSTimer.scheduledTimerWithTimeInterval(3, target: NSBlockOperation(block: {[unowned self] () -> Void in
                self.pingTimer = nil
                
                self.pingResults[self.pingPerformed].sent = false
                self.pingResults[self.pingPerformed].received = false
                self.pingResults[self.pingPerformed].responseTime = -1
                self.pingPerformed++
                self.generateTraceRouteStatistics()
            }), selector: "main", userInfo: nil, repeats: false)
        }
        
        simplePing = SimplePing(hostName: hostName)
        simplePing?.delegate = self
        simplePing?.start()
    }
    
    private func postModelChangeNotification(message:String)
    {
        //print(message)
        NSNotificationCenter.defaultCenter().postNotificationName(CONSTANTS.NOTI_TRACE_ROUTE_MODEL_CHANGED.getAssociatedString(), object: self, userInfo: ["TraceRouteInfo":message])
    }
    
    private func generateTraceRouteStatistics(){
        if pingPerformed < pingNeedTotalAttempts{
            if let hostName = self.hostName{
                simplePing?.stop()
                simplePing = nil
                startPingWithAddress(hostName)
            }
        }
        else
        {
            var message = "\(pingTTL)\t"
            var responseAddress:String? = nil
            var pingSucceed = false
            for pingResult in pingResults{
                if let responseAdd = pingResult.responseAddress{
                    responseAddress = responseAdd
                }
                if pingResult.pingSuccessed {
                    pingSucceed = true
                }
                if !pingResult.sent || !pingResult.received || pingResult.responseTime < 0{
                    //message += String(format: "%8s", arguments: [("*" as NSString).UTF8String] )
                    message += "  *\t"
                }
                else
                {
                    //message += String(format: "%8s", arguments: [("\(pingResult.responseTime) ms" as NSString).UTF8String])
                    message += "\(pingResult.responseTime) ms\t"
                }
            }
            if let responseAdd = responseAddress{
                //message += "\t[\(responseAdd)]\n"
                ReverseDns.startResolveDomainName(responseAdd, withCompleteHandler: {(domainName) -> Void in
                    dispatch_async(dispatch_get_main_queue(), {[unowned self] () -> Void in
                        message += "\t\(domainName) [\(responseAdd)]\n"
                        self.postModelChangeNotification(message)
                        self.checkIfContinue(pingSucceed)
                    })
                })
            }
            else{
                message += "\n"
                postModelChangeNotification(message)
                checkIfContinue(pingSucceed)
            }
        }
    }
    
    private func checkIfContinue(pingSucceed:Bool){
        simplePing?.stop()
        simplePing = nil
        if pingTTL < MAX_TTL && !pingSucceed{
            pingTTL++
            pingResults = [PingResult]()
            requestAddress = nil
            for var i = 0; i < pingNeedTotalAttempts; i++
            {
                pingResults.append(PingResult.init())
            }
            pingPerformed = 0
            if let hostName = self.hostName{
                startPingWithAddress(hostName)
            }
        }
        else
        {
            postModelChangeNotification("\nTrace complete\n\n")
            pingTTL = 1
        }
    }
    //MARK: -delegate methods
    @objc func simplePing(pinger: SimplePing!, didStartWithAddress address: NSData!) {
        simplePing?.setTTL(pingTTL)
        if let hostName = self.hostName{
            if pingPerformed < pingNeedTotalAttempts{
                simplePing?.sendPingWithData(dummyData)
                if pingPerformed == 0 && pingTTL == 1 {
                    var message = ""
                    if hostName.isValidIPv4(){
                        message = "Tracing route to \(hostName)\n"
                    }
                    else{
                        let rawData = UnsafePointer<UInt8>.init(address.bytes)
                        requestAddress = "\(rawData[4]).\(rawData[5]).\(rawData[6]).\(rawData[7])"
                        message = "Tracing route to \(hostName)[\(requestAddress!)]\n"
                    }
                    message += "over a maximum of \(MAX_TTL) hops:\n\n"
                    postModelChangeNotification(message)
                }
            }
        }
    }
    
    @objc func simplePing(pinger: SimplePing!, didFailWithError error: NSError!) {
        print("[simplePing didFailWithError]: \(error)")
        pingTimer?.invalidate()
        pingTimer = nil
        
        pingResults[pingPerformed].sent = false
        pingResults[pingPerformed].received = false
        pingResults[pingPerformed].responseTime = -1
        pingPerformed++
        generateTraceRouteStatistics()
    }
    @objc func simplePing(pinger: SimplePing!, didSendPacket packet: NSData!) {
        requestTimestamp = NSDate().timeIntervalSince1970
        pingResults[pingPerformed].sent = true
    }
    @objc func simplePing(pinger: SimplePing!, didFailToSendPacket packet: NSData!, error: NSError!) {
        print("[simplePing didFailToSendPacket]: \(packet), Error: \(error)")
        pingTimer?.invalidate()
        pingTimer = nil
        
        pingResults[pingPerformed].sent = false
        pingResults[pingPerformed].received = false
        pingResults[pingPerformed].responseTime = -1
        pingPerformed++
        generateTraceRouteStatistics()
    }
    @objc func simplePing(pinger: SimplePing!, didReceivePingResponsePacket packet: NSData!) {
        //print("Did Receive Response Packet: \(packet)")
        pingTimer?.invalidate()
        pingTimer = nil
        
        responseTimestamp = NSDate().timeIntervalSince1970
        let rawData = UnsafePointer<UInt8>.init(packet.bytes)
        pingResults[pingPerformed].responseAddress =  "\(rawData[12]).\(rawData[13]).\(rawData[14]).\(rawData[15])"
        if let requestTime = requestTimestamp{
            if let responseTime = responseTimestamp{
                let time = (responseTime - requestTime) * 1000
                pingResults[pingPerformed].responseTime = Int.init(time)
            }
        }
        pingResults[pingPerformed].received = true
        pingResults[pingPerformed].pingSuccessed = true
        pingPerformed++
        generateTraceRouteStatistics()
    }
    @objc func simplePing(pinger: SimplePing!, didReceiveUnexpectedPacket packet: NSData!) {
        //print("[simplePing didReceiveUnexpectedPacket]: \(packet)")
        pingTimer?.invalidate()
        pingTimer = nil
        
        responseTimestamp = NSDate().timeIntervalSince1970
        let rawData = UnsafePointer<UInt8>.init(packet.bytes)
        if packet.length > 22
        {
            if rawData[20] == 11 && rawData[21] == 00{
                pingResults[pingPerformed].responseAddress =  "\(rawData[12]).\(rawData[13]).\(rawData[14]).\(rawData[15])"
                if let requestTime = requestTimestamp{
                    if let responseTime = responseTimestamp{
                        let time = (responseTime - requestTime) * 1000
                        pingResults[pingPerformed].responseTime = Int.init(time)
                    }
                }
                pingResults[pingPerformed].received = true
                pingPerformed++
                generateTraceRouteStatistics()
                return
            }
        }
        pingResults[pingPerformed].received = false
        pingResults[pingPerformed].responseTime = -1
        pingPerformed++
        generateTraceRouteStatistics()
    }
}










