//
//  TcpServerViewController.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 14/12/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import UIKit

class TcpServerViewController: UIViewController, UIDynamicAnimatorDelegate, UITextFieldDelegate, ModelPassingDelegate {
    
    //MARK: -Outlets
    @IBOutlet weak var sideMenuPanelContainer: SideMenuPanelContainerView!
    @IBOutlet weak var sideMenuPanelContainerWidthConstraint: NSLayoutConstraint!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var messageToSentTextField: UITextField!
    @IBOutlet weak var sendMessageViewBottomConstrain: NSLayoutConstraint!
    
    
    //MARK: -Variables
    var sideMenuPanelViewController : SideMenuPanelViewController?
    var sideMenyuPanelCollapsed = false
    var tcpServer : TcpServer?

    lazy var animator : UIDynamicAnimator = {
        let lazilyCreatedDynamicAnimator = UIDynamicAnimator(referenceView: self.scrollView)
        lazilyCreatedDynamicAnimator.delegate = self
        return lazilyCreatedDynamicAnimator
    }()
    
    lazy var tcpClientMessageBlockBehavior : TcpClientMessageBlockBehavior = {
        [unowned self] in
        let blockBehavior  = TcpClientMessageBlockBehavior()
        self.outterFrame = CGRect(origin: self.scrollView.bounds.origin, size: self.scrollView.contentSize)
        //print("[OutterFrame]: \(self.outterFrame)")
        let path = UIBezierPath.init(rect: self.outterFrame)
        blockBehavior.addBarrier(path, named: "OutterFrame")
        self.scrollView.contentOffset = CGPointZero
        return blockBehavior
    }()
    
    private var childViews = [TcpClientMessageBlockView]()
    private var viewsWithDynamicBehavior = [TcpClientMessageBlockView]()
    private var outterFrame = CGRect.init()
    
    //MARK: -View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        messageToSentTextField.delegate = self
        scrollView.contentSize = self.view.bounds.size
        animator.addBehavior(tcpClientMessageBlockBehavior)
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        registerNotificationsAboutModelChanges()
        UIDevice.currentDevice().setValue(UIInterfaceOrientation.Portrait.rawValue, forKey: "orientation")
        if tcpServer == nil{
            messageToSentTextField.enabled = false
            messageToSentTextField.alpha = 0.6
            showSideMenuPanel()
        }
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        deregisterNotificationsAboutModelChanges()
        if let server = tcpServer{
            server.destroyTcpServer()
        }
    }

    //MARK: -UI Orientation
    override func shouldAutorotate() -> Bool {
        return false
    }
    override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
        return UIInterfaceOrientationMask.Portrait
    }
    
    //MARK: -DynamicAnimator Delegate
    func dynamicAnimatorDidPause(animator: UIDynamicAnimator) {
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
        let notiCenter = NSNotificationCenter.defaultCenter()
        notiCenter.addObserver(self, selector: Selector("handleModelChanges:"), name: CONSTANTS.NOTI_TCP_SERVER_INFO.getAssociatedString(), object: nil)
        notiCenter.addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        notiCenter.addObserver(self, selector: Selector("keyboardWillBeHidden:"), name: UIKeyboardWillHideNotification, object: nil)
    }
    func deregisterNotificationsAboutModelChanges(){
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    func handleModelChanges(notifcation:NSNotification){
        //print("[handleModelChanges]")
        if let userInfo = notifcation.userInfo{
            if let type = userInfo["ChangeType"] as? String{
                dispatch_async(dispatch_get_main_queue(), {[unowned self] () -> Void in
                    switch type{
                        case "update":
                            self.updateChildViews()
                        case "connected":
                            //!! todo
                            break
                        case "disconnected":
                            //!! todo
                            break
                    default: break;
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
        if let _ = messageToSentTextField.text{
            //!! todo
        }
        self.view.endEditing(true)
        return false
    }
    func keyboardWillShow(notification:NSNotification){
        if let userInfo = notification.userInfo{
            if let keyboardFrameValue = userInfo[UIKeyboardFrameBeginUserInfoKey] as? NSValue{
                let keyboardHeight = keyboardFrameValue.CGRectValue().size.height
                UIView.animateWithDuration(0.1, animations: {[unowned self] ()->Void in
                    self.sendMessageViewBottomConstrain.constant = keyboardHeight
                })
            }
        }
    }
    func keyboardWillBeHidden(notification:NSNotification){
        UIView.animateWithDuration(0.1) {[unowned self] () -> Void in
            self.sendMessageViewBottomConstrain.constant = 0
        }
    }
    
    //MARK: -target actions
    @IBAction func optionButtonPressed(sender: UIBarButtonItem) {
        if sideMenyuPanelCollapsed == true{
            showSideMenuPanel()
        }
        else
        {
            hideSideMenuPanel()
        }
    }
    
    //MARK: -private methods
    private func showSideMenuPanel(){
        self.sideMenuPanelContainerWidthConstraint.constant = 250
        sideMenyuPanelCollapsed = false
        if let sideMenuPanelVC = sideMenuPanelViewController{
            sideMenuPanelVC.tcpServer = self.tcpServer
        }
        UIView.animateWithDuration(1.0, animations: {[unowned self] in
            self.view.layoutIfNeeded()
            })
    }
    private func hideSideMenuPanel(){
        self.sideMenuPanelContainerWidthConstraint.constant = 0
        sideMenyuPanelCollapsed = true
        UIView.animateWithDuration(1.0, animations: {[unowned self] in
            self.view.layoutIfNeeded()
            })
    }
    private func updateChildViews(){
        dispatch_async(dispatch_get_main_queue()) { [unowned self] () -> Void in
            if let server = self.tcpServer{
                objc_sync_enter(server.sync_locker)
                let viewCount = self.childViews.count
                let infoCount = server.messageInfos.count
                if viewCount < infoCount{
                    for var i = 0 ; i < (infoCount - viewCount); i++
                    {
                        let index = viewCount + i
                        let messageInfo = server.messageInfos[index]
                        //print("[Controller \(index)] - \(messageInfo)")
                        self.createTcpClientMessageBlockView(messageInfo)
                    }
                }
                objc_sync_exit(server.sync_locker)
                
            }
        }
    }
    private func createTcpClientMessageBlockView(messageInfo:TcpServerMessageInfo){
        //print("[createTcpClientMessageBlockView]")
        let frame = CGRect(origin: CGPoint(x: scrollView.bounds.origin.x, y: scrollView.contentSize.height - 200), size: CGSize(width: scrollView.contentSize.width, height: 100))
        let tcpClientMessageBlockView = TcpClientMessageBlockView(frame: frame)
        
        //tcpClientMessageBlockView.imageName = tcpClientMessageBlockView.isleftAligned ? "Client" : "Server"
        switch messageInfo.type!{
        case TcpServerMessageInfo.MESSAGE_TYPE.STATUS:
            tcpClientMessageBlockView.isleftAligned = false
            tcpClientMessageBlockView.isRightAligned = false
            tcpClientMessageBlockView.imageName = nil
            tcpClientMessageBlockView.message = messageInfo.message
            //print("tcpClientMessage Status: \(tcpClientMessageBlockView.message)")
        case TcpServerMessageInfo.MESSAGE_TYPE.READ:
            tcpClientMessageBlockView.isleftAligned = true
            tcpClientMessageBlockView.isRightAligned = false
            tcpClientMessageBlockView.imageName = "Client"
            tcpClientMessageBlockView.message = String.init(data:messageInfo.data!, encoding:(tcpServer?.dataEncoding.getAssociatedUInt())!)
            //print("tcpClientMessage Read: \(tcpClientMessageBlockView.message)")
        case TcpServerMessageInfo.MESSAGE_TYPE.WRITE:
            tcpClientMessageBlockView.isleftAligned = false
            tcpClientMessageBlockView.isRightAligned = true
            tcpClientMessageBlockView.imageName = "Server"
            tcpClientMessageBlockView.message = messageInfo.message
            //print("tcpClientMessage Write: \(tcpClientMessageBlockView.message)")
        }
        self.scrollView.contentSize.height = self.scrollView.contentSize.height + tcpClientMessageBlockView.frame.size.height
        outterFrame.size.height = outterFrame.size.height + tcpClientMessageBlockView.frame.size.height
        let path = UIBezierPath.init(rect: outterFrame)
        self.animator.removeBehavior(self.tcpClientMessageBlockBehavior)
        self.tcpClientMessageBlockBehavior.addBarrier(path, named: "OutterFrame")
        self.animator.addBehavior(self.tcpClientMessageBlockBehavior)
        self.tcpClientMessageBlockBehavior.addMessageBlock(tcpClientMessageBlockView)
        self.childViews.append(tcpClientMessageBlockView)
        self.viewsWithDynamicBehavior.append(tcpClientMessageBlockView)
    }
    
    //MARK: Model Passinf delegate method
    func passbackModel(model: AnyObject?) {
        //print("tcpServer passed back")
        hideSideMenuPanel()
        if let passbackServer = model as? TcpServer{
            tcpServer = passbackServer
            updateChildViews()
        }
    }
   
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier{
            if identifier == CONSTANTS.SEGUE_TCP_SERVER_OPTIONS.getAssociatedString(){
                if let destViewController = segue.destinationViewController as? SideMenuPanelViewController{
                    sideMenuPanelViewController = destViewController
                    sideMenuPanelViewController?.modelPassingDelegate = self
                    sideMenuPanelViewController?.tcpServer = self.tcpServer
                    //print("[prepareForSegue found sideMenuPanelViewController]")
                }
            }
        }
    }
}





























