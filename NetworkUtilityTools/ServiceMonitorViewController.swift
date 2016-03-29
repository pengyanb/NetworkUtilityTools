//
//  ServiceMonitorViewController.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 2/01/16.
//  Copyright © 2016 Yanbing Peng. All rights reserved.
//

import UIKit
import PNChart

class ServiceMonitorViewController: UIViewController, UIPopoverPresentationControllerDelegate {

    //MARK: -variables 
    let dateFormatter = NSDateFormatter.init()
    
    @IBOutlet weak var pieChart: PNPieChart!

    @IBOutlet weak var statisticTextView: UITextView!
    
    //MARK: -UI Orientation
    override func shouldAutorotate() -> Bool {
        return false
    }
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
    //MARK: -View life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        UIDevice.currentDevice().setValue(UIInterfaceOrientation.Portrait.rawValue, forKey: "orientation")
        UIApplication.sharedApplication().applicationIconBadgeNumber = 0
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleResultChanges:"), name: CONSTANTS.NOTI_SERVICE_MONITOR_RESULT_CHANGED.getAssociatedString(), object: nil)
        updateUI()
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func handleResultChanges(notification:NSNotification){
        dispatch_async(dispatch_get_main_queue()) {[unowned self] () -> Void in
            self.updateUI()
        }
    }
    
    //MARK: -Private Func
    private func updateUI(){
        var items = [PNPieChartDataItem]()
        var statisticText : String?
        if let serviceMonitorResults = NSUserDefaults.standardUserDefaults().objectForKey(CONSTANTS.NSUSER_DEFAULT_SERVICE_MONITOR_RESULT_KEY.getAssociatedString()), serviceMonitorDefaults = NSUserDefaults.standardUserDefaults().objectForKey(CONSTANTS.NSUSER_DEFAULT_SERVICE_MONITOR_SETTING_KEY.getAssociatedString()){
            print("serviceMonitorResults: \(serviceMonitorResults)")
            print("serviceMonitorDefaults: \(serviceMonitorDefaults)")
            
            var isRunning = false
            
            if let serviceTypeIndex = serviceMonitorDefaults["ServiceTypeIndex"] as? Int{
                if let running = serviceMonitorDefaults["IsRunning"] as? Bool{
                    isRunning = running
                }
                switch serviceTypeIndex{
                case 0:
                    if let url = serviceMonitorDefaults["URL"] as? String{
                        statisticText = "Service Monitor [HTTP]\r\n\r\nURL:\t\(url)\r\nStatus:\t\(isRunning ? "Running" : "Stopped")\r\n"
                    }
                case 1:
                    if let ipAddress = serviceMonitorDefaults["IpAddress"] as? String, port = serviceMonitorDefaults["PortNumber"] as? Int{
                        statisticText = "Service Monitor [TCP]\r\n\r\nEndPoint:\t\(ipAddress):\(port)\r\nStatus:\t\(isRunning ? "Running" : "Stopped")\r\n"
                    }
                case 2:
                    if let ipAddress = serviceMonitorDefaults["IpAddress"] as? String, port = serviceMonitorDefaults["PortNumber"] as? Int{
                        statisticText = "Service Monitor [UDP]\r\n\r\nEndPoint:\t\(ipAddress):\(port)\r\nStatus:\t\(isRunning ? "Running" : "Stopped")\r\n"
                    }
                default: break
                }
            }
            
            if let fetchTotalCount = serviceMonitorResults["FetchTotalCount"] as? Int{
                if fetchTotalCount > 0{
                    print("fetchTotalCount: \(fetchTotalCount)")
                    if let fetchSuccessCount = serviceMonitorResults["FetchSuccessCount"] as? Int{
                        if fetchSuccessCount > 0 {
                            items.append(PNPieChartDataItem.init(value: CGFloat.init(fetchSuccessCount), color: UIColor.greenColor(), description: "Success"))
                            if let latestSuccessTime = serviceMonitorResults["FetchLatestSuccessTime"] as? NSDate, _ = statisticText{
                                statisticText = statisticText! + "Last Success Time:\t\(dateFormatter.stringFromDate(latestSuccessTime))\r\nSuccess Count:\t\(fetchSuccessCount)\r\n"
                            }
                        }
                    }
                    if let fetchFailCount = serviceMonitorResults["FetchFailCount"] as? Int{
                        if fetchFailCount > 0{
                            items.append(PNPieChartDataItem.init(value: CGFloat.init(fetchFailCount), color: UIColor.redColor(), description: "Fail"))
                            if let latestFailTime = serviceMonitorResults["FetchLatestFailTime"] as? NSDate, _ = statisticText{
                                statisticText = statisticText! + "Last Fail Time:\t\(dateFormatter.stringFromDate(latestFailTime))\r\nFail Count:\t\(fetchFailCount)\r\n"
                            }
                        }
                    }
                    if let fetchNoConnectionCount = serviceMonitorResults["FetchNoConnectionCount"] as? Int{
                        if fetchNoConnectionCount > 0{
                            items.append(PNPieChartDataItem.init(value: CGFloat.init(fetchNoConnectionCount), color: UIColor.darkGrayColor(), description: "NC"))
                        }
                    }
                }
            }
        }
        if items.isEmpty{
            items.append(PNPieChartDataItem.init(value: CGFloat.init(1), color: UIColor.darkGrayColor(), description: "No Statitisc"))
        }
        pieChart.updateChartData(items)
        pieChart.descriptionTextColor = UIColor.whiteColor()
        pieChart.strokeChart()
        
        if let statistic = statisticText{
            statisticTextView.text = statistic
        }
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier{
            if identifier == CONSTANTS.SEGUE_SERVICE_MONITOR_OPTIONS.getAssociatedString(){
                if let serviceMonitorOptionVC = segue.destinationViewController as? ServiceMonitorOptionsViewController{
                    //!! todo
                    if let ppc = serviceMonitorOptionVC.popoverPresentationController{
                        ppc.delegate = self
                    }
                }
            }
        }
    }

    //MARK: -delegate
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
}


















