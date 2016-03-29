//
//  UdpListener.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 28/10/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import Foundation

class UdpListener : GCDAsyncUdpSocketDelegate, CustomStringConvertible {
    
    // MARK: - init
    init(portNum:UInt16){
        udpPortNum = portNum
    }
    
    deinit
    {
        stopReceive()
    }
    
    // MARK: - Variables & Properties
    var isRunning: Bool = false
    
    var description:String{
        get{
            objc_sync_enter(udpCapturedInfoDictionary)
            var descriptionString = "[UDP Listener @ port \(udpPortNum)]\n"
            descriptionString += "Captured IP source: \(udpCapturedInfoDictionary.count)\n"
            for (ipAddress, udpCaptureInfos) in udpCapturedInfoDictionary{
                descriptionString += "----[IP: \(ipAddress)]----\n"
                for udpCapturedInfo in udpCaptureInfos{
                    descriptionString += "\(udpCapturedInfo)"
                }
            }
            objc_sync_exit(udpCapturedInfoDictionary)
            return descriptionString
        }
    }
    private lazy var udpSocket : GCDAsyncUdpSocket? = { [unowned self] in
        //print("lazy udpSocket")
        return GCDAsyncUdpSocket.init(delegate: self, delegateQueue: self.delegateQueue, socketQueue: nil)
    }()
    
    private var udpPortNum : UInt16 = 0
    
    private var delegateQueue : dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)
    
    private lazy var handlerReceiveHandler : (data: NSData?, address:NSData?) -> () = {
        return { [unowned self] (data:NSData?, address:NSData?)->() in
            if data != nil && address != nil{
                //let dataString = String.init(data: data!, encoding: self.dataEncoding)
                //print("Data: \(dataString)")
                //print("Address: \(GCDAsyncUdpSocket.hostFromAddress(address))")
                var ipAddress:String = GCDAsyncUdpSocket.hostFromAddress(address)
                if ipAddress.containsString(":")
                {
                    ipAddress = ipAddress.componentsSeparatedByString(":").last!
                }
                var udpCapturedInfo = UdpCapturedInfo.init(ipAddress: ipAddress, data: data!, timestamp: NSDate.init())
                objc_sync_enter(self.udpCapturedInfoDictionary)
                if let udpCapturedInfos = self.udpCapturedInfoDictionary[ipAddress]
                {
                    self.udpCapturedInfoDictionary[ipAddress]?.insert(udpCapturedInfo, atIndex: 0)
                }
                else
                {
                    self.udpCapturedInfoDictionary[ipAddress] = [udpCapturedInfo]
                }
                objc_sync_exit(self.udpCapturedInfoDictionary)
                self.broadcastModelChangedNotification()
            }
        }
    }()
    
    private var dataEncoding:CONSTANTS_ENUM  = CONSTANTS.ENCODING_RAW_DATA
    
    var udpCapturedInfoDictionary = [String:[UdpCapturedInfo]]()
    
    // MARK: - public setters
    func setUdpPortNum(portNum:UInt16)
    {
        udpPortNum = portNum
        //print("setUdpPortNum")
        udpSocket = createUdpSocket()
        udpCapturedInfoDictionary = [String:[UdpCapturedInfo]]()
    }

    func getUdpPortNum()->UInt16{
        return udpPortNum
    }
    
    func setDataEncoding(encoding:CONSTANTS_ENUM)
    {
        dataEncoding = encoding 
        broadcastModelChangedNotification()
    }
    func getDataEncoding()->CONSTANTS_ENUM{
        return dataEncoding
    }
    
    //MARK: - Notifications
    func broadcastModelChangedNotification(){
        NSNotificationCenter.defaultCenter().postNotificationName(CONSTANTS.NOTI_UDP_MODEL_CHANGED.getAssociatedString(), object: self)
    }
    
    // MARK: - Private Func
    private func createUdpSocket()->GCDAsyncUdpSocket{
        if udpSocket != nil
        {
            self.udpSocket?.close()
        }
        return GCDAsyncUdpSocket.init(delegate: self, delegateQueue: delegateQueue, socketQueue: nil)
    }
    
    // MARK: - Public API
    func startReceive()->(Bool, String){
        do{
            try udpSocket?.bindToPort(udpPortNum)
            try udpSocket?.beginReceiving()
            print("udpSocket startReceive")
            isRunning = true
            return (true, "")
        }
        catch let error as NSError
        {
            //let errString = ("Error: \(error.domain)")
            isRunning = false
            return (false, "Error: \(error.domain)")
        }
    }
    func stopReceive(){
        udpSocket?.close()
        udpCapturedInfoDictionary = [String:[UdpCapturedInfo]]()
        isRunning = false
        broadcastModelChangedNotification()
    }
    // MARK: - Delegate Methods
    @objc func udpSocket(sock: GCDAsyncUdpSocket!, didReceiveData data: NSData!, fromAddress address: NSData!, withFilterContext filterContext: AnyObject!) {
        dispatch_async(dispatch_get_main_queue()){
            //print("udpSocket didReceiveData")
            self.handlerReceiveHandler(data: data, address: address)
        }
    }
    
}
