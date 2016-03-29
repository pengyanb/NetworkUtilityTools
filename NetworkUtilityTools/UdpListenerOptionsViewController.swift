//
//  ViewController.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 28/10/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import UIKit

class UdpListenerOptionsViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {

    // MARK: - Variables and outlets
    var udpListenerUserDefault = [String:AnyObject]()
    override var preferredContentSize:CGSize{
        set{
            super.preferredContentSize = newValue
        }
        get{
            if let optionView = self.view as? UdpListenerOptionsView {
                if presentingViewController != nil{
                      return optionView.sizeThatFits(presentingViewController!.view.bounds.size)
                }
            }
            return super.preferredContentSize
        }
    }
    @IBOutlet weak var startButton: UIButton!
    @IBOutlet weak var portNumberTextField: UITextField!
    @IBOutlet weak var decodePicker: UIPickerView!
    
    var udpListener : UdpListener?
    
    var passbackUdpListenerModelDelegate : UdpListenerModelPassingDelegate?

    private var EncodingInfo = [
                                CONSTANTS.ENCODING_RAW_DATA,
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
    
    // MARK: - ViewController lifeCycle
    override func viewDidLoad() {
        super.viewDidLoad()
        decodePicker.dataSource = self
        decodePicker.delegate = self
        decodePicker.selectRow(encodingInfoSelectedIndex, inComponent: 0, animated: false)
        portNumberTextField.delegate = self
        
        let doneToolbar : UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.mainScreen().applicationFrame.size.width, height: 50))
        doneToolbar.barStyle = UIBarStyle.Default
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: Selector("inputDoneButtonAction"))
        doneToolbar.items = [flexSpace, doneButton]
        doneToolbar.sizeToFit()
        portNumberTextField.inputAccessoryView = doneToolbar
    }
    
    func inputDoneButtonAction(){
        portNumberTextField.resignFirstResponder()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.popoverPresentationController?.backgroundColor = UIColor.darkGrayColor()
        if let udpListenerUserDefault = NSUserDefaults.standardUserDefaults().objectForKey(CONSTANTS.NSUSER_DEFAULT_UDP_LISTENER_KEY.getAssociatedString()) as? [String:AnyObject]
        {
            self.udpListenerUserDefault = udpListenerUserDefault
            if let portNum = udpListenerUserDefault["PortNumber"] as? Int{
                portNumberTextField.text = "\(portNum)"
            }
            if let encodeIndex = udpListenerUserDefault["EncodeIndex"] as? Int{
                encodingInfoSelectedIndex = encodeIndex
                decodePicker.selectRow(encodingInfoSelectedIndex, inComponent: 0, animated: false)
            }
        }
        if let listener = udpListener{
            portNumberTextField.text = "\(listener.getUdpPortNum())"
            for (index, encoding) in EncodingInfo.enumerate() {
                if encoding.getAssociatedUInt() == listener.getDataEncoding().getAssociatedUInt(){
                    //print("Found index: \(index)")
                    decodePicker.selectRow(index, inComponent: 0, animated: false)
                }
            }
            if listener.isRunning{
                portNumberTextField.enabled = false
                portNumberTextField.alpha = 0.6
                startButton.setTitle("Stop", forState: UIControlState.Normal)
            }
            else
            {
                portNumberTextField.enabled = true
                portNumberTextField.alpha = 1.0
                startButton.setTitle("Start", forState: UIControlState.Normal)
            }
        }
        else
        {
            portNumberTextField.enabled = true
            portNumberTextField.alpha = 1.0
            startButton.setTitle("Start", forState: UIControlState.Normal)
        }
    }
    
    // MARK: - Target Actions
    @IBAction func startButtonPressed() {
        if udpListener == nil{
            if let portNumber = UInt16.init(self.portNumberTextField.text!){
                udpListener = UdpListener.init(portNum: portNumber)
            }
           
        }
        if let listener = udpListener{
            if listener.isRunning{
                listener.stopReceive()
                portNumberTextField.enabled = true
                portNumberTextField.alpha = 1.0
                startButton.setTitle("Start", forState: UIControlState.Normal)
            }
            else
            {
                portNumberTextField.enabled = false
                portNumberTextField.alpha = 0.6
                startButton.setTitle("Stop", forState: UIControlState.Normal)
                listener.setDataEncoding(EncodingInfo[encodingInfoSelectedIndex])
                listener.startReceive()
                if let passback = passbackUdpListenerModelDelegate{
                    //print("passbackUdpListenerModelDelegate is not nil")
                    passback.passbackUdpListenerModel(listener)
                }
                else
                {
                    print("passbackUdpListenerModelDelegate is nil")
                }
                if let portNumber = Int(self.portNumberTextField.text!)
                {
                    udpListenerUserDefault["PortNumber"] = portNumber
                }
                udpListenerUserDefault["EncodeIndex"] = encodingInfoSelectedIndex
                NSUserDefaults.standardUserDefaults().setObject(udpListenerUserDefault, forKey: CONSTANTS.NSUSER_DEFAULT_UDP_LISTENER_KEY.getAssociatedString())
                self.dismissViewControllerAnimated(true, completion: nil)
            }
            
        }
        else
        {
            UIAlertView.init(title: "Error", message:  "Unable to initiate UDP Listener", delegate: nil, cancelButtonTitle: "OK").show()
        }
    }
    
    // MARK: -Datasource & Delegate Method
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        textField.resignFirstResponder()
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
        else
        {
            labelView = UILabel()
        }
        labelView?.textColor = UIColor.blackColor()
        labelView?.text = EncodingInfo[row].getAssociatedString()
        labelView?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        labelView?.textAlignment = NSTextAlignment.Center
        //print("Label text: \(labelView?.text)")
        return labelView!
    }
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        encodingInfoSelectedIndex = row
        if let listener = udpListener{
            udpListenerUserDefault["EncodeIndex"] = encodingInfoSelectedIndex
            NSUserDefaults.standardUserDefaults().setObject(udpListenerUserDefault, forKey: CONSTANTS.NSUSER_DEFAULT_UDP_LISTENER_KEY.getAssociatedString())
            listener.setDataEncoding(EncodingInfo[encodingInfoSelectedIndex])
        }
    }
}

protocol UdpListenerModelPassingDelegate
{
    func passbackUdpListenerModel(listener:UdpListener?)
}
