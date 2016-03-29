//
//  UdpBroadcasterViewController.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 26/11/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import UIKit

class UdpBroadcasterViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate, UITextViewDelegate {

    //MARK: -outlets
    var udpBroadcaster : UdpBroadcaster?
    
    @IBOutlet weak var ipAddress: UITextField!
    @IBOutlet weak var portNum: UITextField!
    @IBOutlet weak var encodePicker: UIPickerView!
    @IBOutlet weak var dataTextview: UITextView!
    @IBOutlet weak var logTextView: UITextView!
    
    private var EncodingInfo = [
        CONSTANTS.ENCODING_ISO_Latin1,
        CONSTANTS.ENCODING_ISO_Latin2,
        CONSTANTS.ENCODING_ASCII,
        CONSTANTS.ENCODING_Non_Lossy_ASCII,
        CONSTANTS.ENCODING_UTF8,
        CONSTANTS.ENCODING_UTF16,
        CONSTANTS.ENCODING_UTF16_Little_Endian,
        CONSTANTS.ENCODING_UTF16_Big_Endian,
        CONSTANTS.ENCODING_UTF32,
        CONSTANTS.ENCODING_UTF32_Little_Endian,
        CONSTANTS.ENCODING_UTF32_Big_Endian,
        CONSTANTS.ENCODING_Unicode,
        CONSTANTS.ENCODING_Windows_CP1250,
        CONSTANTS.ENCODING_Windows_CP1251,
        CONSTANTS.ENCODING_Windows_CP1252,
        CONSTANTS.ENCODING_Windows_CP1253,
        CONSTANTS.ENCODING_Windows_CP1254
    ]
    private var encodingInfoSelectedIndex = 0
    
    //MARK: -View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        //let inputAccessoryView = UIView.init(frame: CGRect.init(x: 0, y: 0, width: UIScreen.mainScreen().applicationFrame.size.width, height: 40))
        //inputAccessoryView.backgroundColor = UIColor.blackColor()
        
        ipAddress.delegate = self
        portNum.delegate = self
        encodePicker.dataSource = self
        encodePicker.delegate = self
        dataTextview.delegate = self
        //logTextView.delegate = self
        
        let doneToolbar:UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.mainScreen().applicationFrame.size.width, height: 50))
        doneToolbar.barStyle = UIBarStyle.Default
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: Selector("inputDoneButtonAction"))
        doneToolbar.items = [flexSpace, doneButton]
        doneToolbar.sizeToFit()
        self.ipAddress.inputAccessoryView = doneToolbar
        self.portNum.inputAccessoryView = doneToolbar
        self.dataTextview.inputAccessoryView = doneToolbar
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        registerForNotification()
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillAppear(animated)
        removeSelfFromObservingNotification()
    }
    
    //MARK: Notification handler
    func registerForNotification(){
        let defaultNotificationCenter = NSNotificationCenter.defaultCenter()
        defaultNotificationCenter.addObserver(self, selector: Selector("udpBroadcasterStatusUpdate:"), name: CONSTANTS.NOTI_UDP_BROADCASTER_INFO.getAssociatedString(), object: nil)
        //defaultNotificationCenter.addObserver(self, selector: Selector("keyboardWillShow:"), name: UIKeyboardWillShowNotification, object: nil)
        //defaultNotificationCenter.addObserver(self, selector: Selector("keyboardWillHide:"), name: UIKeyboardWillHideNotification, object: nil)
    }
    func removeSelfFromObservingNotification(){
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    func udpBroadcasterStatusUpdate(notification: NSNotification)
    {
        if let userInfo = notification.userInfo as? Dictionary<String, String>{
            //print("\(userInfo)")
            if let statusUpdate = userInfo["info"]
            {
                dispatch_async(dispatch_get_main_queue()){ [unowned self] in
                    let content = self.logTextView.text! + "\n" + statusUpdate
                    self.logTextView.text = content
                    NSTimer.scheduledTimerWithTimeInterval(
                        0.2,
                        target: NSBlockOperation(block: { [unowned self] in
                            //print("NSTimer timeout")
                            self.logTextView.scrollRangeToVisible(NSMakeRange((self.logTextView.text! as NSString).length, 0))
                        }),
                        selector: "main",
                        userInfo: nil,
                        repeats: false)
                    //self.logTextView.scrollRangeToVisible(NSMakeRange((content as NSString).length, 0))
                    if (statusUpdate as NSString).rangeOfString("UDP Broadcast Sent").location != NSNotFound{
                        UIAlertView.init(title: "Done", message: "UDP Broadcast Sent", delegate: nil, cancelButtonTitle: "OK").show()
                    }
                }
            }
        }
    }
    func keyboardWillShow(notification:NSNotification)
    {
        /*
        if let info = notification.userInfo{
            if let keyboardRect = (info[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.CGRectValue()
            {
                let keyboardHeight = keyboardRect.size.height
                
            }
        }*/
    }
    func keyboardWillHide(notification:NSNotification)
    {
        
    }
    
    //MARK: Target Actions
    
    @IBAction func broadcastPressed(sender: UIButton) {
        //logTextView.text = ""
        if udpBroadcaster == nil{
            udpBroadcaster = UdpBroadcaster.init(portNum: UInt16.init(portNum.text!)!, ipAddress: ipAddress.text!)
        }
        if let broadcaster = udpBroadcaster{
            broadcaster.setDataEncoding(EncodingInfo[encodePicker.selectedRowInComponent(0)])
            broadcaster.setUdpPortNum(UInt16.init(portNum.text!)!, andIPAddress: ipAddress.text!)
            broadcaster.sendBroadcast(dataTextview.text!)
        }
        else
        {
            UIAlertView.init(title: "Error", message:  "Unable to initiate UDP Broadcaster", delegate: nil, cancelButtonTitle: "OK").show()
        }
    }
    
    //MARK: - Datasource & Delegate Method
    func inputDoneButtonAction()
    {
        self.ipAddress.resignFirstResponder()
        self.portNum.resignFirstResponder()
        self.dataTextview.resignFirstResponder()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    func textViewShouldEndEditing(textView: UITextView) -> Bool {
        textView.resignFirstResponder()
        return true
    }
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return EncodingInfo.count
    }
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        var labelView: UILabel? = nil
        if let reusableLabel = view as? UILabel{
            labelView = reusableLabel
        }
        else {
            labelView = UILabel()
        }
        labelView?.textColor = UIColor.blackColor()
        labelView?.text = EncodingInfo[row].getAssociatedString()
        labelView?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        labelView?.textAlignment = NSTextAlignment.Center
        return labelView!
    }
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        encodingInfoSelectedIndex = row
    }
}
