//
//  SideMenuPanelViewController.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 14/12/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import UIKit

class SideMenuPanelViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate{

    //MARK: -Variables and outlets
 
    @IBOutlet weak var serverPortTextField: UITextField!
    @IBOutlet weak var encodePicker: UIPickerView!
    
    @IBOutlet weak var serverBehaviorPicker: UIPickerView!
    @IBOutlet weak var startButton: UIButton!
    
    var tcpServerUserDefault = [String:AnyObject]()
    var tcpServer:TcpServer?
    
    var modelPassingDelegate : ModelPassingDelegate?
    
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
    private var ServerBehavior = [CONSTANTS.SERVER_BEHAVIOR_ECHO, CONSTANTS.SERVER_BEHAVIOR_MANUAL]
    private var encodingInfoSelectedIndex = 0
    private var serverBehaviorSelectedIndex = 0
    
    
    //MARK: -View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        serverPortTextField.delegate = self
        encodePicker.dataSource = self
        encodePicker.delegate = self
        encodePicker.selectRow(encodingInfoSelectedIndex, inComponent: 0, animated: false)
        serverBehaviorPicker.dataSource = self
        serverBehaviorPicker.delegate = self
        serverBehaviorPicker.selectRow(serverBehaviorSelectedIndex, inComponent: 0, animated: false)
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let serverUserDefault = NSUserDefaults.standardUserDefaults().objectForKey(CONSTANTS.NSUSER_DEFAULT_TCP_SERVER_KEY.getAssociatedString()) as? [String:AnyObject]{
            self.tcpServerUserDefault = serverUserDefault
            if let portNum = serverUserDefault["ServerPort"] as? Int{
                serverPortTextField.text = "\(portNum)"
            }
            if let encodeIndex = serverUserDefault["EncodeIndex"] as? Int{
                encodingInfoSelectedIndex = encodeIndex
                encodePicker.selectRow(encodingInfoSelectedIndex, inComponent: 0, animated: false)
            }
            if let serverBehaviorIndex = serverUserDefault["BehaviorIndex"] as? Int{
                serverBehaviorSelectedIndex = serverBehaviorIndex
                serverBehaviorPicker.selectRow(serverBehaviorSelectedIndex, inComponent: 0, animated: false)
            }
        }
        //!! todo
    }
    
    //MARK: -Target Actions
    
    @IBAction func startPressed(sender: UIButton) {
        if tcpServer == nil{
            if let portNumber = UInt16.init(serverPortTextField.text!){
                tcpServer = TcpServer.init(portNum: portNumber)
            }
        }
        if let server = tcpServer{
            if server.isListening{
                server.destroyTcpServer()
                serverPortTextField.enabled = true
                serverPortTextField.alpha = 1.0
                serverBehaviorPicker.userInteractionEnabled = true
                serverBehaviorPicker.alpha = 1.0
                startButton.setTitle("Start", forState: UIControlState.Normal)
            }
            else{
                serverPortTextField.enabled = false
                serverPortTextField.alpha = 0.6
                serverBehaviorPicker.userInteractionEnabled = false
                serverBehaviorPicker.alpha = 0.6
                startButton.setTitle("Stop", forState: UIControlState.Normal)
                server.dataEncoding = EncodingInfo[encodingInfoSelectedIndex]
                server.serverBehavior = ServerBehavior[serverBehaviorSelectedIndex]
                tcpServerUserDefault["EncodeIndex"] = encodingInfoSelectedIndex
                tcpServerUserDefault["BehaviorIndex"] = serverBehaviorSelectedIndex
                if let portNumber = UInt16.init(serverPortTextField.text!)
                {
                    server.serverPortNum = portNumber
                    tcpServerUserDefault["ServerPort"] = Int.init(portNumber)
                }
                server.startServer()
                if let passback = modelPassingDelegate{
                    passback.passbackModel(tcpServer)
                }
                NSUserDefaults.standardUserDefaults().setObject(tcpServerUserDefault, forKey: CONSTANTS.NSUSER_DEFAULT_TCP_SERVER_KEY.getAssociatedString())
                
            }
        }
        else
        {
            UIAlertView.init(title: "Error", message: "Unable to initiate TCP Server", delegate: nil, cancelButtonTitle: "OK").show()
        }
        
    }
    
    //MARK: -PickerView DataSource & Delegate
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        if pickerView.tag == 1{
            return EncodingInfo.count
        }
        else if pickerView.tag == 2{
            return ServerBehavior.count
        }
        else
        {
            return 0
        }
    }
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        var labelView:UILabel?
        if let reuseableLabel = view as? UILabel{
            labelView = reuseableLabel
        }
        else
        {
            labelView = UILabel()
        }
        if pickerView.tag == 1{
            labelView?.textColor = UIColor.blackColor()
            labelView?.text = EncodingInfo[row].getAssociatedString()
            labelView?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
            labelView?.textAlignment = NSTextAlignment.Center
        }
        else if pickerView.tag == 2{
            labelView?.textColor = UIColor.blackColor()
            labelView?.text = ServerBehavior[row].getAssociatedString()
            labelView?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
            labelView?.textAlignment = NSTextAlignment.Center
        }
        return labelView!
    }
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if pickerView.tag == 1{
            encodingInfoSelectedIndex = row
        }
        else if pickerView.tag == 2{
            serverBehaviorSelectedIndex = row
        }
        //!! todo
    }
    
    //MARK: -TextView Delegate
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        return true
    }
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return true
    }
}












