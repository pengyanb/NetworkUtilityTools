//
//  PortScanner.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 11/02/16.
//  Copyright © 2016 Yanbing Peng. All rights reserved.
//

import Foundation

class PortScanner : GCDAsyncSocketDelegate{
    //MARK: -init
    init(startIpRange:String, endIpRange:String, portNum:UInt16, scanType:Int = 0)
    {
        
        self.startIpRange = startIpRange
        self.endIpRange = endIpRange
        self.portNum = portNum
        self.scanType = scanType
        
        isDone = false
        
        let startIpRangeSplit = startIpRange.componentsSeparatedByString(".")
        let endIpRangeSplit = endIpRange.componentsSeparatedByString(".")
        if startIpRangeSplit.count == 4 && endIpRangeSplit.count == 4{
            let startIpPortion1 = Int.init(startIpRangeSplit[0])!
            let startIpPortion2 = Int.init(startIpRangeSplit[1])!
            let startIpPortion3 = Int.init(startIpRangeSplit[2])!
            let startIpPortion4 = Int.init(startIpRangeSplit[3])!
            
            let endIpPortion1 = Int.init(endIpRangeSplit[0])!
            let endIpPortion2 = Int.init(endIpRangeSplit[1])!
            let endIpPortion3 = Int.init(endIpRangeSplit[2])!
            let endIpPortion4 = Int.init(endIpRangeSplit[3])!
            
            let startIpOverallValue = startIpPortion1 * 255 * 255 * 255 + startIpPortion2 * 255 * 255 + startIpPortion3 * 255 + startIpPortion4
            let endIpOverallValue =  endIpPortion1 * 255 * 255 * 255 + endIpPortion2 * 255 * 255 + endIpPortion3 * 255 + endIpPortion4
            
            if  startIpOverallValue < endIpOverallValue{
                overallIpToTestCount = endIpOverallValue - startIpOverallValue
                initialIpCounter = startIpOverallValue
            }
            else
            {
                overallIpToTestCount = startIpOverallValue - endIpOverallValue
                initialIpCounter = endIpOverallValue
            }
            print("[OverallIpToTestCount: \(overallIpToTestCount)]")
        }
        else
        {
            notifyPortScannerModelChanged("Error", info: "Invalid IP Address")
        }
    }
    
    //MARK: -variables
    private let MAX_SCAN_COUNT = 50
    private let MAX_SCAN_TIMEOUT = 5.0
    
    var detectedIps = [String]()
    
    private var startIpRange:String
    private var endIpRange:String
    private var portNum:UInt16
    private var scanType:Int = 0
    private var tcpSockets = [GCDAsyncSocket]()
    private var httpTasks = [NSURLSessionDataTask]()
    private var ftpTasks = [NSURLSessionDataTask]()
    
    private let delegateQueue:dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)
    
    
    private var initialIpCounter = 1
    
    private var overallIpToTestCount = 0
    private var currentIpIndex = 0
    
    private let modulus1 = 255 * 255 * 255
    private let modulus2 = 255 * 255
    private let modulus3 = 255
    
    private var isDone = false
    //MARK: -Notifications
    private func notifyPortScannerModelChanged(changeType:String, info:String?){
        //changeType : 1. Error     2. Done     3. Detected     4.Testing
        dispatch_async(dispatch_get_main_queue()) { [unowned self] () -> Void in
            var userInfo = ["ChangeType":changeType]
            if let _info = info{
                userInfo["Info"] = _info
                if changeType == "Detected"{
                    self.detectedIps.append(_info)
                }
            }
            //print("UserInfo: \(userInfo)")
            NSNotificationCenter.defaultCenter().postNotificationName(CONSTANTS.NOTI_PORT_SCANNER_MODEL_CHANGED.getAssociatedString(), object: self, userInfo: userInfo)
        }
    }
    
    //MARK: -public API
    func startPortScan(){
        if isDone{
            return
        }
        if currentIpIndex >= overallIpToTestCount {
            if !isDone && dataArrayAllEmpty(){
                //print("[StartPortScan \(self.currentIpIndex)]")
                isDone = true
                notifyPortScannerModelChanged("Done", info: nil)
            }
            return
        }
        if let ipToTest = getNextIpToTest(){
            switch scanType{
            case 0: rawSocketScanTest(ipToTest)
            case 1: httpScanTest(ipToTest)
            case 2: ftpScanTest(ipToTest)
            case 3: rtspScanTest(ipToTest)
            default: break
            }
        }
    }
    
    func stopPortScan(){
        dispatch_async(dispatch_get_main_queue()) {[unowned self] () -> Void in
            self.currentIpIndex = self.overallIpToTestCount + 1
            self.notifyPortScannerModelChanged("Done", info: nil)
        }
    }
    
    //MARK: -Delegate [Raw Socket]
    @objc func socket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        if scanType == 0  //raw socket scan
        {
            notifyPortScannerModelChanged("Detected", info: host)
            sock.disconnect()
        }
        else if scanType == 3 //RTSP scan
        {
            let dataString = "OPTIONS rtsp://\(host) RTSP/1.0\r\nCSeq: 1\r\n\r\n"
            //let dataString = "DESCRIBE rtsp://\(host) RTSP/1.0\r\nCSeq: 2\r\n\r\n"
            //print("[" + dataString + "]")
            if let dataToSend = dataString.dataUsingEncoding(CONSTANTS.ENCODING_ASCII.getAssociatedUInt()){
                sock.writeData(dataToSend , withTimeout: MAX_SCAN_TIMEOUT, tag: 0)
                sock.readDataWithTimeout(MAX_SCAN_TIMEOUT, tag: 0)
            }
            else{
                sock.disconnect()
            }
        }
    }
    
    @objc func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        if scanType == 3 //RTSP scan
        {
            print(String.init(data: data, encoding: CONSTANTS.ENCODING_ASCII.getAssociatedUInt()))
            notifyPortScannerModelChanged("Detected", info: sock.connectedHost)
            sock.disconnect()
        }
    }
    
    @objc func socket(sock: GCDAsyncSocket!, shouldTimeoutReadWithTag tag: Int, elapsed: NSTimeInterval, bytesDone length: UInt) -> NSTimeInterval {
        sock.disconnect()
        return 0
    }
    
    @objc func socket(sock: GCDAsyncSocket!, shouldTimeoutWriteWithTag tag: Int, elapsed: NSTimeInterval, bytesDone length: UInt) -> NSTimeInterval {
        sock.disconnect()
        return 0
    }
    
    @objc func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        dispatch_async(dispatch_get_main_queue()) {[unowned self] () -> Void in
            var indexToRemove = -1
            for var i = 0;  i < self.tcpSockets.count; i++ {
                let socket = self.tcpSockets[i]
                if socket == sock{
                    indexToRemove = i
                }
            }
            if indexToRemove >= 0{
                //print("Remove index: \(indexToRemove) socketCount: \(self.tcpSockets.count)")
                self.tcpSockets.removeAtIndex(indexToRemove)
            }
            self.startPortScan()
        }
    }
    
    //MARK: -private functions
    private func dataArrayAllEmpty()->Bool{
        return tcpSockets.isEmpty && httpTasks.isEmpty && ftpTasks.isEmpty
    }

    private func ftpScanTest(ipToTest:String){
        if self.ftpTasks.count < self.MAX_SCAN_COUNT{
            if let url = NSURL.init(string:"ftp://\(ipToTest):\(portNum)"){
                let request = NSURLRequest.init(URL: url, cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: MAX_SCAN_TIMEOUT)
                let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {[unowned self] (data, response, error) -> Void in
                    dispatch_async(dispatch_get_main_queue(), {[unowned self] () -> Void in
                        self.ftpTasks = self.ftpTasks.filter({ (_task) -> Bool in
                            if _task.state == NSURLSessionTaskState.Completed{
                                return false
                            }
                            return true
                        })
                        if error == nil && data != nil{
                            self.notifyPortScannerModelChanged("Detected", info: ipToTest)
                        }
                        self.startPortScan()
                    })
                })
                task.resume()
                self.notifyPortScannerModelChanged("Testing", info: ipToTest)
                self.ftpTasks.append(task)
            }
            self.currentIpIndex++
            self.startPortScan()
        }
    }
    private func httpScanTest(ipToTest:String){
        if self.httpTasks.count < self.MAX_SCAN_COUNT{
            if let url = NSURL.init(string: "http://\(ipToTest):\(portNum)"){
                let request = NSURLRequest.init(URL: url, cachePolicy: NSURLRequestCachePolicy.UseProtocolCachePolicy, timeoutInterval: MAX_SCAN_TIMEOUT)
                let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { [unowned self](data, response, error) -> Void in
                    dispatch_async(dispatch_get_main_queue(), {[unowned self] () -> Void in
                        self.httpTasks = self.httpTasks.filter({ (_task) -> Bool in
                            if _task.state == NSURLSessionTaskState.Completed{
                                return false
                            }
                            return true
                        })
                        if error == nil && data != nil{
                            self.notifyPortScannerModelChanged("Detected", info: ipToTest)
                            /*
                            if let responseString = String.init(data: data!, encoding: CONSTANTS.ENCODING_ISO_Latin1.getAssociatedUInt()){
                                if (responseString as NSString).rangeOfString("AAP Embedded WEB Server").location != NSNotFound{
                                    self.notifyPortScannerModelChanged("Detected", info: ipToTest)
                                }
                            }*/
                        }
                        self.startPortScan()
                    })
                })
                task.resume()
                self.notifyPortScannerModelChanged("Testing", info: ipToTest)
                self.httpTasks.append(task)
            }
            self.currentIpIndex++
            self.startPortScan()
        }
    }
    private func rtspScanTest(ipToTest:String){
        if self.tcpSockets.count < self.MAX_SCAN_COUNT{
            let socket = GCDAsyncSocket.init(delegate: self, delegateQueue: self.delegateQueue)
            self.notifyPortScannerModelChanged("Testing", info: ipToTest)
            if self.rawSocketConnectToServer(socket, ipToTest: ipToTest){
                self.tcpSockets.append(socket)
            }
            self.currentIpIndex++
            self.startPortScan()
        }
    }
    
    private func rawSocketScanTest(ipToTest:String){
        if self.tcpSockets.count < self.MAX_SCAN_COUNT{
            let socket = GCDAsyncSocket.init(delegate: self, delegateQueue: self.delegateQueue)
            self.notifyPortScannerModelChanged("Testing", info: ipToTest)
            if self.rawSocketConnectToServer(socket, ipToTest: ipToTest){
                self.tcpSockets.append(socket)
            }
            self.currentIpIndex++
            self.startPortScan()
        }
    }
    private func rawSocketConnectToServer(socket:GCDAsyncSocket, ipToTest:String)->Bool{
        do{
            try socket.connectToHost(ipToTest, onPort: portNum, withTimeout: MAX_SCAN_TIMEOUT)
            return true
        }
        catch{
            return false
        }
    }
    
    private func getNextIpToTest()->String?{
        if overallIpToTestCount > 0 && currentIpIndex <= overallIpToTestCount{
            let ipToTest = initialIpCounter + currentIpIndex
            let remainder1 = ipToTest % modulus1
            let ipToTestPortion1 = (ipToTest - remainder1) / modulus1
            let remainder2 = remainder1 % modulus2
            let ipToTestPortion2 = (remainder1 - remainder2) / modulus2
            let remainder3 = remainder2 % modulus3
            let ipToTestPortion3 = (remainder2 - remainder3) / modulus3
            let ipToTestPortion4 = remainder3
            
            return "\(ipToTestPortion1).\(ipToTestPortion2).\(ipToTestPortion3).\(ipToTestPortion4)"
            
        }
        else{
            return nil
        }
    }
}

















