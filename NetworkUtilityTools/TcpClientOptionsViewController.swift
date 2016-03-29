//
//  TcpClientOptionsViewController.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 3/12/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import UIKit

class TcpClientOptionsViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {

    //MARK: -Variables and outlets
    var tcpClientUserDefault = [String:AnyObject]()
    override var preferredContentSize:CGSize{
        set{
            super.preferredContentSize = newValue
        }
        get{
            if let optionView = self.view as? TcpClientOptionsView{
                if presentingViewController != nil{
                    return optionView.sizeThatFits(presentingViewController!.view.bounds.size)
                }
            }
            return super.preferredContentSize
        }
    }
    
    @IBOutlet weak var serverIpAddressTextField: UITextField!
    @IBOutlet weak var serverPortNumberTextField: UITextField!
    @IBOutlet weak var encodePicker: UIPickerView!
    @IBOutlet weak var startButton: UIButton!

    
    var tcpClient : TcpClient?
    
    var passbackTcpClientModelDelegate : TcpClientModelPassingDelegate?
    
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
        serverIpAddressTextField.delegate = self
        serverPortNumberTextField.delegate = self
        encodePicker.dataSource = self
        encodePicker.delegate = self
        encodePicker.selectRow(encodingInfoSelectedIndex, inComponent: 0, animated: false)
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.popoverPresentationController?.backgroundColor = UIColor.darkGrayColor()
        if let clientUserDefault = NSUserDefaults.standardUserDefaults().objectForKey(CONSTANTS.NSUSER_DEFAULT_TCP_CLIENT_KEY.getAssociatedString()) as? [String:AnyObject]
        {
            self.tcpClientUserDefault = clientUserDefault
            if let serverIpAddress = clientUserDefault["ServerIp"] as? String{
                serverIpAddressTextField.text = serverIpAddress
            }
            if let portNum = clientUserDefault["ServerPort"] as? Int{
                serverPortNumberTextField.text = "\(portNum)"
            }
            if let encodeIndex = clientUserDefault["EncodeIndex"] as? Int{
                encodingInfoSelectedIndex = encodeIndex
                encodePicker.selectRow(encodingInfoSelectedIndex, inComponent: 0, animated: false)
            }
            
        }
        if let client = tcpClient{
            if let ipAdr = client.getTcpClientDestIpAddress()
            {
                serverIpAddressTextField.text = ipAdr
            }
            if let portNum = client.getTcpClientDestPortNumber()
            {
            serverPortNumberTextField.text = "\(portNum)"
            }
            for(index, encoding) in EncodingInfo.enumerate(){
                if encoding.getAssociatedUInt() == client.getDataEncoding().getAssociatedUInt(){
                    encodePicker.selectRow(index, inComponent: 0, animated: false)
                }
            }
            if client.isRunning{
                serverIpAddressTextField.enabled = false
                serverIpAddressTextField.alpha = 0.6
                serverPortNumberTextField.enabled = false
                serverPortNumberTextField.alpha = 0.6
                startButton.setTitle("Stop", forState: UIControlState.Normal)
            }
            else
            {
                serverIpAddressTextField.enabled = true
                serverIpAddressTextField.alpha = 1.0
                serverPortNumberTextField.enabled = true
                serverPortNumberTextField.alpha = 1.0
                startButton.setTitle("Start", forState: UIControlState.Normal)
            }
        }
        else
        {
            serverIpAddressTextField.enabled = true
            serverIpAddressTextField.alpha = 1.0
            serverPortNumberTextField.enabled = true
            serverPortNumberTextField.alpha = 1.0
            startButton.setTitle("Start", forState: UIControlState.Normal)
        }
    }
    
    //MARK: -Target Actions
    
    @IBAction func startButtonPressed(sender: UIButton) {
        if tcpClient == nil{
            if let portNumber = UInt16.init(serverPortNumberTextField.text!){
                tcpClient = TcpClient.init(portNum: portNumber, ipAddress: serverIpAddressTextField.text!)
            }
        }
        if let client = tcpClient{
            if client.isRunning{
                client.destroyTcpClient()
                serverIpAddressTextField.enabled = true
                serverIpAddressTextField.alpha = 1.0
                serverPortNumberTextField.enabled = true
                serverPortNumberTextField.alpha = 1.0
                startButton.setTitle("Start", forState: UIControlState.Normal)
            }
            else
            {
                serverIpAddressTextField.enabled = false
                serverIpAddressTextField.alpha = 0.6
                serverPortNumberTextField.enabled = false
                serverPortNumberTextField.alpha = 0.6
                startButton.setTitle("Stop", forState: UIControlState.Normal)
                client.setDataEncoding(EncodingInfo[encodingInfoSelectedIndex])
                tcpClientUserDefault["EncodeIndex"] = encodingInfoSelectedIndex
                client.setTcpClientDestIpAddress(serverIpAddressTextField.text!)
                tcpClientUserDefault["ServerIp"] = serverIpAddressTextField.text!
                if let portNumber = UInt16.init(serverPortNumberTextField.text!){
                    client.setTcpClientDestPortNumber(portNumber)
                    tcpClientUserDefault["ServerPort"] = Int.init(portNumber)
                }
                client.connectToServer()
                if let passback = passbackTcpClientModelDelegate{
                    passback.passbackTcpClientModel(client)
                }
                
                NSUserDefaults.standardUserDefaults().setObject(tcpClientUserDefault, forKey: CONSTANTS.NSUSER_DEFAULT_TCP_CLIENT_KEY.getAssociatedString())
                self.dismissViewControllerAnimated(true, completion: nil)
            }
        }
        else
        {
            UIAlertView.init(title: "Error", message: "Unable to initiate TCP Client", delegate: nil, cancelButtonTitle: "OK").show()
        }
    }
    
    //MARK: -DataSource & Delegate Methods
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
        if let reuseableLabel = view as? UILabel{
            labelView = reuseableLabel
        }
        else
        {
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
        if let client = tcpClient{
            tcpClientUserDefault["EncodeIndex"] = encodingInfoSelectedIndex
            NSUserDefaults.standardUserDefaults().setObject(tcpClientUserDefault, forKey: CONSTANTS.NSUSER_DEFAULT_TCP_CLIENT_KEY.getAssociatedString())
            client.setDataEncoding(EncodingInfo[encodingInfoSelectedIndex])
        }
    }

}

protocol TcpClientModelPassingDelegate{
    func passbackTcpClientModel(client:TcpClient?)
}














