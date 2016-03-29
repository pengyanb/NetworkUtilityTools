//
//  ServiceMonitorOptionsViewController.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 14/01/16.
//  Copyright © 2016 Yanbing Peng. All rights reserved.
//

import UIKit

class ServiceMonitorOptionsViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource, UITextFieldDelegate, UITextViewDelegate {
    //MARK: -Variable
    private let serviceTypeLabelsText = ["HTTP", "TCP", "UDP"]
    private let httpMethodLabelsText = ["GET", "POST"]
    private let testCriteriaLabelsText = ["Equals to Response", "Contains Response"]
    
    var serviceMonitorModel : ServiceMonitor?
    
    //MARK: -Outlets
    @IBOutlet var scrollView: UIScrollView!
    
    @IBOutlet weak var serviceTypePickerView: UIPickerView!
    
    @IBOutlet weak var ipAddressTextField: UITextField!
    
    @IBOutlet weak var portNumTextField: UITextField!
    
    @IBOutlet weak var dataToSendTextField: UITextField!

    @IBOutlet weak var urlTextField: UITextField!
    
    @IBOutlet weak var httpMethodPicker: UIPickerView!
    
    @IBOutlet weak var httpBodyTextField: UITextField!
    
    @IBOutlet weak var responseTextView: UITextView!
    
    @IBOutlet weak var testIntervalPicker: UIDatePicker!
    
    @IBOutlet weak var testCriteriaPicker: UIPickerView!
    
    @IBOutlet weak var startServiceMonitorButton: UIButton!
    
    @IBOutlet weak var tcpUdpInputFieldsHeightConstraint: NSLayoutConstraint!
    
    @IBOutlet weak var httpInputFieldHeightConstraint: NSLayoutConstraint!
    
    //MARK: -Target Actions
    @IBAction func sendRequestButtonPressed(){
        responseTextView.text = ""
        switch serviceTypePickerView.selectedRowInComponent(0){
        case 0:
            serviceMonitorModel = ServiceMonitor.init(successHandler: {[unowned self] (response) -> (Void) in
                dispatch_async(dispatch_get_main_queue(), {[unowned self] () -> Void in
                    self.responseTextView.text = response
                })
                }, errorHandler: { (errorMessage) -> (Void) in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        UIAlertView.init(title: "Error", message: errorMessage, delegate: nil, cancelButtonTitle: "OK").show()
                    })
            })
            serviceMonitorModel?.sendHttpRequest(urlTextField.text!, method: (httpMethodPicker.selectedRowInComponent(0) == 0) ? "Get" : "Post", dataToPost: httpBodyTextField.text)
        case 1:
            if let port = UInt16.init(portNumTextField.text!){
                serviceMonitorModel = ServiceMonitor.init(successHandler: {[unowned self] (response) -> (Void) in
                    dispatch_async(dispatch_get_main_queue(), {[unowned self] () -> Void in
                        self.responseTextView.text = response
                    })
                    }, errorHandler: { (errorMessage) -> (Void) in
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            UIAlertView.init(title: "Error", message: errorMessage, delegate: nil, cancelButtonTitle: "OK").show()
                        })
                })
                serviceMonitorModel?.sendTcpRequest(ipAddressTextField.text!, port: port, dataToSend: dataToSendTextField.text!)
            }
        case 2:
            if let port = UInt16.init(portNumTextField.text!){
                serviceMonitorModel = ServiceMonitor.init(successHandler: {[unowned self] (response) -> (Void) in
                    dispatch_async(dispatch_get_main_queue(), { () -> Void in
                        self.responseTextView.text = response
                    })
                    }, errorHandler: { (errorMessage) -> (Void) in
                        dispatch_async(dispatch_get_main_queue(), { () -> Void in
                            UIAlertView.init(title: "Error", message: errorMessage, delegate: nil, cancelButtonTitle: "OK").show()
                        })
                })
                serviceMonitorModel?.sendUdpRequest(ipAddressTextField.text!, port: port, dataToSend: dataToSendTextField.text!)
            }
        default: break
        }
    }
    

    @IBAction func startServiceMonitorButtonPressed() {
        var serviceMonitorDefaults = [String:AnyObject]()
        if let serMonDefaults = NSUserDefaults.standardUserDefaults().objectForKey(CONSTANTS.NSUSER_DEFAULT_SERVICE_MONITOR_SETTING_KEY.getAssociatedString()) as? [String:AnyObject]{
            serviceMonitorDefaults = serMonDefaults
        }
        var isRunning = false
        if let statusRunning = serviceMonitorDefaults["IsRunning"] as? Bool{
            if statusRunning == true{
                isRunning = true
            }
        }
        
        if isRunning //stop service monitor
        {
            UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalNever)
            startServiceMonitorButton.setTitle("Start Service Monitor", forState: UIControlState.Normal)
            serviceMonitorDefaults["IsRunning"] = false
        }
        else  //start service monitor
        {
            serviceMonitorDefaults["IsRunning"] = true
            startServiceMonitorButton.setTitle("Stop Service Monitor", forState: UIControlState.Normal)
            serviceMonitorDefaults["ServiceTypeIndex"] = serviceTypePickerView.selectedRowInComponent(0)
            switch serviceTypePickerView.selectedRowInComponent(0){
            case 0:
                serviceMonitorDefaults["URL"] = urlTextField.text!
                serviceMonitorDefaults["HttpMethodIndex"] = httpMethodPicker.selectedRowInComponent(0)
                serviceMonitorDefaults["HttpBody"] = httpBodyTextField.text
            case 1: fallthrough
            case 2:
                let port = Int.init(portNumTextField.text!)
                serviceMonitorDefaults["IpAddress"] = ipAddressTextField.text!
                serviceMonitorDefaults["PortNumber"] = (port == nil) ? 80 : port
                serviceMonitorDefaults["DataToSend"] = dataToSendTextField.text!
            default:
                break
            }
            let dateFormatter = NSDateFormatter.init()
            dateFormatter.dateFormat = "HH"
            let hourValue = Int.init(dateFormatter.stringFromDate(testIntervalPicker.date))
            dateFormatter.dateFormat = "mm"
            let minuteValue = Int.init(dateFormatter.stringFromDate(testIntervalPicker.date))
            if hourValue != nil && minuteValue != nil{
                serviceMonitorDefaults["TestInterval"] = "\(hourValue!):\(minuteValue!)"
                serviceMonitorDefaults["TestIntervalSeconds"] = hourValue! * 3600 + minuteValue! * 60
                //print("[setMinimumBackgroundFetchInterval: \(hourValue! * 3600 + minuteValue! * 60)]")
                UIApplication.sharedApplication().setMinimumBackgroundFetchInterval(NSTimeInterval.init(hourValue! * 3600 + minuteValue! * 60))
                
            }
            serviceMonitorDefaults["ResponseSample"] = responseTextView.text!
            serviceMonitorDefaults["TestCriteriaIndex"] = testCriteriaPicker.selectedRowInComponent(0)
            
            var serviceMonitorResults = [String:AnyObject]()
            if let serMonResults = NSUserDefaults.standardUserDefaults().objectForKey(CONSTANTS.NSUSER_DEFAULT_SERVICE_MONITOR_RESULT_KEY.getAssociatedString()) as? [String:AnyObject]{
                serviceMonitorResults = serMonResults
            }
            serviceMonitorDefaults["FetchAlertWhenFail"] = true
            
            serviceMonitorResults["FetchTotalCount"] = 0
            serviceMonitorResults["FetchSuccessCount"] = 0
            serviceMonitorResults["FetchNoConnectionCount"] = 0
            serviceMonitorResults["FetchFailCount"] = 0
            
            NSUserDefaults.standardUserDefaults().setObject(serviceMonitorResults, forKey: CONSTANTS.NSUSER_DEFAULT_SERVICE_MONITOR_RESULT_KEY.getAssociatedString())
        }
        NSUserDefaults.standardUserDefaults().setObject(serviceMonitorDefaults, forKey: CONSTANTS.NSUSER_DEFAULT_SERVICE_MONITOR_SETTING_KEY.getAssociatedString())
        NSNotificationCenter.defaultCenter().postNotificationName(CONSTANTS.NOTI_SERVICE_MONITOR_RESULT_CHANGED.getAssociatedString(), object: "ServiceMonitorOptionView")
    }
    
    
    //MARK: -View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        self.scrollView.contentSize = CGSize(width: scrollView.bounds.width, height: 1400)
        serviceTypePickerView.dataSource = self
        serviceTypePickerView.delegate = self
        
        httpMethodPicker.dataSource = self
        httpMethodPicker.delegate = self
        
        testCriteriaPicker.dataSource = self
        testCriteriaPicker.delegate = self
        
        ipAddressTextField.delegate = self
        portNumTextField.delegate = self
        dataToSendTextField.delegate = self
        urlTextField.delegate = self
        httpBodyTextField.delegate = self
        
        responseTextView.delegate = self
        
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.mainScreen().applicationFrame.size.width, height: 50))
        doneToolbar.barStyle = UIBarStyle.Default
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: Selector("inputDoneButtonAction"))
        doneToolbar.items = [flexSpace, doneButton]
        doneToolbar.sizeToFit()
        responseTextView.inputAccessoryView = doneToolbar
        // Do any additional setup after loading the view.
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.popoverPresentationController?.backgroundColor = UIColor.darkGrayColor()
        
        serviceTypePickerView.selectRow(0, inComponent: 0, animated: false)
        hideTcpUdpRelatedInputFields()
        startServiceMonitorButton.setTitle("Start Service Monitor", forState: UIControlState.Normal)
        
        if let serviceMonitorDefaults = NSUserDefaults.standardUserDefaults().objectForKey(CONSTANTS.NSUSER_DEFAULT_SERVICE_MONITOR_SETTING_KEY.getAssociatedString()) as? [String:AnyObject]{
            
            if let serviceTypeIndex = serviceMonitorDefaults["ServiceTypeIndex"] as? Int{
                serviceTypePickerView.selectRow(serviceTypeIndex, inComponent: 0, animated: false)
                if serviceTypeIndex == 0{
                    hideTcpUdpRelatedInputFields()
                }
                else{
                    hideHttpRelatedInputFields()
                }
            }
            
            if let isRunning = serviceMonitorDefaults["IsRunning"] as? Bool{
                if isRunning == true{
                    startServiceMonitorButton.setTitle("Stop Service Monitor", forState: UIControlState.Normal)
                }
            }
            
            if let url = serviceMonitorDefaults["URL"] as? String{
                urlTextField.text = url
            }
            if let httpMethodIndex = serviceMonitorDefaults["HttpMethodIndex"] as? Int{
                httpMethodPicker.selectRow(httpMethodIndex, inComponent: 0, animated: false)
            }
            if let httpBody = serviceMonitorDefaults["HttpBody"] as? String{
                httpBodyTextField.text = httpBody
            }
            
            if let ipAddress = serviceMonitorDefaults["IpAddress"] as? String{
                ipAddressTextField.text = ipAddress
            }
            if let portNumber = serviceMonitorDefaults["PortNumber"] as? Int{
                portNumTextField.text = "\(portNumber)"
            }
            if let dataToSend = serviceMonitorDefaults["DataToSend"] as? String{
                dataToSendTextField.text = dataToSend
            }
            
            if let testInterval = serviceMonitorDefaults["TestInterval"] as? String{
                let dataFormatter = NSDateFormatter.init()
                dataFormatter.dateFormat = "HH:mm"
                if let date = dataFormatter.dateFromString(testInterval){
                    testIntervalPicker.date = date
                }
            }
            if let responseSample = serviceMonitorDefaults["ResponseSample"] as? String{
                responseTextView.text = responseSample
            }
        }
    }

    //MARK: -Private Functions
    private func hideHttpRelatedInputFields(){
        httpInputFieldHeightConstraint.constant = 0
        tcpUdpInputFieldsHeightConstraint.constant = 150
    }
    private func hideTcpUdpRelatedInputFields(){
        httpInputFieldHeightConstraint.constant = 280
        tcpUdpInputFieldsHeightConstraint.constant = 0
    }
    
    //MARK: -DataSource & Delegate Methods
    func inputDoneButtonAction(){
        responseTextView.resignFirstResponder()
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
        switch pickerView.tag{
        case 1: return 3
        case 2: return 2
        case 3: return 2
        default: return 0
        }
    }
    
    func pickerView(pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusingView view: UIView?) -> UIView {
        var labelView:UILabel? = nil
        if let reuseableLabel = view as? UILabel{
            labelView = reuseableLabel
        }
        else{
            labelView = UILabel()
        }
        labelView?.textColor = UIColor.blackColor()
        switch pickerView.tag{
        case 1: labelView?.text = serviceTypeLabelsText[row]
        case 2: labelView?.text = httpMethodLabelsText[row]
        case 3: labelView?.text = testCriteriaLabelsText[row]
        default: labelView?.text = ""
        }
        labelView?.font = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
        labelView?.textAlignment = NSTextAlignment.Center
        return labelView!
    }
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        switch pickerView.tag{
        case 1: if row == 0{
                hideTcpUdpRelatedInputFields()
            }
            else{
                hideHttpRelatedInputFields()
            }
        default: return
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
