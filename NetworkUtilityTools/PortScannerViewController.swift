//
//  PortScannerViewController.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 11/02/16.
//  Copyright © 2016 Yanbing Peng. All rights reserved.
//

import UIKit
import ActionSheetPicker_3_0

class PortScannerViewController: UIViewController, UITextFieldDelegate, UITableViewDataSource, UITableViewDelegate {

    //MARK: -variables
    lazy var ipPickerRowsData : [[String]] = {
        var _ipPickerRowsData = [[String]](count: 4, repeatedValue: [String](count: 255, repeatedValue: ""))
        for var i=0; i < 4; i++ {
            for var j=0; j < 255; j++ {
                _ipPickerRowsData[i][j] = "\(j+1)"
            }
        }
        return _ipPickerRowsData
    }()
    
    var typePickerRowsData : [String] = ["Raw Socket", "HTTP", "FTP", "RTSP"]
    
    var portScannerModel : PortScanner?
    
    var detectedIpAddress = [String]()
    
    var urlString = ""
    
    var selectedIp = ""
    
    var selectedPort = ""
    
    var selectedTypeIndex = 1
    
    //MARK: -outlets
    @IBOutlet weak var startIpRangeButton: UIButton!
    
    @IBOutlet weak var endIpRangeButton: UIButton!
    
    @IBOutlet weak var typeButton: UIButton!
    
    @IBOutlet weak var portTextField: UITextField!
    
    @IBOutlet weak var startButton: UIButton!
    
    @IBOutlet weak var resultTableView: UITableView!
    
    @IBOutlet weak var portScannerHeader: UINavigationItem!
    
    
    //MARK: -view life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        resultTableView.dataSource = self
        resultTableView.delegate = self
        portTextField.delegate = self
        
        let doneToolbar : UIToolbar = UIToolbar(frame: CGRect.init(x: 0, y: 0, width: UIScreen.mainScreen().applicationFrame.size.width, height: 50))
        doneToolbar.barStyle = UIBarStyle.Default
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let doneButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.Done, target: self, action: Selector("inputDoneButtonAction"))
        doneToolbar.items = [flexSpace, doneButton]
        doneToolbar.sizeToFit()
        portTextField.inputAccessoryView = doneToolbar
        // Do any additional setup after loading the view.
    }
    
    func inputDoneButtonAction(){
        portTextField.resignFirstResponder()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        deregisterNotificationsAboutModelChanges()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        registerForNotificationAboutModelChanges()
        if let portScannerDefaults = NSUserDefaults.standardUserDefaults().objectForKey(CONSTANTS.NSUSER_DEFAULT_PORT_SCANNER_SETTING_KEY.getAssociatedString()) as? [String:String]{
            self.startIpRangeButton.setTitle(portScannerDefaults["StartIpRangeButtonText"], forState: UIControlState.Normal)
            self.endIpRangeButton.setTitle(portScannerDefaults["EndIpRangeButtonText"], forState: UIControlState.Normal)
            self.typeButton.setTitle(portScannerDefaults["TypeButtonText"], forState: UIControlState.Normal)
            self.portTextField.text = portScannerDefaults["PortText"]
            
            var typeButtonText = self.typeButton.titleForState(UIControlState.Normal)
            if typeButtonText == nil{
                typeButtonText = "HTTP"
            }
            for var i = 0; i < typePickerRowsData.count; i++
            {
                if typePickerRowsData[i] == typeButtonText{
                    selectedTypeIndex = i
                    break
                }
            }
        }
    }
    
    //MARK: -target actions
    @IBAction func startIpRangeButtonPressed() {
        let ipSplit = self.startIpRangeButton.titleForState(UIControlState.Normal)!.componentsSeparatedByString(".")
        let initialSelection = [Int.init(ipSplit[0])! - 1, Int.init(ipSplit[1])! - 1, Int.init(ipSplit[2])! - 1, Int.init(ipSplit[3])! - 1]
        
        ActionSheetMultipleStringPicker.showPickerWithTitle("Start IP Address", rows: self.ipPickerRowsData, initialSelection: initialSelection, doneBlock: { (picker, indexes, values) -> Void in
                if let _indexes = indexes as? [Int]{
                    dispatch_async(dispatch_get_main_queue(), {[unowned self] () -> Void in
                        let ipPortion1 = "\(_indexes[0] + 1)"
                        let ipPortion2 = "\(_indexes[1] + 1)"
                        let ipPortion3 = "\(_indexes[2] + 1)"
                        let ipPortion4 = "\(_indexes[3] + 1)"
                        self.startIpRangeButton.setTitle(ipPortion1 + "." + ipPortion2 + "." + ipPortion3 + "." + ipPortion4, forState: UIControlState.Normal)
                    })
                }
            }, cancelBlock: { (picker) -> Void in
                return
            }, origin: self.startIpRangeButton)
    }

    @IBAction func endIpRangeButtonPressed() {
        let ipSplit = self.endIpRangeButton.titleForState(UIControlState.Normal)!.componentsSeparatedByString(".")
        let initialSelection = [Int.init(ipSplit[0])! - 1, Int.init(ipSplit[1])! - 1, Int.init(ipSplit[2])! - 1, Int.init(ipSplit[3])! - 1]
        
        ActionSheetMultipleStringPicker.showPickerWithTitle("End IP Address", rows: self.ipPickerRowsData, initialSelection: initialSelection, doneBlock: { (picker, indexes, values) -> Void in
            if let _indexes = indexes as? [Int]{
                dispatch_async(dispatch_get_main_queue(), { [unowned self] () -> Void in
                    let ipPortion1 = "\(_indexes[0] + 1)"
                    let ipPortion2 = "\(_indexes[1] + 1)"
                    let ipPortion3 = "\(_indexes[2] + 1)"
                    let ipPortion4 = "\(_indexes[3] + 1)"
                    self.endIpRangeButton.setTitle(ipPortion1 + "." + ipPortion2 + "." + ipPortion3 + "." + ipPortion4, forState: UIControlState.Normal)
                })
            }
            }, cancelBlock: { (picker) -> Void in
                return
            }, origin: self.endIpRangeButton)
    }
    
    @IBAction func typeButtonPressed() {
        var initialSelection = 1
        if let typeButtonText = typeButton.titleForState(UIControlState.Normal)
        {
            for var i = 0; i < typePickerRowsData.count; i++
            {
                if typePickerRowsData[i] == typeButtonText{
                    initialSelection = i
                    selectedTypeIndex = i
                    break
                }
            }
        }
        ActionSheetStringPicker.showPickerWithTitle("Type", rows: self.typePickerRowsData, initialSelection: initialSelection, doneBlock: { (picker, selectedIndex, selectedValue) -> Void in
                dispatch_async(dispatch_get_main_queue(), {[unowned self] () -> Void in
                    let buttonText = self.typePickerRowsData[selectedIndex]
                    self.selectedTypeIndex = selectedIndex
                    self.typeButton.setTitle(buttonText, forState: UIControlState.Normal)
                    switch self.selectedTypeIndex{
                    case 1: self.portTextField.text = "\(80)"
                    case 2: self.portTextField.text = "\(21)"
                    case 3: self.portTextField.text = "\(554)"
                    default:break
                    }
                })
            }, cancelBlock: { (picker) -> Void in
                return
            }, origin: self.typeButton)
    }
    
    @IBAction func startButtonPressed() {
        if let buttonTitle = self.startButton.titleForState(UIControlState.Normal)
        {
            if buttonTitle == "Start" {
                if let portNum = UInt16.init(self.portTextField.text!){
                    var userDefaults = [String:String]()
                    userDefaults["StartIpRangeButtonText"] = startIpRangeButton.titleForState(UIControlState.Normal)!
                    userDefaults["EndIpRangeButtonText"] = endIpRangeButton.titleForState(UIControlState.Normal)!
                    userDefaults["TypeButtonText"] = typeButton.titleForState(UIControlState.Normal)!
                    userDefaults["PortText"] = portTextField.text!
                    
                    NSUserDefaults.standardUserDefaults().setObject(userDefaults, forKey: CONSTANTS.NSUSER_DEFAULT_PORT_SCANNER_SETTING_KEY.getAssociatedString())
                    portScannerModel = PortScanner.init(startIpRange: userDefaults["StartIpRangeButtonText"]!, endIpRange: userDefaults["EndIpRangeButtonText"]!, portNum: portNum, scanType: selectedTypeIndex)
                    detectedIpAddress = [String]()
                    resultTableView.reloadData()
                    portScannerModel?.startPortScan()
                    UIApplication.sharedApplication().networkActivityIndicatorVisible = true
                    startButton.setTitle("Stop", forState: UIControlState.Normal)
                }
                else
                {
                    UIAlertView.init(title: "Error", message: "Invalid Port Number", delegate: nil, cancelButtonTitle: "OK").show()
                }
            }
            else
            {
                portScannerModel?.stopPortScan()
                startButton.setTitle("Start", forState: UIControlState.Normal)
            }
        }
        
    }
    
    //MARK: -Notification
    func registerForNotificationAboutModelChanges(){
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleModelChanges:"), name: CONSTANTS.NOTI_PORT_SCANNER_MODEL_CHANGED.getAssociatedString(), object: nil)
    }
    func deregisterNotificationsAboutModelChanges(){
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func handleModelChanges(notification:NSNotification){
        if let userInfo = notification.userInfo{
            if let changeType = userInfo["ChangeType"] as? String{
                if changeType == "Testing" {
                    if let info = userInfo["Info"] as? String
                    {
                        dispatch_async(dispatch_get_main_queue(), {[unowned self] () -> Void in
                            self.portScannerHeader.title = info
                        })
                    }
                }
                
                if changeType == "Done"{
                    print("[Port Scanner Done]")
                    dispatch_async(dispatch_get_main_queue(), {[unowned self] () -> Void in
                        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
                        self.portScannerHeader.title = "Done"
                        self.startButton.setTitle("Start", forState: UIControlState.Normal)
                    })
                }
                
                if changeType == "Error" {
                    dispatch_async(dispatch_get_main_queue(), {[unowned self] () -> Void in
                        self.portScannerHeader.title = "Error"
                        self.startButton.setTitle("Start", forState: UIControlState.Normal)
                        if let info = userInfo["Info"] as? String{
                             UIAlertView.init(title: "Error", message: info, delegate: nil, cancelButtonTitle: "OK").show()
                        }
                    })
                }
                
                if changeType == "Detected" {
                    if let info = userInfo["Info"] as? String{
                        dispatch_async(dispatch_get_main_queue(), {[unowned self] () -> Void in
                            self.detectedIpAddress.append(info)
                            self.resultTableView.reloadData()
                        })
                    }
                }
            }
        }
    }
    
    //MARK: -Delegate Methods
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        return true
    }
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return detectedIpAddress.count
    }
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var cell:UITableViewCell? = nil
        if let reuseableCell = tableView.dequeueReusableCellWithIdentifier("portScannerTableViewCell"){
            cell = reuseableCell
        }
        else{
            cell = UITableViewCell.init(style: UITableViewCellStyle.Default, reuseIdentifier: "portScannerTableViewCell")
        }
        cell?.textLabel?.text = detectedIpAddress[indexPath.row]
        if self.selectedTypeIndex == 3{
            cell?.accessoryType = UITableViewCellAccessoryType.DetailDisclosureButton
        }
        else
        {
            cell?.accessoryType = UITableViewCellAccessoryType.None
        }
        return cell!
    }
    func tableView(tableView: UITableView, accessoryButtonTappedForRowWithIndexPath indexPath: NSIndexPath) {
        if self.selectedTypeIndex == 3 {
            urlString = "http://\(detectedIpAddress[indexPath.row]):80"
            self.performSegueWithIdentifier(CONSTANTS.SEGUE_SHOW_PORT_SCANNER_DETECTED_IP_DETAIL.getAssociatedString(), sender: self)
        }
        
    }
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if self.selectedTypeIndex == 0 || self.selectedTypeIndex == 1{
            urlString = "http://\(detectedIpAddress[indexPath.row]):\(portTextField.text!)"
            self.performSegueWithIdentifier(CONSTANTS.SEGUE_SHOW_PORT_SCANNER_DETECTED_IP_DETAIL.getAssociatedString(), sender: self)
        }
        else if self.selectedTypeIndex == 2 {
            urlString = "ftp://\(detectedIpAddress[indexPath.row]):\(portTextField.text!)"
            self.performSegueWithIdentifier(CONSTANTS.SEGUE_SHOW_PORT_SCANNER_DETECTED_IP_DETAIL.getAssociatedString(), sender: self)
        }
        else if self.selectedTypeIndex == 3 {
            selectedIp = detectedIpAddress[indexPath.row]
            selectedPort = portTextField.text!
            self.performSegueWithIdentifier(CONSTANTS.SEGUE_SHOW_PORT_SCANNER_STREAM_PLAYER.getAssociatedString(), sender: self)
        }
    }
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if let identifier = segue.identifier{
            if identifier == CONSTANTS.SEGUE_SHOW_PORT_SCANNER_DETECTED_IP_DETAIL.getAssociatedString(){
                if let destVC = segue.destinationViewController as? DetectedIpDetailViewController{
                    destVC.urlString = urlString
                }
            }
            else if identifier == CONSTANTS.SEGUE_SHOW_PORT_SCANNER_STREAM_PLAYER.getAssociatedString(){
                if let destVC = segue.destinationViewController as? StreamPlayerViewController{
                    destVC.ipAddress = selectedIp
                    destVC.portNum = selectedPort
                    destVC.needToResolveUrl = true
                }
            }
        }
    }
    
}





































