//
//  TcpServer.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 13/12/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import Foundation

class TcpServer : GCDAsyncSocketDelegate{
    //MARK: -init
    init(portNum:UInt16)
    {
        serverPortNum = portNum
    }
    deinit{
        destroyTcpServer()
    }
    
    //MARK: -Variables & properties
    let sync_locker = ""
    
    private var serverListening = false
    var isListening:Bool{
        get{
            if tcpServerSocket != nil{
                return serverListening
            }
            else
            {
                return false
            }
        }
    }
    var messageInfos = [TcpServerMessageInfo]()
    private var tcpServerSocket:GCDAsyncSocket?{
        didSet{
            tcpServerSocket?.IPv4PreferredOverIPv6 = true
        }
    }
    private var tcpClientSockets = [GCDAsyncSocket?]()
    
    var serverPortNum:UInt16 = 0
    lazy var formatter:NSDateFormatter = {
        let fmt = NSDateFormatter()
        fmt.dateFormat = "yyyy-MM-dd hh:mm:ss"
        return fmt
    }()
    
    var dataEncoding:CONSTANTS_ENUM = CONSTANTS.ENCODING_ASCII
    
    var serverBehavior:CONSTANTS_ENUM = CONSTANTS.SERVER_BEHAVIOR_ECHO
    
    //private let delegateQueue:dispatch_queue_t = dispatch_queue_create("com.NetworkUtilityTools.TcpServer.delegateQueue", nil)
    
    private let delegateQueue:dispatch_queue_t = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    
    //MARK: -Notifications
    private func notifyTcpServerModelChanged(changeType:String)
    {
        NSNotificationCenter.defaultCenter().postNotificationName(CONSTANTS.NOTI_TCP_SERVER_INFO.getAssociatedString(), object: self, userInfo: ["ChangeType":changeType])
    }
    //MARK: -notifyModelChangeSynchronizely
    private func notifyModelChangeSynchronizely(messageInfo:TcpServerMessageInfo, changeType:String)
    {
        dispatch_async(dispatch_get_main_queue()) {[weak self] () -> Void in
            if let weakSelf = self{
                //print("[Model] - \(messageInfo)")
                objc_sync_enter(weakSelf.sync_locker)
                weakSelf.messageInfos.append(messageInfo)
                objc_sync_exit(weakSelf.sync_locker)
                weakSelf.notifyTcpServerModelChanged(changeType)
            }
        }
    }
    
    //MARK: -private Func
    private func createStatusMessageInfo(message:String)->TcpServerMessageInfo{
        let messageInfo = TcpServerMessageInfo()
        messageInfo.type = TcpServerMessageInfo.MESSAGE_TYPE.STATUS
        messageInfo.message = message
        messageInfo.timestamp = NSDate.init()
        return messageInfo
    }
    private func createReadWriteMessageInfo(data:NSData?, message:String?, clientTag:Int, type:TcpServerMessageInfo.MESSAGE_TYPE)->TcpServerMessageInfo{
        let messageInfo = TcpServerMessageInfo()
        messageInfo.type = type
        messageInfo.data = data
        messageInfo.message = message
        messageInfo.timestamp = NSDate.init()
        messageInfo.clientTag = clientTag
        //print("messageInfo.type is read: \(messageInfo.type == TcpServerMessageInfo.MESSAGE_TYPE.READ)")
        return messageInfo
    }
    
    private func createTcpServerSocket(){
        if tcpServerSocket != nil{
            for var clientSocket in tcpClientSockets{
                clientSocket?.delegate = nil
                clientSocket?.disconnect()
                clientSocket = nil
            }
            tcpClientSockets = [GCDAsyncSocket?]()
            tcpServerSocket?.delegate = nil
            tcpServerSocket?.disconnect()
            tcpServerSocket = nil
        }
        tcpServerSocket = GCDAsyncSocket.init(delegate: self, delegateQueue: delegateQueue)
    }
    func destroyTcpServer(){
        if tcpServerSocket != nil{
            serverListening = false
            for var clientSocket in tcpClientSockets{
                clientSocket?.delegate = nil
                clientSocket?.disconnect()
                clientSocket = nil
            }
            tcpClientSockets = [GCDAsyncSocket?]()
            tcpServerSocket?.delegate = nil
            tcpServerSocket?.disconnect()
            tcpServerSocket = nil
        }
    }
    
   
    
    //MARK: - Public API
    func startServer()->Bool{
        //print("start Server")
        if tcpServerSocket == nil{
            objc_sync_enter(sync_locker)
            messageInfos = [TcpServerMessageInfo]()
            objc_sync_exit(sync_locker)
            createTcpServerSocket()
        }
        var result = false;
        var message = "";
        if let serverSocket = tcpServerSocket{
            if serverListening == true{
                result = true
                message = "Server[\(serverBehavior.getAssociatedString() == CONSTANTS.SERVER_BEHAVIOR_ECHO.getAssociatedString() ? "echo" : "manual")] start\n at \(UtilityFunctions.getWiFiAddress()):\(serverPortNum)"
            }
            else
            {
                do{
                    try serverSocket.acceptOnPort(serverPortNum)
                    serverListening = true
                    result = true
                    message = "Server[\(serverBehavior.getAssociatedString() == CONSTANTS.SERVER_BEHAVIOR_ECHO.getAssociatedString() ? "echo" : "manual")] start\n at \(UtilityFunctions.getWiFiAddress()):\(serverPortNum)"
                }
                catch let error as NSError{
                    print("\(error)")
                    serverListening = false
                    result = false
                    message = "Unable to start server"
                }
            }
        }
        else
        {
            result = false
            message = "Unable to start server"
        }
        notifyModelChangeSynchronizely(createStatusMessageInfo(message), changeType: "update")
        return result
    }
    
    func writeDataToSocket(socketTag:Int, data:NSData, timeout:NSTimeInterval)
    {
        //print("Socket\(socketTag) WriteData")
        if let socket = tcpClientSockets[socketTag]{
            if socket.isConnected{
                socket.writeData(data, withTimeout: timeout, tag: socketTag)
                notifyModelChangeSynchronizely(createReadWriteMessageInfo(nil, message: String.init(data: data, encoding: dataEncoding.getAssociatedUInt()), clientTag: socketTag, type: TcpServerMessageInfo.MESSAGE_TYPE.WRITE), changeType: "update")
            }
            else
            {
                notifyModelChangeSynchronizely(createStatusMessageInfo("Client[\(socket.connectedHost):\(socket.connectedPort)] is disconnected\nunable to send data"), changeType: "update")
            }
        }
    }
    
    //MARK: -Delegate Methods
    @objc func socket(sock: GCDAsyncSocket!, didAcceptNewSocket newSocket: GCDAsyncSocket!) {
        newSocket.IPv4PreferredOverIPv6 = true
        newSocket.autoDisconnectOnClosedReadStream = true
        newSocket.userData = tcpClientSockets.count 
        newSocket.readDataWithTimeout(-1, tag: newSocket.userData as! Int)
        tcpClientSockets.append(newSocket)
        
        notifyModelChangeSynchronizely(createStatusMessageInfo("Client\(tcpClientSockets.count) [\(newSocket.connectedHost):\(newSocket.connectedPort)] connected"), changeType: "update")
    }
    
    @objc func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        //print("Socket\(tag) didReadData:\(String.init(data: data, encoding: dataEncoding.getAssociatedUInt()))")
        notifyModelChangeSynchronizely(createReadWriteMessageInfo(data, message: nil, clientTag: tag, type: TcpServerMessageInfo.MESSAGE_TYPE.READ), changeType: "update")
        
        if serverBehavior.getAssociatedString() == CONSTANTS.SERVER_BEHAVIOR_ECHO.getAssociatedString(){
            writeDataToSocket(tag, data: data, timeout: 5)
        }
        
        sock.readDataWithTimeout(-1, tag: tag)
    }
    
    @objc func socket(sock: GCDAsyncSocket!, didWriteDataWithTag tag: Int) {
        //print("Socket\(tag) didWriteData")
    }
    
    @objc func socket(sock: GCDAsyncSocket!, shouldTimeoutWriteWithTag tag: Int, elapsed: NSTimeInterval, bytesDone length: UInt) -> NSTimeInterval {

        notifyModelChangeSynchronizely(createStatusMessageInfo("Timeout while sending message to client[\(sock.connectedHost):\(sock.connectedPort)]"), changeType: "update")
        return 0
    }
    @objc func socketDidDisconnect(sock: GCDAsyncSocket!, withError err: NSError!) {
        for (index, var client) in tcpClientSockets.enumerate(){
            if client == sock{
                notifyModelChangeSynchronizely(createStatusMessageInfo("Client\(index + 1) disconnected"), changeType: "update")
                client?.delegate = nil
                client = nil
            }
        }
    }
    
}
















