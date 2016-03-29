//
//  UdpBroadcaster.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 23/11/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import Foundation

class UdpBroadcaster : GCDAsyncUdpSocketDelegate
{
    // MARK: -init
    init(portNum:UInt16, ipAddress:String = "255.255.255.255")
    {
        udpPortNum = portNum
        self.ipAddress = ipAddress
    }
    deinit
    {
        destroyUdpSocket()
    }
    
    // MARK: - Variables & Properties
    private var udpSocket : GCDAsyncUdpSocket?{
        didSet{
            udpSocket?.setPreferIPv4()
            do{
                try udpSocket?.enableBroadcast(true)
            }
            catch{
                print("Error occured while enabling UDP Socket Broadcast")
            }
        }
    }
    
    private var udpPortNum : UInt16 = 0
    private var ipAddress :String?
    private lazy var formatter: NSDateFormatter = {
        let fmt = NSDateFormatter.init()
        fmt.dateFormat = "yyyy-MM-dd hh:mm:ss"
        return fmt
    }()
    
    private var dataEncoding:CONSTANTS_ENUM = CONSTANTS.ENCODING_ASCII
    
    private lazy var handlerBroadcastHandler : (message:String?)->() = {
        return { [unowned self] (message:String?)->() in
            if let msg = message{
                self.notifyUdpBroadcasterStatusChanged(msg)
            }
        }
    }()
    
    private let delegateQueue : dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)
    
    //MARK: - public setters
    func setUdpPortNum(portNum: UInt16, andIPAddress ip:String)
    {
        if (portNum != udpPortNum) || (ip != ipAddress)
        {
            udpPortNum = portNum
            ipAddress = ip
            createUdpSocket()
        }
    }
    func setDataEncoding(encode:CONSTANTS_ENUM)
    {
        dataEncoding = encode
    }
    
    //MARK: - Private Func
    private func createUdpSocket()->GCDAsyncUdpSocket?{
        if udpSocket != nil{
            self.udpSocket?.close()
        }
        udpSocket = GCDAsyncUdpSocket.init(delegate: self, delegateQueue: delegateQueue)
        notifyUdpBroadcasterStatusChanged("\(formatter.stringFromDate(NSDate.init())): UDP Broadcaster [\(ipAddress!):\(udpPortNum)] initialized")
        return udpSocket
    }

    private func destroyUdpSocket(){
        udpSocket?.close()
        notifyUdpBroadcasterStatusChanged("\(formatter.stringFromDate(NSDate.init())): UDP Broadcaster disposed")
    }
    
    private func notifyUdpBroadcasterStatusChanged(message:String)
    {
        NSNotificationCenter.defaultCenter().postNotificationName(CONSTANTS.NOTI_UDP_BROADCASTER_INFO.getAssociatedString(), object: self, userInfo: ["info":message])
    }
    //MARK: - Public API
    func sendBroadcast(message:String)
    {
        if udpSocket == nil{
            createUdpSocket()
        }
        if let socket = udpSocket{
            let data = message.dataUsingEncoding(dataEncoding.getAssociatedUInt())
            socket.sendData(data, toHost: ipAddress, port: udpPortNum, withTimeout: CONSTANTS.TIMEOUT_UDP_BROADCAST.getAssociatedDouble(), tag: 0)
        }
        else
        {
            notifyUdpBroadcasterStatusChanged("\(formatter.stringFromDate(NSDate.init())): Unable to create UDP Broadcaster [\(ipAddress!):\(udpPortNum)]")
        }
        
    }
    
    //MARK: - Delegate methods
    @objc func udpSocket(sock: GCDAsyncUdpSocket!, didSendDataWithTag tag: Int) {
        handlerBroadcastHandler(message: "\(formatter.stringFromDate(NSDate.init())): UDP Broadcast Sent")
    }
    @objc func udpSocket(sock: GCDAsyncUdpSocket!, didNotSendDataWithTag tag: Int, dueToError error: NSError!) {
        handlerBroadcastHandler(message: "\(formatter.stringFromDate(NSDate.init())): UDP Broadcast Error - \(error)")
    }
}