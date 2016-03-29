//
//  PingTool.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 22/12/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import Foundation

class PingTool : NSObject, SimplePingDelegate {

    //MARK: -variables
    private let dummyData = "Ping Tool by Peng Yanbing(Peter)".dataUsingEncoding(NSASCIIStringEncoding)!
    var pingResults = [PingResult]()
    private var pingNeedTotalAttempts:Int = 4
    private var pingPerformed:Int = 0
    
    private var hostName:String?
    private var simplePing:SimplePing?
    var pingTTL:Int32?
    
    private var requestAddress:String?
    private var requestTimestamp:NSTimeInterval?
    private var responseTimestamp:NSTimeInterval?
    
    private var pingTimer:NSTimer?
    
    //MARK: public API
    func startPingWithAddress(hostName: String, withNumberOfAttempt attemptCount:Int)
    {
        self.hostName = hostName
        pingNeedTotalAttempts = attemptCount
        pingResults = [PingResult]()
        requestAddress = nil
        for var i = 0; i < attemptCount; i++
        {
            pingResults.append(PingResult.init())
        }
        pingPerformed = 0
        startPingWithAddress(hostName)
    }
    
    //MARK: -private func
    private func startPingWithAddress(hostName: String)
    {
        simplePing?.stop()
        simplePing = nil
        
        if pingTimer == nil{
            pingTimer = NSTimer.scheduledTimerWithTimeInterval(3, target: NSBlockOperation(block: {[unowned self] () -> Void in
                self.pingTimer = nil
                
                self.pingResults[self.pingPerformed].sent = false
                self.pingPerformed++
                self.postModelChangedNotification("Request timed out.\n")
                if self.pingPerformed < self.pingNeedTotalAttempts{
                    if let hostName = self.hostName{
                        self.startPingWithAddress(hostName)
                    }
                }
                else{
                    self.generatePingStatistics()
                    self.simplePing?.stop()
                    self.simplePing = nil
                }
            }), selector: "main", userInfo: nil, repeats: false)
        }
        
        simplePing = SimplePing(hostName: hostName)
        simplePing?.delegate = self
        simplePing?.start()
    }
    
    private func postModelChangedNotification(message:String)
    {
        NSNotificationCenter.defaultCenter().postNotificationName(CONSTANTS.NOTI_PING_MODEL_CHANGED.getAssociatedString(), object: self, userInfo: ["PingInfo":message])
    }
    private func generatePingStatistics(){
        var packetReceived = 0
        var packetLost = 0
        var miniRTT = Int.max
        var maxRTT = Int.min
        var totalRTT = 0
        for pingResult in pingResults{
            if pingResult.received{
                packetReceived++
            }
            else
            {
                packetLost++
            }
            totalRTT += pingResult.responseTime
            if miniRTT > pingResult.responseTime{
                miniRTT = pingResult.responseTime
            }
            if maxRTT < pingResult.responseTime{
                maxRTT = pingResult.responseTime
            }
        }
        var message = ""
        if let requestAdd = requestAddress{
            message = "\nPing statistics for \(requestAdd):\n"
        }
        else
        {
            message = "\nPing statistics for \(hostName!):\n"
        }
        message += "\tPacket: Sent = \(pingPerformed), Received = \(packetReceived), Loss = \(packetLost) (\(Int.init(Double.init(packetLost) * 100.0 / Double.init( pingPerformed)))% loss)\n"
        message += "Approximate round trip times in milli-seconds:\n"
        message += "\tMinimum = \(miniRTT)ms, Maximum = \(maxRTT)ms, Average = \(Int.init(Double.init(totalRTT)/Double.init(pingPerformed)))ms\n\n"
        postModelChangedNotification(message)
    }

    //MARK: -delegate methods
    @objc func simplePing(pinger: SimplePing!, didStartWithAddress address: NSData!) {
        if let ttl = pingTTL{
            simplePing?.setTTL(ttl)
        }
        //print("address:\(address)")
        if let hostName = self.hostName{
            if pingPerformed < pingNeedTotalAttempts
            {
                simplePing?.sendPingWithData(dummyData)
                if pingPerformed == 0
                {
                    //print("Pinging \(hostName) with \(dummyData.length) bytes of data:\n")
                    var message = ""
                    if hostName.isValidIPv4(){
                        message = "Pinging \(hostName) with \(dummyData.length) bytes of data:\n"
                    }
                    else
                    {
                        let rawData = UnsafePointer<UInt8>.init(address.bytes)
                        requestAddress = "\(rawData[4]).\(rawData[5]).\(rawData[6]).\(rawData[7])"
                        message = "Pinging \(hostName) [\(requestAddress!)] with \(dummyData.length) bytes of data:\n"
                    }
                    postModelChangedNotification(message)
                }
                //pingResults[pingPerformed].sent = true
                //pingPerformed++
            }
        }
    }
    
    @objc func simplePing(pinger: SimplePing!, didFailWithError error: NSError!) {
        //print("Request failed.")
        pingTimer?.invalidate()
        pingTimer = nil
        postModelChangedNotification("Request failed.\n")
        pingResults[pingPerformed].sent = false
        pingPerformed++
        
        if pingPerformed < pingNeedTotalAttempts{
            if let hostName = self.hostName{
                startPingWithAddress(hostName)
            }
        }
        else{
            generatePingStatistics()
            simplePing?.stop()
            simplePing = nil
        }
    }
    @objc func simplePing(pinger: SimplePing!, didSendPacket packet: NSData!) {
        //print("simplePing didSendPacket:\(packet)")
        requestTimestamp = NSDate().timeIntervalSince1970
        pingResults[pingPerformed].sent = true
        //pingPerformed++
    }
    @objc func simplePing(pinger: SimplePing!, didFailToSendPacket packet: NSData!, error: NSError!) {
        //print("simplePing didFailToSendPack:\(packet)")
        //print("Request timed out.\n")
        pingTimer?.invalidate()
        pingTimer = nil
        pingResults[pingPerformed].sent = false
        pingPerformed++
        postModelChangedNotification("Request timed out.\n")
        if pingPerformed < pingNeedTotalAttempts{
            if let hostName = self.hostName{
                startPingWithAddress(hostName)
            }
        }
        else{
            generatePingStatistics()
            simplePing?.stop()
            simplePing = nil
        }
    }
    @objc func simplePing(pinger: SimplePing!, didReceivePingResponsePacket packet: NSData!) {
        //print("simplePing didReceivePingResponsePacket:\(packet)")
        pingTimer?.invalidate()
        pingTimer = nil
        var response = "Reply from "
        responseTimestamp = NSDate().timeIntervalSince1970
        let rawData = UnsafePointer<UInt8>.init(packet.bytes)
        let responseAddress = "\(rawData[12]).\(rawData[13]).\(rawData[14]).\(rawData[15])"
        response = response + "\(responseAddress): "
        response = response + "bytes=\(packet.subdataWithRange(NSRange.init(location: 27, length: packet.length - 28)).length) "
        
        let responseTTL = Int32.init(rawData[8])
        
        if let requestTime = requestTimestamp{
            if let responseTime = responseTimestamp{
                let time = (responseTime - requestTime) * 1000
                response = response + "time=\(Int.init(time))ms "
                pingResults[pingPerformed].responseTime = Int.init(time)
            }
        }
        response = response + "TTL=\(responseTTL)\n"
        //print(response)
        postModelChangedNotification(response)
        simplePing?.stop()

        pingResults[pingPerformed].received = true
        pingResults[pingPerformed].responseTTL = Int.init(responseTTL)
        pingPerformed++
        
        if pingPerformed < pingNeedTotalAttempts{
            if let hostName = self.hostName{
                startPingWithAddress(hostName)
            }
        }
        else{
            generatePingStatistics()
            simplePing?.stop()
            simplePing = nil
        }
    }
    @objc func simplePing(pinger: SimplePing!, didReceiveUnexpectedPacket packet: NSData!) {
        //print("simplePing didReceiveUnexpectedPacket:\(packet)")
        pingTimer?.invalidate()
        pingTimer = nil
        postModelChangedNotification("Received invalid packet\n")
        pingPerformed++
        if pingPerformed < pingNeedTotalAttempts{
            if let hostName = self.hostName{
                startPingWithAddress(hostName)
            }
        }
        else{
            generatePingStatistics()
            simplePing?.stop()
            simplePing = nil
        }
    }
    
}
