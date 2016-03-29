//
//  ServiceMonitor.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 2/01/16.
//  Copyright © 2016 Yanbing Peng. All rights reserved.
//

import Foundation

class ServiceMonitor : GCDAsyncUdpSocketDelegate, GCDAsyncSocketDelegate {
    //MARK: -Variables
    private var successHandler: ((String?)->(Void))
    private var errorHandler: ((String?)->(Void))
    
    private var udpSocket: GCDAsyncUdpSocket?
    private var tcpSocket: GCDAsyncSocket?
    
    private let delegateQueue: dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    
    private var dataToSend:String = ""
    
    private var requestSucceed:Bool = false
    
    private var udpTimer: NSTimer?
    
    //MARK: -init
    init(successHandler: ((String?)->(Void)), errorHandler: ((String?)->(Void))){
        self.successHandler = successHandler
        self.errorHandler = errorHandler
    }
    
    //MARK: -Private functions
    private func handleError(errorMessage:String){
        errorHandler(errorMessage)
        
        tcpSocket?.delegate = nil
        tcpSocket?.disconnect()
        tcpSocket = nil

        udpSocket?.close()
        udpSocket = nil
        udpTimer?.invalidate()
        udpTimer = nil
    }
    
    private func handleSuccess(response:String){
        requestSucceed = true
        successHandler(response)
        
        tcpSocket?.delegate = nil
        tcpSocket?.disconnect()
        tcpSocket = nil
        
        udpSocket?.close()
        udpSocket = nil
        udpTimer?.invalidate()
        udpTimer = nil
    }
    
    //MARK: -Public functions
    func sendHttpRequest(var url:String, method:String, dataToPost:String?){
        if !url.lowercaseString.hasPrefix("http://") && !url.lowercaseString.hasPrefix("https://"){
            url = "http://" + url
        }
        if let serverUrl = NSURL(string: url){
            let request = NSMutableURLRequest(URL: serverUrl)
            request.HTTPMethod = method
            if let data = dataToPost?.dataUsingEncoding(NSISOLatin1StringEncoding){
                request.HTTPBody = data
            }
            let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {[unowned self] (data, response, error) -> Void in
                guard error == nil && data != nil else{
                    print("Error: \(error)\r\n data: \(data)")
                    self.handleError("Http request error")
                    return
                }
                if let responseString = String.init(data: data!, encoding: NSISOLatin1StringEncoding){
                    self.handleSuccess(responseString)
                }
                else
                {
                    self.handleError("Invalid Http response")
                }
            })
            task.resume()
        }
        else
        {
            handleError("Invalid URL")
        }
    }
    
    func sendUdpRequest(ipAddress:String, port:UInt16, dataToSend:String){
        self.dataToSend = dataToSend
        requestSucceed = false
        if udpSocket != nil{
            udpSocket?.close()
            udpSocket = nil
        }
        
        udpSocket = GCDAsyncUdpSocket.init(delegate: self, delegateQueue: delegateQueue)
        do{
            try udpSocket?.bindToPort(0)
            try udpSocket?.beginReceiving()
            if let data = dataToSend.dataUsingEncoding(NSISOLatin1StringEncoding){
                udpSocket?.sendData(data, toHost: ipAddress, port: port, withTimeout: 5, tag: 0)
                udpTimer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: Selector("udpRequestTimeout:"), userInfo: nil, repeats: false)
            }
            else{
                handleError("Invalid data to send")
            }
        }
        catch let error as NSError{
            handleError("\(error)")
        }
    }
    
    func sendTcpRequest(ipAddress:String, port:UInt16, dataToSend:String){
        self.dataToSend = dataToSend
        requestSucceed = false
        if tcpSocket != nil{
            tcpSocket?.delegate = nil
            tcpSocket?.disconnect()
            tcpSocket = nil
        }
        
        tcpSocket = GCDAsyncSocket.init(delegate: self, delegateQueue: delegateQueue)
        do{
            try tcpSocket?.connectToHost(ipAddress, onPort: port, withTimeout: 5)
        }
        catch let error as NSError{
            handleError("\(error)")
        }
    }
    
    //MARK: -Delegate (UDP) methods
    func udpRequestTimeout(timer:NSTimer){
        handleError("UDP request timeout")
    }
    
    @objc func udpSocket(sock: GCDAsyncUdpSocket!, didReceiveData data: NSData!, fromAddress address: NSData!, withFilterContext filterContext: AnyObject!) {
        if let response = String.init(data: data, encoding: NSISOLatin1StringEncoding){
            handleSuccess(response)
        }
        else{
            handleError("Invalid response")
        }
    }
    
    @objc func udpSocket(sock: GCDAsyncUdpSocket!, didNotSendDataWithTag tag: Int, dueToError error: NSError!) {
        handleError("Unable to send UDP request")
    }
    
    //MARK: -Delegate (TCP) methods
    @objc func socket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        if let data = dataToSend.dataUsingEncoding(NSISOLatin1StringEncoding){
            sock.writeData(data, withTimeout: 5, tag: 0)
            sock.readDataWithTimeout(5, tag: 0)
        }
        else{
            handleError("Invalid data to send")
        }
    }
    
    @objc func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        if let response = String.init(data: data, encoding: NSISOLatin1StringEncoding){
            handleSuccess(response)
        }
        else{
            handleError("Invalid response")
        }
        
    }
    
    @objc func socket(sock: GCDAsyncSocket!, shouldTimeoutWriteWithTag tag: Int, elapsed: NSTimeInterval, bytesDone length: UInt) -> NSTimeInterval {
        handleError("Timeout sending data")
        return 0
    }
    
    @objc func socket(sock: GCDAsyncSocket!, shouldTimeoutReadWithTag tag: Int, elapsed: NSTimeInterval, bytesDone length: UInt) -> NSTimeInterval {
        handleError("Timeout receving response")
        return 0
    }
    
    @objc func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        if !requestSucceed {
            handleError("Disconnected")
        }
    }
}










