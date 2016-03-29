//
//  TcpClientViewController.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 27/11/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import UIKit

class TcpClientViewController: UIViewController, UIDynamicAnimatorDelegate, TcpClientModelPassingDelegate, UIPopoverPresentationControllerDelegate, UITextFieldDelegate {

    //MARK: -Outlets
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var messageToSendTextField: UITextField!
    
    @IBOutlet weak var sendMessageViewBottomConstrain: NSLayoutConstraint!
    
    //MARK: -Variables
    var tcpClient : TcpClient?
    
    lazy var animator : UIDynamicAnimator = {
        let lazilyCreatedDynamicAnimator = UIDynamicAnimator(referenceView: self.scrollView)
        lazilyCreatedDynamicAnimator.delegate = self
        return lazilyCreatedDynamicAnimator
    }()
    
    lazy var tcpClientMessageBlockBehavior : TcpClientMessageBlockBehavior = { [unowned self] in
        let blockBehavior = TcpClientMessageBlockBehavior()
        self.outterFrame = CGRect(origin: self.scrollView.bounds.origin, size: self.scrollView.contentSize)
        let path = UIBezierPath.init(rect: self.outterFrame)
        blockBehavior.addBarrier(path, named: "OutterFrame")
        return blockBehavior
    }()
    
    private var childViews = [TcpClientMessageBlockView]()
    private var viewsWithDynamicBehavior = [TcpClientMessageBlockView]()
    private var outterFrame = CGRect.init()
    
    //MARK：-View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        messageToSendTextField.delegate = self
        scrollView.contentSize = self.view.bounds.size
        animator.addBehavior(tcpClientMessageBlockBehavior)
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        registerNotificationsAboutModelChanges()
        UIDevice.currentDevice().setValue(UIInterfaceOrientation.Portrait.rawValue, forKey: "orientation")
        if tcpClient == nil{
            //messageToSendTextField.enabled = false
            messageToSendTextField.alpha = 0.6
            performSegueWithIdentifier(CONSTANTS.SEGUE_TCP_CLIENT_OPTIONS.getAssociatedString(), sender: self)
        }
        if var userDefaults = NSUserDefaults.standardUserDefaults().objectForKey(CONSTANTS.NSUSER_DEFAULT_TCP_CLIENT_KEY.getAssociatedString()) as? [String:AnyObject]{
            if let messageToSend = userDefaults["MessageToSend"] as? String{
                messageToSendTextField.text = messageToSend
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        deregisterNotificationsAboutModelChanges()
    }
    
    //MARK: -UI Orientation
    override func shouldAutorotate() -> Bool {
        return false
    }
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
    //MARK: - DynamicAnimator Delegate
    func dynamicAnimatorDidPause(animator: UIDynamicAnimator) {
        print("[dynamicAnimatorDidPause]")
        for viewWithBehavior in viewsWithDynamicBehavior{
            tcpClientMessageBlockBehavior.removeMessageBlock(viewWithBehavior)
        }
        viewsWithDynamicBehavior = [TcpClientMessageBlockView]()
        
        if let lastChildView = childViews.last{
            outterFrame = CGRect.init(
                x: scrollView.bounds.origin.x,
                y: lastChildView.frame.origin.y + lastChildView.frame.size.height,
                width: scrollView.bounds.size.width,
                height: scrollView.contentSize.height - (lastChildView.frame.origin.y + lastChildView.frame.size.height))
        }
    }
    
    //MARK: -Notifications
    func registerNotificationsAboutModelChanges(){
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleModelChanges:"), name: CONSTANTS.NOTI_TCP_CLIENT_INFO.getAssociatedString(), object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillBeHidden:"), name: UIKeyboardWillHideNotification, object: nil)
    }
    func deregisterNotificationsAboutModelChanges(){
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    func handleModelChanges(notification:NSNotification)
    {
        if let userInfo = notification.userInfo
        {
            if let type = userInfo["ChangeType"] as? String
            {
                //print(type)
                dispatch_async(dispatch_get_main_queue()){ [unowned self] in
                    switch type{
                    case "update":
                        self.updateChildViews()
                    case "connected":
                        self.messageToSendTextField.enabled = true
                        self.messageToSendTextField.alpha = 1.0
                    case "disconnected":
                        //self.messageToSendTextField.enabled = false
                        self.messageToSendTextField.alpha = 0.6
                        self.view.endEditing(true)
                    default:break;
                    }
                }
            }
        }
    }
    
    //MARK: -keyboard Related
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        //print("textFieldShouldEncEditing")
        return true
    }
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        //print("textFieldShouldReturn")
        if let message = messageToSendTextField.text{
            if var userDefaults = NSUserDefaults.standardUserDefaults().objectForKey(CONSTANTS.NSUSER_DEFAULT_TCP_CLIENT_KEY.getAssociatedString()) as? [String:AnyObject]{
                userDefaults["MessageToSend"] = message
                NSUserDefaults.standardUserDefaults().setObject(userDefaults, forKey: CONSTANTS.NSUSER_DEFAULT_TCP_CLIENT_KEY.getAssociatedString())
            }
            tcpClient?.writeData(message, withTimeout: 5)
        }
        self.view.endEditing(true)
        return false
    }
    func keyboardWillShow(notification:NSNotification){
        //print("keyboardWillShow")
        if let userInfo = notification.userInfo{
            //print("userInfo: \(userInfo)")
            if let keyboardFrameValue = userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue{
                let keyboardHeight = keyboardFrameValue.CGRectValue().size.height
                //print("keyboard Height: \(keyboardHeight)")
                UIView.animateWithDuration(0.1, animations: { [unowned self] ()->Void  in
                    self.sendMessageViewBottomConstrain.constant = keyboardHeight
                })
            }
        }
    }
    func keyboardWillBeHidden(notification:NSNotification){
        UIView.animateWithDuration(0.1, animations: {[unowned self] ()->Void in
            self.sendMessageViewBottomConstrain.constant = 0
        })
    }
    
    //Mark: -Target Action

    
    //Mark: -private methods
    private func updateChildViews(){
        //print("childView: \(childViews.count)")
        //print("messageInfos: \(tcpClient?.messageInfos.count)")
        dispatch_async(dispatch_get_main_queue()){ [unowned self] in
            if let client = self.tcpClient{
                let viewCount = self.childViews.count
                let infoCount = client.messageInfos.count
                if viewCount < infoCount {
                    for var i = 0 ; i < (infoCount - viewCount); i++
                    {
                        let index = viewCount + i
                        self.createTcpClientMessageBlockView(client.messageInfos[index])
                    }
                }
            }
            
        }
    }
    private func createTcpClientMessageBlockView(messageInfo:TcpClientMessageInfo){
        let frame = CGRect(origin: CGPoint(x: scrollView.bounds.origin.x, y: scrollView.contentSize.height - 200), size: CGSize(width: scrollView.contentSize.width, height: 100))
        let tcpClientMessageBlockView = TcpClientMessageBlockView(frame: frame)
    
        //tcpClientMessageBlockView.imageName = tcpClientMessageBlockView.isleftAligned ? "Server" : "Client"
        switch messageInfo.type!{
        case TcpClientMessageInfo.MESSAGE_TYPE.STATUS:
            tcpClientMessageBlockView.isleftAligned = false
            tcpClientMessageBlockView.isRightAligned = false
            tcpClientMessageBlockView.imageName = nil
            tcpClientMessageBlockView.message = messageInfo.message
        case TcpClientMessageInfo.MESSAGE_TYPE.READ:
            tcpClientMessageBlockView.isleftAligned = true
            tcpClientMessageBlockView.isRightAligned = false
            tcpClientMessageBlockView.imageName = "Server"
            tcpClientMessageBlockView.message = String.init(data: messageInfo.data!, encoding: (tcpClient?.getDataEncoding().getAssociatedUInt())!)
            //print("Read Message: [\(tcpClientMessageBlockView.message)]")
        case TcpClientMessageInfo.MESSAGE_TYPE.WRITE:
            tcpClientMessageBlockView.isleftAligned = false
            tcpClientMessageBlockView.isRightAligned = true
            tcpClientMessageBlockView.imageName = "Client"
            tcpClientMessageBlockView.message = messageInfo.message
        }
        //print(tcpClientMessageBlockView.message);
        //tcpClientMessageBlockView.frame.origin.y = scrollView.contentSize.height -  tcpClientMessageBlockView.frame.size.height
        self.scrollView.contentSize.height = self.scrollView.contentSize.height + tcpClientMessageBlockView.frame.size.height
        outterFrame.size.height = outterFrame.size.height + tcpClientMessageBlockView.frame.size.height
        let path = UIBezierPath.init(rect: outterFrame)
        self.animator.removeBehavior(self.tcpClientMessageBlockBehavior)
        self.tcpClientMessageBlockBehavior.addBarrier(path, named: "OutterFrame")
        self.animator.addBehavior(self.tcpClientMessageBlockBehavior)
        print("tcpClientMessageBlockView: \(tcpClientMessageBlockView.frame)")
        self.tcpClientMessageBlockBehavior.addMessageBlock(tcpClientMessageBlockView)
        self.childViews.append(tcpClientMessageBlockView)
        self.viewsWithDynamicBehavior.append(tcpClientMessageBlockView)
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier{
            switch identifier{
            case CONSTANTS.SEGUE_TCP_CLIENT_OPTIONS.getAssociatedString():
                if let tcpClientOptionsVC = segue.destinationViewController as? TcpClientOptionsViewController{
                    tcpClientOptionsVC.passbackTcpClientModelDelegate = self
                    if let ppc = tcpClientOptionsVC.popoverPresentationController{
                        ppc.delegate = self
                    }
                    if let client = tcpClient{
                        tcpClientOptionsVC.tcpClient = client
                    }
                }
            default:break
            }
        }
    }
    
    func popoverPresentationControllerShouldDismissPopover(popoverPresentationController: UIPopoverPresentationController) -> Bool {
        /*
        if tcpClient == nil{
            return false
        }*/
        return true
    }
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    //MARK: Model Passing delegate method
    func passbackTcpClientModel(client: TcpClient?) {
        if let passbackClient = client{
            tcpClient = passbackClient
            messageToSendTextField.enabled = true
            updateChildViews()
        }
    }
}
