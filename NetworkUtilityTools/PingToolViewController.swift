//
//  PingToolViewController.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 26/12/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import UIKit

class PingToolViewController: UIViewController, UITextFieldDelegate {

    //MARK: - Variables
    private var pingTool:PingTool = {return PingTool.init()}()
    
    //MARK: - Outlets
    
    @IBOutlet weak var pingConsoleTextView: UITextView!

    @IBOutlet weak var pingAddressTextField: UITextField!
    
    @IBOutlet weak var pingAddressViewBottomLayoutConstraint: NSLayoutConstraint!
    
    
    //MARK; -view lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        pingAddressTextField.delegate = self
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        registerNoficationsAboutModelChanges()
        if let pingToolUserDefault = NSUserDefaults.standardUserDefaults().objectForKey(CONSTANTS.NSUSER_DEFAULT_PING_TOOL_KEY.getAssociatedString()) as? String{
            pingAddressTextField.text = pingToolUserDefault
        }
        
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        deregisterNotificationsAboutModelChanges()
    }
    
    //MARK: -Notifications
    func registerNoficationsAboutModelChanges(){
        let notiCenter = NSNotificationCenter.defaultCenter()
        notiCenter.addObserver(self, selector: Selector("handleModelChanges:"), name: CONSTANTS.NOTI_PING_MODEL_CHANGED.getAssociatedString(), object: nil)
        notiCenter.addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        notiCenter.addObserver(self, selector: Selector("keyboardWillBeHidden:"), name: UIKeyboardWillHideNotification, object: nil)
    }
    func deregisterNotificationsAboutModelChanges(){
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func handleModelChanges(notification:NSNotification)
    {
        if let userInfo = notification.userInfo{
            if let pingInfo = userInfo["PingInfo"] as? String{
                //print(pingInfo)
                pingConsoleTextView.text = pingConsoleTextView.text! + pingInfo
                NSTimer.scheduledTimerWithTimeInterval(0.2, target: NSBlockOperation(block: { [unowned self] () -> Void in
                    self.pingConsoleTextView.scrollRangeToVisible(NSMakeRange((self.pingConsoleTextView.text! as NSString).length, 0))
                }) , selector: "main", userInfo: nil, repeats: false)
            }
        }
    }
    
    //MARK: -Target Action
    @IBAction func pingButtonClicked(sender: UIButton) {
        self.view.endEditing(true)
        if let pingAddress = pingAddressTextField.text{
            NSUserDefaults.standardUserDefaults().setObject(pingAddress, forKey: CONSTANTS.NSUSER_DEFAULT_PING_TOOL_KEY.getAssociatedString())
            pingConsoleTextView.text = ""
            pingTool.startPingWithAddress(pingAddress, withNumberOfAttempt: 4)
        }
    }
    
    //MARK: -keyboard related
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        return true
    }
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let pingAddress = pingAddressTextField.text{
            NSUserDefaults.standardUserDefaults().setObject(pingAddress, forKey: CONSTANTS.NSUSER_DEFAULT_PING_TOOL_KEY.getAssociatedString())
            pingTool.startPingWithAddress(pingAddress, withNumberOfAttempt: 4)
        }
        self.view.endEditing(true)
        return false
    }
    func keyboardWillShow(notification:NSNotification)
    {
        if let userInfo = notification.userInfo{
            if let keyboardFrameValue = userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue{
                let keyboardHeight = keyboardFrameValue.CGRectValue().size.height
                UIView.animateWithDuration(0.1, animations: { [unowned self] () -> Void in
                    self.pingAddressViewBottomLayoutConstraint.constant = keyboardHeight
                })
            }
        }
    }
    func keyboardWillBeHidden(notification:NSNotification){
        UIView.animateWithDuration(0.1) { [unowned self] () -> Void in
            self.pingAddressViewBottomLayoutConstraint.constant = 0
        }
    }
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
