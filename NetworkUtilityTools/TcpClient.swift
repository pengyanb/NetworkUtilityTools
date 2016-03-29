//
//  TcpClient.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 2/12/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import Foundation

class TcpClient : GCDAsyncSocketDelegate{
    //MARK: -init
    init(portNum:UInt16, ipAddress:String){
        destPortNum = portNum
        destIpAddress = ipAddress
    }
    deinit{
        destroyTcpClient()
    }
    
    //MARK: - Variables & Properties
    var messageInfos = [TcpClientMessageInfo]()
    
    var isRunning:Bool{
        get{
            if let socket = tcpSocket{
                if socket.isConnected{
                    return true
                }
                else{
                    return false
                }
            }
            else{
                return false
            }
        }
    }
    private var tcpSocket: GCDAsyncSocket?{
        didSet{
            tcpSocket?.IPv4PreferredOverIPv6 = true
            tcpSocket?.autoDisconnectOnClosedReadStream = true
        }
    }
    
    private var destPortNum:UInt16 = 0
    private var destIpAddress:String?
    lazy var formatter: NSDateFormatter = {
        let fmt = NSDateFormatter()
        fmt.dateFormat = "yyyy-MM-dd hh:mm:ss"
        return fmt
    }()
    
    private var dataEncoding:CONSTANTS_ENUM = CONSTANTS.ENCODING_ASCII
    
    private let delegateQueue:dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)
    
    
    //MARK: -public setters/getters
    func setTcpClientDestIpAddress(ipAddress:String)
    {
        destIpAddress = ipAddress
    }
    func getTcpClientDestIpAddress()->String?{
        return destIpAddress
    }
    func setTcpClientDestPortNumber(portNum:UInt16){
        destPortNum = portNum
    }
    func getTcpClientDestPortNumber()->UInt16?{
        return destPortNum
    }
    func setDataEncoding(encoding:CONSTANTS_ENUM){
        dataEncoding = encoding
        notifyTcpClientModelChanged("Refresh")
    }
    func getDataEncoding()->CONSTANTS_ENUM{
        return dataEncoding
    }
    
    //MARK: -Notifications
    private func notifyTcpClientModelChanged(changeType:String)
    {
        NSNotificationCenter.defaultCenter().postNotificationName(CONSTANTS.NOTI_TCP_CLIENT_INFO.getAssociatedString(), object: self, userInfo: ["ChangeType":changeType])
    }
    private func notifyModelChangeSynchronizely(messageInfo:TcpClientMessageInfo, changeType:String){
        dispatch_async(dispatch_get_main_queue()) {[weak self] () -> Void in
            self?.messageInfos.append(messageInfo)
            self?.notifyTcpClientModelChanged(changeType)
        }
    }
    
    //MARK: -private Func
    private func createStatusMessageInfo(message:String)->TcpClientMessageInfo{
        let messageInfo = TcpClientMessageInfo()
        messageInfo.type = TcpClientMessageInfo.MESSAGE_TYPE.STATUS
        messageInfo.message = message
        messageInfo.timestamp = NSDate.init()
        return messageInfo
    }
    private func createReadWriteMessageInfo(data:NSData?, message:String?, type:TcpClientMessageInfo.MESSAGE_TYPE)->TcpClientMessageInfo{
        let messageInfo = TcpClientMessageInfo()
        messageInfo.type = type
        messageInfo.data = data
        messageInfo.message = message
        messageInfo.timestamp = NSDate.init()
        return messageInfo
    }
    private func createTcpSocket(){
        if tcpSocket != nil{
            tcpSocket?.delegate = nil
            tcpSocket?.disconnect()
            tcpSocket = nil
        }
        tcpSocket = GCDAsyncSocket.init(delegate: self, delegateQueue: delegateQueue)
        notifyModelChangeSynchronizely(createStatusMessageInfo("Tcp Client initialized"), changeType:"update")
    }
    func destroyTcpClient(){
        if tcpSocket != nil{
            tcpSocket?.delegate = nil
            tcpSocket?.disconnect()
            tcpSocket = nil
        }
        notifyModelChangeSynchronizely(createStatusMessageInfo("Tcp Client disconnected"), changeType:"update")
    }
    
    //MARK: - Public API
    func connectToServer()->Bool{
        print("socket connectToServer")
        if tcpSocket == nil{
            createTcpSocket()
        }
        if let socket = tcpSocket{
            if socket.isConnected{
                if (socket.connectedHost != destIpAddress) || (socket.connectedPort != destPortNum){
                    //destroyTcpClient()
                    socket.disconnect()
                }
                else
                {
                    return true
                }
            }
            do{
                //try socket.connectToHost(destIpAddress, onPort: destPortNum)
                try socket.connectToHost(destIpAddress, onPort: destPortNum, withTimeout: 5)
                //print("socket.connectToHost: \(destIpAddress):\(destPortNum)")
                return true
            }
            catch let error as NSError{
                print("\(error)")
                notifyModelChangeSynchronizely(createStatusMessageInfo("Unable to connect to Server \(destIpAddress):\(destPortNum)"), changeType:"update")
                return false
            }
        }
        else{
            
            return false
        }
    }
    
    func writeData(message:String, withTimeout timeout:NSTimeInterval){
        if let socket = tcpSocket{
            if socket.isConnected{
                if let data = message.dataUsingEncoding(dataEncoding.getAssociatedUInt())
                {
                    socket.writeData(data, withTimeout: timeout, tag: messageInfos.count-1)
                    notifyModelChangeSynchronizely(createReadWriteMessageInfo(nil, message: message, type: TcpClientMessageInfo.MESSAGE_TYPE.WRITE), changeType:"update")
                }
            }
            else
            {
                notifyModelChangeSynchronizely(createStatusMessageInfo("Tcp Client is disconnected, unable to send data"), changeType:"update")
            }
        }
        else
        {
            notifyModelChangeSynchronizely(createStatusMessageInfo("Tcp Client is uninitialized, unable to send any data"), changeType:"update")
        }
    }
    
    func readData(withTimeout timeout:NSTimeInterval, tag:Int=0)
    {
        if let socket = tcpSocket{
            if socket.isConnected{
                socket.readDataWithTimeout(timeout, tag: tag)
            }
            else{
                notifyModelChangeSynchronizely(createStatusMessageInfo("Tcp Client is disconnected, unable to send data"), changeType:"update")
            }
        }
        else{
            notifyModelChangeSynchronizely(createStatusMessageInfo("Tcp Client is uninitialized, unable to send data"), changeType:"update")
        }
    }

    //MARK: - Delegate methods
    @objc func socket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        notifyModelChangeSynchronizely(createStatusMessageInfo("Tcp Client connected to \(host):\(port)"), changeType:"update")
        notifyTcpClientModelChanged("connected")
        readData(withTimeout: -1)
    }
    
    @objc func socket(sock: GCDAsyncSocket!, didWriteDataWithTag tag: Int) {
        //messageInfos[tag].isReady = true
        //notifyTcpClientModelChanged("update")
    }
    @objc func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        //print("[TcpClient socketDidReadData]")
        notifyModelChangeSynchronizely(createReadWriteMessageInfo(data, message: nil, type: TcpClientMessageInfo.MESSAGE_TYPE.READ), changeType:"update")
        readData(withTimeout: -1)
    }
    @objc func socket(sock: GCDAsyncSocket!, shouldTimeoutWriteWithTag tag: Int, elapsed: NSTimeInterval, bytesDone length: UInt) -> NSTimeInterval {
        let msgInfo = messageInfos[tag]
        //messageInfos.removeAtIndex(tag)
        if let message = msgInfo.message{
            notifyModelChangeSynchronizely(createStatusMessageInfo("Timeout while transmiting: \(message)"), changeType:"update")
        }
        return 0
    }
    @objc func socket(sock: GCDAsyncSocket!, shouldTimeoutReadWithTag tag: Int, elapsed: NSTimeInterval, bytesDone length: UInt) -> NSTimeInterval {
        notifyModelChangeSynchronizely(createStatusMessageInfo("Timeout while receiving"), changeType:"update")
        return 0
    }
    @objc func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        notifyModelChangeSynchronizely(createStatusMessageInfo("Tcp Client disconnected"), changeType:"update")
        notifyTcpClientModelChanged("disconnected")
    }
}










