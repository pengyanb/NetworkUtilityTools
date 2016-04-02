//
//  NetworkUtilityToolSelectionViewController.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 5/11/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import UIKit
import iAd
import GoogleMobileAds

class NetworkUtilityToolSelectionViewController: UIViewController, ADBannerViewDelegate, GADBannerViewDelegate, GADInterstitialDelegate {

    // MARK: - Variables & outlets
    private let segueDictionary = [
        "PingTool":CONSTANTS.SEGUE_SELECT_PING_TOOL,
        "TraceRoute":CONSTANTS.SEGUE_SELECT_TRACE_ROUTE,
        "UdpListener":CONSTANTS.SEGUE_SELECT_UDP_LISTENER,
        "UdpBroadcaster":CONSTANTS.SEGUE_SELECT_UDP_BROADCASTER,
        "TcpClient":CONSTANTS.SEGUE_SELECT_TCP_CLIENT,
        "TcpServer":CONSTANTS.SEGUE_SELECT_TCP_SERVER,
        "UpnpChecker":CONSTANTS.SEGUE_SELECT_UPNP_CHECKER,
        "ServiceMonitor":CONSTANTS.SEGUE_SELECT_SERVICE_MONITOR,
        "WhatsMyIp":CONSTANTS.SEGUE_SELECT_WHATS_MY_IP,
        "PortScanner":CONSTANTS.SEGUE_SELECT_PORT_SCANNER]
    
    @IBOutlet weak var pingToolIconView: NetwrokUtilityToolIconView!
    @IBOutlet weak var traceRouteIconView: NetwrokUtilityToolIconView!
    @IBOutlet weak var udpListenerIconView: NetwrokUtilityToolIconView!
    @IBOutlet weak var udpBroadcasterIconView: NetwrokUtilityToolIconView!
    @IBOutlet weak var tcpServerIconView: NetwrokUtilityToolIconView!
    @IBOutlet weak var tcpClientIconView: NetwrokUtilityToolIconView!
    @IBOutlet weak var upnpCheckerIconView: NetwrokUtilityToolIconView!
    @IBOutlet weak var serviceMonitorIconView: NetwrokUtilityToolIconView!
    @IBOutlet weak var whatsMyIpIconView: NetwrokUtilityToolIconView!
    @IBOutlet weak var portScannerIconView: NetwrokUtilityToolIconView!
    
    
    @IBOutlet weak var iAdBanner: ADBannerView!
    
    @IBOutlet weak var iAdBannerHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var bannerView: GADBannerView!
    
    @IBOutlet weak var bannerViewHeightConstraint: NSLayoutConstraint!
    
    var interstitial : GADInterstitial!
    
    var needToShowInterstitial = true
    
    // MARK: - View Controller life cycle
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait;
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        iAdBanner.delegate = self
        pingToolIconView.tapHandler = iconTapHanndler
        traceRouteIconView.tapHandler = iconTapHanndler
        udpListenerIconView.tapHandler = iconTapHanndler
        udpBroadcasterIconView.tapHandler = iconTapHanndler
        tcpServerIconView.tapHandler = iconTapHanndler
        tcpClientIconView.tapHandler = iconTapHanndler
        upnpCheckerIconView.tapHandler = iconTapHanndler
        serviceMonitorIconView.tapHandler = iconTapHanndler
        whatsMyIpIconView.tapHandler = iconTapHanndler
        portScannerIconView.tapHandler = iconTapHanndler
        // Do any additional setup after loading the view.
        
        bannerViewHeightConstraint.constant = 50
        iAdBannerHeightConstraint.constant = 0
        initAdMob()
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        bannerView.loadRequest(GADRequest())
        if needToShowInterstitial{
            createInterstitial()
        }
    }
    
    // MARK: - Custom Func
    func iconTapHanndler(iconName:String)->Void{
        print("\(iconName) tapped")
        if let segueIdentifier = segueDictionary[iconName]
        {
            needToShowInterstitial = true
            performSegueWithIdentifier(segueIdentifier.getAssociatedString(), sender: self)
        }
    }
    
    //MARK: -Delegate methods
    func bannerViewDidLoadAd(banner: ADBannerView!) {
        /*
        iAdBannerHeightConstraint.constant = 50
        bannerViewHeightConstraint.constant = 0
        */
        //print("[bannerViewDidLoadAd]")
    }
    
    func bannerView(banner: ADBannerView!, didFailToReceiveAdWithError error: NSError!) {
        /*
        iAdBannerHeightConstraint.constant = 0
        bannerViewHeightConstraint.constant = 50
        initAdMobBanner()
        */
        //print("[BannerViewDidFailToReceiveAdWithError]:\(error)")
    }
    
    func adViewDidReceiveAd(bannerView: GADBannerView!) {
        print("[adViewDidReceivedAd]")
    }
    func adView(bannerView: GADBannerView!, didFailToReceiveAdWithError error: GADRequestError!) {
        print("[adViewDidFailToReceiveAdWithError]: \(error)")
    }
    func interstitialDidReceiveAd(ad: GADInterstitial!) {
        print("[interstitialDidReceiveAd]")
        needToShowInterstitial = false

        self.interstitial.presentFromRootViewController(UIApplication.sharedApplication().keyWindow?.rootViewController)
        
    }
    func interstitial(ad: GADInterstitial!, didFailToReceiveAdWithError error: GADRequestError!) {
        print("[interstitialDidFailToReceiveAdWithError]:\(error)")
    }
    //MARK: -Custom functions
    private func initAdMob(){
        bannerView.delegate = self
        bannerView.adUnitID = "2077ef9a63d2b398840261c8221a0c9b"
        bannerView.rootViewController = self
        bannerView.adSize = kGADAdSizeSmartBannerPortrait
        
    }
    
    private func createInterstitial(){
        if self.interstitial != nil{
            self.interstitial.delegate = nil
            self.interstitial = nil
        }
        self.interstitial = GADInterstitial(adUnitID: "2077ef9a63d2b398840261c8221a0c9b")
        self.interstitial.delegate = self
        let request = GADRequest()
        //request.testDevices = ["2077ef9a63d2b398840261c8221a0c9b"]
        self.interstitial.loadRequest(request)
    }

    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
}


















