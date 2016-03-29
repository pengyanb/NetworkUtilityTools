//
//  AppDelegate.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 28/10/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var serviceMonitorModel : ServiceMonitor?

    func performServiceMonitorRoutine(complettionHandler: ((UIBackgroundFetchResult) ->Void)){
        if var serviceMonitorDefaults = NSUserDefaults.standardUserDefaults().objectForKey(CONSTANTS.NSUSER_DEFAULT_SERVICE_MONITOR_SETTING_KEY.getAssociatedString()) as? [String:AnyObject], serviceMonitorResults = NSUserDefaults.standardUserDefaults().objectForKey(CONSTANTS.NSUSER_DEFAULT_SERVICE_MONITOR_RESULT_KEY.getAssociatedString()) as? [String:AnyObject]{
            
            if let isRunning = serviceMonitorDefaults["IsRunning"] as? Bool{
                if isRunning{
                    var fetchAlertWhenFail = true
                    if let alertWhenFail = serviceMonitorDefaults["FetchAlertWhenFail"] as? Bool{
                        fetchAlertWhenFail = alertWhenFail
                    }
                    if let serviceTypeIndex = serviceMonitorDefaults["ServiceTypeIndex"] as? Int{
                        if let responseSample = serviceMonitorDefaults["ResponseSample"] as? String, testCriteriaIndex = serviceMonitorDefaults["TestCriteriaIndex"] as? Int{
                            serviceMonitorModel = ServiceMonitor.init(successHandler: { [unowned self] (response) -> (Void) in
                                var fetchResult = UIBackgroundFetchResult.NoData
                                if let responseUnwrapped = response{
                                    if testCriteriaIndex == 0 && response == responseSample{
                                        serviceMonitorResults["FetchSuccessCount"] = (serviceMonitorResults["FetchSuccessCount"] as? Int)! + 1
                                        fetchResult = UIBackgroundFetchResult.NewData
                                        serviceMonitorResults["FetchLatestSuccessTime"] = NSDate.init()
                                        if !fetchAlertWhenFail{
                                            serviceMonitorDefaults["FetchAlertWhenFail"] = !fetchAlertWhenFail
                                            self.serviceMonitorLocalNotification("Network Utility Tool [Service Monitor]\r\nDetect service back online")
                                        }
                                    }
                                    else if testCriteriaIndex == 1 && (responseUnwrapped as NSString).rangeOfString(responseSample).location != NSNotFound{
                                        serviceMonitorResults["FetchSuccessCount"] = (serviceMonitorResults["FetchSuccessCount"] as? Int)! + 1
                                        fetchResult = UIBackgroundFetchResult.NewData
                                        serviceMonitorResults["FetchLatestSuccessTime"] = NSDate.init()
                                        if !fetchAlertWhenFail{
                                            serviceMonitorDefaults["FetchAlertWhenFail"] = !fetchAlertWhenFail
                                            self.serviceMonitorLocalNotification("Network Utility Tool [Service Monitor]\r\nDetect service back online")
                                        }
                                    }
                                    else{
                                        serviceMonitorResults["FetchFailCount"] = (serviceMonitorResults["FetchFailCount"] as? Int)! + 1
                                        serviceMonitorResults["FetchLatestFailTime"] = NSDate.init()
                                        if fetchAlertWhenFail{
                                            serviceMonitorDefaults["FetchAlertWhenFail"] = !fetchAlertWhenFail
                                            self.serviceMonitorLocalNotification("Network Utility Tool [Service Monitor]\r\nDetect service offline")
                                        }
                                    }
                                }
                                else{
                                    serviceMonitorResults["FetchFailCount"] = (serviceMonitorResults["FetchFailCount"] as? Int)! + 1
                                    serviceMonitorResults["FetchLatestFailTime"] = NSDate.init()
                                    if fetchAlertWhenFail{
                                        serviceMonitorDefaults["FetchAlertWhenFail"] = !fetchAlertWhenFail
                                        self.serviceMonitorLocalNotification("Network Utility Tool [Service Monitor]\r\nDetect service offline")
                                    }
                                }
                                self.updateServiceMonitorResults(serviceMonitorDefaults, serviceMonitorResults: serviceMonitorResults, complettionHandler: complettionHandler, fetchResult: fetchResult)
                                }, errorHandler: { (errorMessage) -> (Void) in
                                    serviceMonitorResults["FetchFailCount"] = (serviceMonitorResults["FetchFailCount"] as? Int)! + 1
                                    serviceMonitorResults["FetchLatestFailTime"] = NSDate.init()
                                    if fetchAlertWhenFail{
                                        serviceMonitorDefaults["FetchAlertWhenFail"] = !fetchAlertWhenFail
                                        self.serviceMonitorLocalNotification("Network Utility Tool [Service Monitor]\r\nDetect service offline")
                                    }
                                    self.updateServiceMonitorResults(serviceMonitorDefaults,serviceMonitorResults: serviceMonitorResults, complettionHandler: complettionHandler, fetchResult: .NoData)
                            })
                        }
                        switch serviceTypeIndex{
                        case 0: if let url = serviceMonitorDefaults["URL"] as? String, httpMethodIndex = serviceMonitorDefaults["HttpMethodIndex"] as? Int{
                            var httpBody:String? = nil
                            if let body = serviceMonitorDefaults["HttpBody"] as? String{
                                httpBody = body
                            }
                            serviceMonitorModel?.sendHttpRequest(url, method: (httpMethodIndex == 0) ? "GET" : "POST", dataToPost: httpBody)
                            }
                        case 1: if let portNumber = serviceMonitorDefaults["PortNumber"] as? Int, ipAddress = serviceMonitorDefaults["IpAddress"] as? String, dataToSend = serviceMonitorDefaults["DataToSend"] as? String{
                            serviceMonitorModel?.sendTcpRequest(ipAddress, port: UInt16.init(portNumber), dataToSend: dataToSend)
                            return
                            }
                        case 2: if let portNumber = serviceMonitorDefaults["PortNumber"] as? Int, ipAddress = serviceMonitorDefaults["IpAddress"] as? String, dataToSend = serviceMonitorDefaults["DataToSend"] as? String{
                            serviceMonitorModel?.sendUdpRequest(ipAddress, port: UInt16.init(portNumber), dataToSend: dataToSend)
                            return
                            }
                        default: break
                        }
                    }
                }
            }
        }
        complettionHandler(.NoData)
    }
    
    func updateServiceMonitorResults(ServiceMonitorDefaults:[String:AnyObject], var serviceMonitorResults:[String:AnyObject], complettionHandler: (UIBackgroundFetchResult) ->Void, fetchResult:UIBackgroundFetchResult){
        serviceMonitorResults["FetchTotalCount"] = (serviceMonitorResults["FetchTotalCount"] as? Int)! + 1
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            NSUserDefaults.standardUserDefaults().setObject(serviceMonitorResults, forKey: CONSTANTS.NSUSER_DEFAULT_SERVICE_MONITOR_RESULT_KEY.getAssociatedString())
            NSUserDefaults.standardUserDefaults().setObject(ServiceMonitorDefaults, forKey: CONSTANTS.NSUSER_DEFAULT_SERVICE_MONITOR_SETTING_KEY.getAssociatedString())
        }
        
        NSNotificationCenter.defaultCenter().postNotificationName(CONSTANTS.NOTI_SERVICE_MONITOR_RESULT_CHANGED.getAssociatedString(), object: nil)
        
        complettionHandler(fetchResult)
    }
    
    func serviceMonitorLocalNotification(alertMessage:String){
        let localNotification  = UILocalNotification.init()
        localNotification.fireDate = NSDate(timeIntervalSinceNow: 3)
        localNotification.alertBody = alertMessage
        localNotification.timeZone = NSTimeZone.defaultTimeZone()
        localNotification.applicationIconBadgeNumber = UIApplication.sharedApplication().applicationIconBadgeNumber + 1
        localNotification.soundName = UILocalNotificationDefaultSoundName
        //UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
        if UIApplication.sharedApplication().applicationState == .Active{
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                UIAlertView.init(title: "Service Monitor", message: alertMessage, delegate: nil, cancelButtonTitle: "OK").show()
            })
            
        }
        else{
            UIApplication.sharedApplication().presentLocalNotificationNow(localNotification)
        }
    }
    
    func application(application: UIApplication, performFetchWithCompletionHandler complettionHandler: (UIBackgroundFetchResult) -> Void) {
        performServiceMonitorRoutine(complettionHandler)
    }

    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        // Override point for customization after application launch.
        application.registerUserNotificationSettings(UIUserNotificationSettings(forTypes: [UIUserNotificationType.Alert, .Badge, .Sound], categories: nil))
        performServiceMonitorRoutine { (fetchResult) -> Void in
            
        }
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        
    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }


}

