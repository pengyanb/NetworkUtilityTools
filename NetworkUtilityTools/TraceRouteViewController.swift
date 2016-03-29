//
//  TraceRouteViewController.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 26/12/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import UIKit

class TraceRouteViewController: UIViewController, UITextFieldDelegate {
    
    //MARK: -Variables
    private var traceRouteModel:TraceRoute = {return TraceRoute.init()}()
    
    //MARK: -Outlets
    @IBOutlet weak var traceRouteConsoleTextView: UITextView!
    
    @IBOutlet weak var traceRouteAddressTextField: UITextField!
    
    @IBOutlet weak var traceRouteButton: UIButton!
    
    @IBOutlet weak var traceRouteAddressViewBottomLayoutConstraint: NSLayoutConstraint!
    
    //MARK: - view life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        traceRouteAddressTextField.delegate = self
    }

    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        registerNotificationsAboutModelChanges()
        if let traceRouteUserDefault = NSUserDefaults.standardUserDefaults().objectForKey(CONSTANTS.NSUSER_DEFAULT_TRACE_ROUTE_KEY.getAssociatedString()) as? String{
            traceRouteAddressTextField.text = traceRouteUserDefault
        }
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        deregisterNotificationsAboutModelChanges()
    }
    
    //MARK: -Notifications
    func registerNotificationsAboutModelChanges(){
        let notiCenter = NSNotificationCenter.defaultCenter()
        notiCenter.addObserver(self, selector: Selector("handleModelChanges:"), name: CONSTANTS.NOTI_TRACE_ROUTE_MODEL_CHANGED.getAssociatedString(), object: nil)
        notiCenter.addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        notiCenter.addObserver(self, selector: Selector("keyboardWillBeHidden:"), name: UIKeyboardWillHideNotification, object: nil)
    }
    func deregisterNotificationsAboutModelChanges(){
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func handleModelChanges(notification:NSNotification)
    {
        if let userInfo = notification.userInfo{
            if let traceRouteInfo = userInfo["TraceRouteInfo"] as? String{
                traceRouteConsoleTextView.text = traceRouteConsoleTextView.text! + traceRouteInfo
                if (traceRouteInfo as NSString).rangeOfString("Trace complete").location != NSNotFound{
                    enableUserInteraction()
                }
                NSTimer.scheduledTimerWithTimeInterval(0.2, target: NSBlockOperation(block: {[unowned self] () -> Void in
                    self.traceRouteConsoleTextView.scrollRangeToVisible(NSMakeRange((self.traceRouteConsoleTextView.text! as NSString).length, 0))
                }), selector: "main", userInfo: nil, repeats: false)
            }
        }
    }

    //MARK: -keyboard Related
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        return true
    }
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if let traceRouteAddress = traceRouteAddressTextField.text{
            NSUserDefaults.standardUserDefaults().setObject(traceRouteAddress, forKey: CONSTANTS.NSUSER_DEFAULT_TRACE_ROUTE_KEY.getAssociatedString())
            traceRouteModel.startTraceRouteWithAddress(traceRouteAddress)
            disableUserInteraction()
        }
        self.view.endEditing(true)
        return false
    }
    func keyboardWillShow(notification:NSNotification){
        if let userInfo = notification.userInfo{
            if let keyboardFrameView = userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue{
                let keyboardHeight = keyboardFrameView.CGRectValue().size.height
                UIView.animateWithDuration(0.1, animations: {[unowned self] () -> Void in
                    self.traceRouteAddressViewBottomLayoutConstraint.constant = keyboardHeight
                })
            }
        }
    }
    func keyboardWillBeHidden(notification:NSNotification)
    {
        UIView.animateWithDuration(0.1) {[unowned self] () -> Void in
            self.traceRouteAddressViewBottomLayoutConstraint.constant = 0
        }
    }
    
    //MARK: -private func
    private func disableUserInteraction(){
        traceRouteAddressTextField.enabled = false
        traceRouteAddressTextField.alpha = 0.6
        traceRouteButton.enabled = false
        traceRouteButton.alpha = 0.6
    }
    private func enableUserInteraction(){
        traceRouteAddressTextField.enabled = true
        traceRouteAddressTextField.alpha = 1.0
        traceRouteButton.enabled = true
        traceRouteButton.alpha = 1.0
    }
    
    //MARK: -Target Action
    @IBAction func traceRouteButtonPressed(sender: UIButton) {
        self.view.endEditing(true)
        if let traceRouteAddress = traceRouteAddressTextField.text{
            NSUserDefaults.standardUserDefaults().setObject(traceRouteAddress, forKey: CONSTANTS.NSUSER_DEFAULT_TRACE_ROUTE_KEY.getAssociatedString())
            traceRouteConsoleTextView.text = ""
            traceRouteModel.startTraceRouteWithAddress(traceRouteAddress)
            disableUserInteraction()
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
