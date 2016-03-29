//
//  WhatsMyIpViewController.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 10/02/16.
//  Copyright © 2016 Yanbing Peng. All rights reserved.
//

import UIKit

class WhatsMyIpViewController: UIViewController, STUNClientDelegate, GCDAsyncUdpSocketDelegate{

    //MARK: -variables
    var udpSocket : GCDAsyncUdpSocket?
    var stunClient : STUNClient?
    
    //MARK: -outlets
    @IBOutlet weak var ipAddressLabelView: UILabel!
    
    //MARK: -view life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        checkPublicIpAddress()
    }
    
    //MARK: -target action
    @IBAction func refreshButtonPressed() {
        checkPublicIpAddress()
    }
    
    //MARK: -delegate
    func didReceivePublicIPandPort(data: [NSObject : AnyObject]!) {
        print("Public IP: \(data["publicIPKey"]) Port:\(data["publicPortKey"])")
        if let ipAddress =  data["publicIPKey"] as? String{
            ipAddressLabelView.text = ipAddress
        }
        
    }
    
    //MARK: -private functions
    private func checkPublicIpAddress(){
        ipAddressLabelView.text = "Unknown"
        if checkNetworkStatus(){
            udpSocket = GCDAsyncUdpSocket.init(delegate: self, delegateQueue: dispatch_get_main_queue())
            stunClient = STUNClient.init()
            stunClient?.requestPublicIPandPortWithUDPSocket(udpSocket, delegate: self)
        }
        else
        {
            UIAlertView.init(title: "Error", message: "No internet connection", delegate: nil, cancelButtonTitle: "OK").show()
        }
    }

    private func checkNetworkStatus()->Bool{
        do{
            let reachability:Reachability = try Reachability.reachabilityForInternetConnection()
            let networkStatus = reachability.currentReachabilityStatus.hashValue
            return networkStatus != 0
        }
        catch{
            return false
        }
    }
}














