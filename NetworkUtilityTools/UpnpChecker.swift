//
//  UpnpChecker.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 2/01/16.
//  Copyright © 2016 Yanbing Peng. All rights reserved.
//

import Foundation

class UpnpChecker : NSObject, GCDAsyncUdpSocketDelegate, NSXMLParserDelegate{
    
    //MARK: -variables
    var upnpCheckerProcedureIndex = 0
    private let defaultTimeout = 5
    private let upnpDiscoveryMessage =    "M-SEARCH * HTTP/1.1\r\n"
                                        + "Host: 239.255.255.250:1900\r\n"
                                        + "ST: urn:schemas-upnp-org:device:InternetGatewayDevice:1\r\n"
                                        //+ "ST: ssdp:all\r\n"
                                        + "Man: \"ssdp:discover\"\r\n"
                                        + "MX: 3\r\n\r\n"
    
    private var udpSocket : GCDAsyncUdpSocket?
    
    private let delegateQueue : dispatch_queue_t = dispatch_get_global_queue(QOS_CLASS_DEFAULT, 0)
    
    private var upnpServerLocation : String?
    
    private var upnpServerHost : String?
    
    private var upnpServerControlURL : String?
    
    private var ssdpSearchTimer : NSTimer?
    
    private var upnpPortToCheck : UInt16 = 8080
    
    private var localIPAddress : String = UtilityFunctions.getWiFiAddress()
    
    var needRemovePort: Bool = false
    
    //MARK: -private func
    private func createUdpSocket()->GCDAsyncUdpSocket?{
        upnpServerLocation = nil
        upnpServerControlURL = nil
        upnpServerHost = nil
        let sock = GCDAsyncUdpSocket.init(delegate: self, delegateQueue: self.delegateQueue)
        sock.setPreferIPv4()
        do{
            try sock.bindToPort(0)
            try sock.enableBroadcast(true)
            try sock.joinMulticastGroup("239.255.255.250")
            try sock.beginReceiving()
            //print("[Socket bind to Local Port: \(sock.localPort())]")
        }
        catch let err as NSError{
            print("\(err)")
            return nil
        }
        return sock
    }
    private func handleUpnpCheckProcedure()
    {
        if upnpCheckerProcedureIndex == 1
        {
            if let upnpDiscoveryMessageData = upnpDiscoveryMessage.dataUsingEncoding(CONSTANTS.ENCODING_UTF8.getAssociatedUInt()){
                
                udpSocket?.sendData(upnpDiscoveryMessageData, toHost: "239.255.255.250", port: 1900, withTimeout: 5, tag: upnpCheckerProcedureIndex)
                
            }
        }
        else if upnpCheckerProcedureIndex == 2{
            if let serverLocation = upnpServerLocation{
                if let serverUrl = NSURL(string: serverLocation)
                {
                    let request = NSMutableURLRequest(URL: serverUrl)
                    request.HTTPMethod = "GET"
                    request.setValue("text/xml, application/xml", forHTTPHeaderField: "Accept")
                    upnpCheckerProcedureIndex = 3
                    postModelChangeNotification("\(upnpCheckerProcedureIndex) [Requesting Server UPnP Description]:\r\nURL:\(serverLocation)\r\n\r\n", type: "status")
                    let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: {[unowned self] (data, response, error) -> Void in
                        guard error == nil && data != nil else{
                            print("Error: \(error)")
                            print("Data: \(data)")
                            self.upnpCheckerProcedureIndex = 4
                            self.postModelChangeNotification("\(self.upnpCheckerProcedureIndex) [Error occured while requesting]\r\n", type: "status")
                            self.upnpCheckerProcedureIndex = 0
                            self.postModelChangeNotification("Error: error occured while requesting", type: "result")
                            return
                        }
                        
                        if let responseString = String.init(data: data!, encoding: CONSTANTS.ENCODING_UTF8.getAssociatedUInt())
                        {
                            let responseNSString = responseString as NSString
                            if (responseNSString.rangeOfString("<?xml", options: NSStringCompareOptions.CaseInsensitiveSearch).location != NSNotFound) && (responseNSString.rangeOfString("<root", options: NSStringCompareOptions.CaseInsensitiveSearch).location != NSNotFound) && (responseNSString.rangeOfString("urn:schemas-upnp-org:device:InternetGatewayDevice:1", options: NSStringCompareOptions.CaseInsensitiveSearch).location != NSNotFound) && (responseNSString.rangeOfString("urn:schemas-upnp-org:service:WANIPConnection:1", options: NSStringCompareOptions.CaseInsensitiveSearch).location != NSNotFound) && (responseNSString.rangeOfString("<controlURL", options: NSStringCompareOptions.CaseInsensitiveSearch).location != NSNotFound) {
                                
                                self.upnpCheckerProcedureIndex = 4
                                self.postModelChangeNotification("\(self.upnpCheckerProcedureIndex) [UPnP Description Response]:\r\n\(responseString)\r\n\r\n", type: "status")
                                
                                if (serverUrl.host != nil) && (serverUrl.port != nil){
                                    self.upnpServerHost = serverUrl.host! + ":" + "\(serverUrl.port!)"
                                }
                                
                                let serviceTypeRange = responseNSString.rangeOfString("urn:schemas-upnp-org:service:WANIPConnection:1", options: NSStringCompareOptions.CaseInsensitiveSearch)
                                let serviceOfInterestStartRange = responseNSString.rangeOfString("<service", options: [NSStringCompareOptions.CaseInsensitiveSearch, NSStringCompareOptions.BackwardsSearch], range: NSMakeRange(0, serviceTypeRange.location))
                                let serviceOfInterestEndRange = responseNSString.rangeOfString("</service>", options: NSStringCompareOptions.CaseInsensitiveSearch, range: NSMakeRange(serviceTypeRange.location, responseNSString.length-serviceTypeRange.location))
                                //print("[StartRange]: \(serviceOfInterestStartRange)\n[EndRange]: \(serviceOfInterestEndRange)")
                                let serviceOfInterest = responseNSString.substringWithRange(NSMakeRange(serviceOfInterestStartRange.location, serviceOfInterestEndRange.location + serviceOfInterestEndRange.length - serviceOfInterestStartRange.location)) as NSString
                                
                                //print("[Service Of Interest]: \(serviceOfInterest)")
                                if (serviceOfInterest.rangeOfString("<controlURL>", options: NSStringCompareOptions.CaseInsensitiveSearch).location != NSNotFound) && (serviceOfInterest.rangeOfString("</controlURL>", options: NSStringCompareOptions.CaseInsensitiveSearch).location != NSNotFound){
                                    let controlURLStartRange = serviceOfInterest.rangeOfString("<controlURL>", options: NSStringCompareOptions.CaseInsensitiveSearch)
                                    let controlURLEndRange = serviceOfInterest.rangeOfString("</controlURL>", options: NSStringCompareOptions.CaseInsensitiveSearch)
                                    self.upnpServerControlURL = serviceOfInterest.substringWithRange(NSMakeRange(controlURLStartRange.location + controlURLStartRange.length, controlURLEndRange.location - controlURLStartRange.location - controlURLStartRange.length))
                                    print("[ControlURL]: \(self.upnpServerControlURL)")
                                    self.handleUpnpCheckProcedure()
                                    return
                                }
                            }
                        }
                        self.upnpCheckerProcedureIndex = 0
                        self.postModelChangeNotification("Invalid UPnP Descripion received\r\n", type: "status")
                        self.postModelChangeNotification("Error: Invalid UPnP Descripion received", type: "result")
                    })
                    task.resume()
                }
            }
        }
        else if upnpCheckerProcedureIndex == 4{
            if let controlURL = upnpServerControlURL{
                if let serverHost = upnpServerHost{
                    if let postURL = NSURL(string: "http://\(serverHost)\(controlURL)"){
                        print("http://\(serverHost)\(controlURL)")
                        var requestBody = "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
                        requestBody +=    "<s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">"
                        requestBody +=      "<s:Body>"
                        requestBody +=      "<u:AddPortMapping xmlns:u=\"urn:schemas-upnp-org:service:WANIPConnection:1\">"
                        requestBody +=      "<NewRemoteHost></NewRemoteHost>"
                        requestBody +=      "<NewExternalPort>" + "\(upnpPortToCheck)" + "</NewExternalPort>"
                        requestBody +=      "<NewProtocol>TCP</NewProtocol>"
                        requestBody +=      "<NewInternalPort>" + "\(upnpPortToCheck)" + "</NewInternalPort>"
                        requestBody +=      "<NewInternalClient>\(localIPAddress)</NewInternalClient>"
                        requestBody +=      "<NewEnabled>1</NewEnabled>"
                        requestBody +=      "<NewPortMappingDescription>NUTools_\(upnpPortToCheck)</NewPortMappingDescription>"
                        requestBody +=      "<NewLeaseDuration>60</NewLeaseDuration>"
                        requestBody +=      "</u:AddPortMapping>"
                        requestBody +=      "</s:Body>"
                        requestBody +=  "</s:Envelope>\r\n\r\n"
            
                        let request = NSMutableURLRequest(URL: postURL)
                        request.HTTPMethod = "POST"
                        request.setValue("text/xml", forHTTPHeaderField: "Content-Type")
                        request.setValue("\"urn:schemas-upnp-org:service:WANIPConnection:1#AddPortMapping\"", forHTTPHeaderField: "SOAPAction")
                        request.setValue("\(requestBody.characters.count)", forHTTPHeaderField:"Content-Length")
                        request.HTTPBody =  requestBody.dataUsingEncoding(CONSTANTS.ENCODING_UTF8.getAssociatedUInt())
                        upnpCheckerProcedureIndex = 5
                        postModelChangeNotification("\(upnpCheckerProcedureIndex) [Transmit SOAP Control Action]:\r\n\(requestBody)\r\n\r\n", type: "status")
                        let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { [unowned self] (data, response, error) -> Void in
                            guard error == nil && data != nil else{
                                print("Error: \(error)")
                                print("Data: \(data)")
                                self.upnpCheckerProcedureIndex = 6
                                self.postModelChangeNotification("\(self.upnpCheckerProcedureIndex) [Error occured while transmitting SOAP Control Action]\r\n", type: "status")
                                return
                            }
                            
                            if let responseString = String.init(data: data!, encoding: CONSTANTS.ENCODING_UTF8.getAssociatedUInt()){
                                self.upnpCheckerProcedureIndex = 6
                                self.postModelChangeNotification("\(self.upnpCheckerProcedureIndex) [Received SOAP Response]:\r\n\(responseString)\r\n\r\n", type: "status")
                                if (responseString as NSString).rangeOfString("AddPortMappingResponse").location != NSNotFound
                                {
                                    self.needRemovePort = true
                                    self.postModelChangeNotification("Success: Port Forwarded", type: "result")
                                }
                                else if (responseString as NSString).rangeOfString("<errorDescription>").location != NSNotFound && (responseString as NSString).rangeOfString("</errorDescription>").location != NSNotFound{
                                    let startRange = (responseString as NSString).rangeOfString("<errorDescription>")
                                    let endIndex = (responseString as NSString).rangeOfString("</errorDescription>").location
                                    let errorMessage = (responseString as NSString).substringWithRange(NSMakeRange(startRange.location + startRange.length, endIndex - startRange.location - startRange.length))
                                    self.postModelChangeNotification("Error: " + errorMessage, type: "result")
                                }
                                else{
                                    self.postModelChangeNotification("Error: invalid response", type: "result")
                                }
                            }
                        })
                        task.resume()
                    }
                }
            }
        }
    }
    private func postModelChangeNotification(message:String, type:String)
    {
        //print("\(message)")
        NSNotificationCenter.defaultCenter().postNotificationName(CONSTANTS.NOTI_UPNP_CHECKER_MODEL_CHANGED.getAssociatedString(), object: self, userInfo: [type : message])
    }
    
    func ssdpRequestTimeout(timer:NSTimer){
        upnpCheckerProcedureIndex = 2
        postModelChangeNotification("\(upnpCheckerProcedureIndex) [SSDP search request timeout]\r\n", type: "status")
        upnpCheckerProcedureIndex = 0
        postModelChangeNotification("Error: SSDP search request timeout", type: "result")
    }
    
    //MARK: -public func
    func startUpnpCheck(port:UInt16){
        if upnpCheckerProcedureIndex == 0{
            upnpPortToCheck = port
            udpSocket = createUdpSocket()
            upnpCheckerProcedureIndex = 1
            handleUpnpCheckProcedure()
            ssdpSearchTimer = NSTimer.scheduledTimerWithTimeInterval(5, target: self, selector: Selector("ssdpRequestTimeout:"), userInfo: nil, repeats: false)
        }
    }
    
    func removeForwardedPort(){
        self.needRemovePort = false
        if let controlURL = upnpServerControlURL, serverHost = upnpServerHost{
            print("http://\(serverHost)\(controlURL)")
            if let postURL = NSURL(string: "http://\(serverHost)\(controlURL)"){
                var requestBody =   "<?xml version=\"1.0\" encoding=\"utf-8\"?>"
                requestBody +=      "<s:Envelope xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\" xmlns:s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">"
                requestBody +=      "<s:Body>"
                requestBody +=      "<u:DeletePortMapping xmlns:u=\"urn:schemas-upnp-org:service:WANIPConnection:1\">"
                requestBody +=      "<NewRmoteHost></NewRemoteHost>"
                requestBody +=      "<NewExternalPort>\(upnpPortToCheck)</NewExternalPort>"
                requestBody +=      "<NewProtocol>TCP</NewProtocol>"
                requestBody +=      "</u:DeletePortMapping>"
                requestBody +=      "</s:Body>"
                requestBody +=      "</s:Envelope>\r\n\r\n"
                
                let request = NSMutableURLRequest(URL: postURL)
                request.HTTPMethod = "POST"
                request.setValue("text/xml", forHTTPHeaderField: "Content-Type")
                request.setValue("\"urn:schemas-upnp-org:service:WANIPConnection:1#DeletePortMapping\"", forHTTPHeaderField: "SOAPAction")
                request.setValue("\(requestBody.characters.count)", forHTTPHeaderField: "Content-Length")
                request.HTTPBody = requestBody.dataUsingEncoding(CONSTANTS.ENCODING_UTF8.getAssociatedUInt())
                postModelChangeNotification("[Transmit SOAP Control Action]:\r\n\(requestBody)\r\n\r\n", type: "status")
                let task = NSURLSession.sharedSession().dataTaskWithRequest(request, completionHandler: { [unowned self] (data, response, error) -> Void in
                    guard error == nil  && data != nil else{
                        self.postModelChangeNotification("Error: unable to remove port", type: "result")
                        return
                    }
                    
                    if let responseString = String.init(data: data!, encoding: CONSTANTS.ENCODING_UTF8.getAssociatedUInt()){
                        self.postModelChangeNotification("[Received SOAP Response]:\r\n\(responseString)\r\n\r\n", type: "status")
                        if (responseString as NSString).rangeOfString("DeletePortMappingResponse").location != NSNotFound{
                            self.postModelChangeNotification("Success: Port Removed", type: "result")
                        }
                        else if (responseString as NSString).rangeOfString("<errorDescription>").location != NSNotFound && (responseString as NSString).rangeOfString("</errorDescription>").location != NSNotFound{
                            let startRange = (responseString as NSString).rangeOfString("<errorDescription>")
                            let endIndex = (responseString as NSString).rangeOfString("</errorDescription>").location
                            let errorMessage = (responseString as NSString).substringWithRange(NSMakeRange(startRange.location + startRange.length, endIndex - startRange.location - startRange.length))
                            self.postModelChangeNotification("Error: " + errorMessage , type: "result")
                        }
                        else
                        {
                            self.postModelChangeNotification("Error: invalid response", type: "result")
                        }
                    }
                })
                task.resume()
            }
        }

    }
    
    //MARK: -Delegate Metods
    @objc func udpSocket(sock: GCDAsyncUdpSocket!, didSendDataWithTag tag: Int) {
        //print("[udpSocket didSendDataWithTag:\(tag)]")
        postModelChangeNotification("\(upnpCheckerProcedureIndex) [SSDP search request for UPnP compliant device] :\r\n\(upnpDiscoveryMessage)", type: "status")
    }
    
    @objc func udpSocket(sock: GCDAsyncUdpSocket!, didReceiveData data: NSData!, fromAddress address: NSData!, withFilterContext filterContext: AnyObject!) {
        //print("[udpSocket didReceiveData]: \(String.init(data: data, encoding: CONSTANTS.ENCODING_UTF8.getAssociatedUInt())))")
        let ssdpResponse = String.init(data: data, encoding: CONSTANTS.ENCODING_UTF8.getAssociatedUInt())
        if ssdpResponse != nil{
            let response = ssdpResponse! as NSString
            if (response.rangeOfString("HTTP/1.1 200 OK", options: NSStringCompareOptions.CaseInsensitiveSearch).location != NSNotFound) && (response.rangeOfString("LOCATION", options: NSStringCompareOptions.CaseInsensitiveSearch).location != NSNotFound) && (response.rangeOfString("CACHE-CONTROL", options: NSStringCompareOptions.CaseInsensitiveSearch).location != NSNotFound) && (response.rangeOfString("SERVER", options: NSStringCompareOptions.CaseInsensitiveSearch).location != NSNotFound) && (response.rangeOfString("ST", options: NSStringCompareOptions.CaseInsensitiveSearch).location != NSNotFound) && (response.rangeOfString("USN", options: NSStringCompareOptions.CaseInsensitiveSearch).location != NSNotFound){

                
                
                let locationIndex = response.rangeOfString("LOCATION", options: NSStringCompareOptions.CaseInsensitiveSearch).location
                let responseAtLocation = response.substringFromIndex(locationIndex) as NSString
                let newLineIndex = responseAtLocation.rangeOfString("\r\n", options: NSStringCompareOptions.CaseInsensitiveSearch).location
                let locationLine = responseAtLocation.substringToIndex(newLineIndex) as NSString
                if locationLine.rangeOfString(":", options: NSStringCompareOptions.CaseInsensitiveSearch).location != NSNotFound{
                    let locationLineSplits = locationLine.componentsSeparatedByString(":")
                    for var i = 1; i < locationLineSplits.count; i++
                    {
                        let part = locationLineSplits[i].stringByTrimmingCharactersInSet(NSCharacterSet.whitespaceAndNewlineCharacterSet())
                        upnpServerLocation = (upnpServerLocation == nil) ? part : (upnpServerLocation! + ":" + part)
                        
                    }
                    //print(upnpServerLocation)
                    ssdpSearchTimer?.invalidate()
                    upnpCheckerProcedureIndex = 2
                    postModelChangeNotification("\(upnpCheckerProcedureIndex) [SSDP response captured] :\r\n\(ssdpResponse!)", type: "status")
                    handleUpnpCheckProcedure()
                }
                
            }
        }
        //print("FromAddress: \(address)")
    }
}





















