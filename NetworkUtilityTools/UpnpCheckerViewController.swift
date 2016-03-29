//
//  UpnpCheckerViewController.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 2/01/16.
//  Copyright © 2016 Yanbing Peng. All rights reserved.
//

import UIKit

class UpnpCheckerViewController: UIViewController, UITextFieldDelegate {

    //MARK: -variables
    private var upnpChecker:UpnpChecker? = {
        return UpnpChecker.init()
    }()
    
    //MARK: -Outlets
    @IBOutlet weak var upnpCheckerConsoleTextView: UITextView!
    
    @IBOutlet weak var upnpCheckerPortTextField: UITextField!
    
    @IBOutlet weak var upnpCheckButton: UIButton!
    
    @IBOutlet weak var upnpCheckerPortViewBottomLayoutConstraint: NSLayoutConstraint!
    
    //MARK: -view Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        upnpCheckerPortTextField.delegate = self
        // Do any additional setup after loading the view.
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        registerForNotificationAboutModelChanges()
        if NSUserDefaults.standardUserDefaults().objectForKey(CONSTANTS.NSUSER_DEFAULT_UPNP_CHECKER_KEY.getAssociatedString()) != nil {
            let upnpCheckerDefaultPort = NSUserDefaults.standardUserDefaults().integerForKey(CONSTANTS.NSUSER_DEFAULT_UPNP_CHECKER_KEY.getAssociatedString())
            upnpCheckerPortTextField.text = "\(upnpCheckerDefaultPort)"
        }
        
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        deregisterNotificationsAboutModelChanges()
    }
    
    //MARK: -Notifications
    func registerForNotificationAboutModelChanges(){
        let notiCenter = NSNotificationCenter.defaultCenter()
        notiCenter.addObserver(self, selector: Selector("handleModelChanges:")
        , name: CONSTANTS.NOTI_UPNP_CHECKER_MODEL_CHANGED.getAssociatedString(), object: nil)
        notiCenter.addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        notiCenter.addObserver(self, selector: Selector("keyboardWillBeHidden:"), name: UIKeyboardWillHideNotification, object: nil)
    }
    func deregisterNotificationsAboutModelChanges(){
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func handleModelChanges(notification:NSNotification){
        if upnpChecker?.needRemovePort == true{
            upnpCheckButton.setTitle("Remove", forState: UIControlState.Normal)
        }
        else if upnpChecker?.needRemovePort == false{
            upnpCheckButton.setTitle("Forward", forState: UIControlState.Normal)
        }
        else{
            upnpCheckButton.setTitle("Forward", forState: UIControlState.Normal)
        }
        
        if let userInfo = notification.userInfo{
            if let statusInfo = userInfo["status"] as? String{
                //print("\(statusInfo)")
                dispatch_async(dispatch_get_main_queue(), {[unowned self] () -> Void in
                    self.upnpCheckerConsoleTextView.text = self.upnpCheckerConsoleTextView.text! + statusInfo
                    NSTimer.scheduledTimerWithTimeInterval(0.2, target: NSBlockOperation(block: {[unowned self] () -> Void in
                        self.upnpCheckerConsoleTextView.scrollRangeToVisible(NSMakeRange((self.upnpCheckerConsoleTextView.text! as NSString).length, 0))
                        }), selector: "main", userInfo: nil, repeats: false)
                })
                
            }
            if let statusInfo = userInfo["result"] as? String{
                dispatch_async(dispatch_get_main_queue(), {[unowned self] () -> Void in
                    self.enableUserInteraction()
                    if (statusInfo as NSString).rangeOfString("Success:").location != NSNotFound{
                        UIAlertView.init(title: "Success", message: statusInfo, delegate: nil, cancelButtonTitle: "OK").show()
                    }
                    else if (statusInfo as NSString).rangeOfString("Error:").location != NSNotFound{
                        UIAlertView.init(title: "Error", message: statusInfo, delegate: nil, cancelButtonTitle: "OK").show()
                    }
                })
            }
        }
    }
 
    //MARK: -keyboard Related
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        return true
    }
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let portString = upnpCheckerPortTextField.text{
            if let portToCheck = UInt16.init(portString){
                NSUserDefaults.standardUserDefaults().setInteger(Int.init(portToCheck), forKey: CONSTANTS.NSUSER_DEFAULT_UPNP_CHECKER_KEY.getAssociatedString())
                upnpChecker?.upnpCheckerProcedureIndex = 0
                upnpCheckerConsoleTextView.text = ""
                upnpChecker?.startUpnpCheck(portToCheck)
                disableUserInteraction()
            }
        }
        self.view.endEditing(true)
        return false
    }
    func keyboardWillShow(notification:NSNotification){
        if let userInfo = notification.userInfo{
            if let keyboardFrameView = userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue{
                let keyboardHeight = keyboardFrameView.CGRectValue().size.height
                UIView.animateWithDuration(0.1, animations: {[unowned self] () -> Void in
                    self.upnpCheckerPortViewBottomLayoutConstraint.constant = keyboardHeight
                })
            }
        }
    }
    func keyboardWillBeHidden(notification:NSNotification){
        UIView.animateWithDuration(0.1) {[unowned self] () -> Void in
            self.upnpCheckerPortViewBottomLayoutConstraint.constant = 0
        }
    }
    
    //MARK: -private func
    private func disableUserInteraction(){
        upnpCheckerPortTextField.enabled = false
        upnpCheckerPortTextField.alpha = 0.6
        upnpCheckButton.enabled = false
        upnpCheckButton.alpha = 0.6
    }
    private func enableUserInteraction(){
        upnpCheckerPortTextField.enabled = true
        upnpCheckerPortTextField.alpha = 1.0
        upnpCheckButton.enabled = true
        upnpCheckButton.alpha = 1.0
    }
    
    //MARK: -Target Action
    @IBAction func checkButtonPressed(sender: UIButton) {
        self.view.endEditing(true)
        if upnpCheckButton.titleForState(UIControlState.Normal) == "Forward"
        {
            if let portString = upnpCheckerPortTextField.text{
                if let portToCheck = UInt16.init(portString){
                    NSUserDefaults.standardUserDefaults().setInteger(Int.init(portToCheck), forKey: CONSTANTS.NSUSER_DEFAULT_UPNP_CHECKER_KEY.getAssociatedString())
                    upnpChecker?.upnpCheckerProcedureIndex = 0
                    upnpCheckerConsoleTextView.text = ""
                    upnpChecker?.startUpnpCheck(portToCheck)
                    disableUserInteraction()
                }
            }
        }
        else{
            upnpChecker?.removeForwardedPort()
        }
        
    }

}















