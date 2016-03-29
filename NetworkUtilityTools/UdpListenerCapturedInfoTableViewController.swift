//
//  UdpListenerCapturedInfoTableViewController.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 12/11/15.
//  Copyright © 2015 Yanbing Peng. All rights reserved.
//

import UIKit

class UdpListenerCapturedInfoTableViewController: UITableViewController, UIPopoverPresentationControllerDelegate, UdpListenerModelPassingDelegate {

    var udpListener : UdpListener?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.estimatedRowHeight = 100.0
        tableView.rowHeight = UITableViewAutomaticDimension
        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
    }
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        registerNotificationsAboutModelChanges()
        if udpListener == nil{
            performSegueWithIdentifier(CONSTANTS.SEGUE_UDP_LISTENER_OPTIONS.getAssociatedString(), sender: self)
        }
    }
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        deregisterNotificationsAboutModelChanges()
    }

    // MARK: Notifications
    func registerNotificationsAboutModelChanges(){
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("handleModelChanges"), name: CONSTANTS.NOTI_UDP_MODEL_CHANGED.getAssociatedString(), object: nil)
    }
    
    func deregisterNotificationsAboutModelChanges(){
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func handleModelChanges()->Void{
        //print("handleModelChanges")
        if let listener = udpListener{
            if listener.udpCapturedInfoDictionary.count > 0{
                SwiftSpinner.hide()
            }
        }
        self.tableView.reloadData()
    }

    // MARK: - Table view data source
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        objc_sync_enter(udpListener?.udpCapturedInfoDictionary)
        if let listener = udpListener{
            //print("[numberOfSectionsInTableView]: \(listener.udpCapturedInfoDictionary.count)")
            objc_sync_exit(udpListener?.udpCapturedInfoDictionary)
            return listener.udpCapturedInfoDictionary.count
        }
        else{
            //print("[numberOfSectionsInTableView]: 0")
            objc_sync_exit(udpListener?.udpCapturedInfoDictionary)
            return 0
        }
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        objc_sync_enter(udpListener?.udpCapturedInfoDictionary)
        if let listener = udpListener{
            let key = Array(listener.udpCapturedInfoDictionary.keys)[section]
            //print("[numberOfRowsInSection]: \(listener.udpCapturedInfoDictionary[key]!.count)")
            objc_sync_exit(udpListener?.udpCapturedInfoDictionary)
            return listener.udpCapturedInfoDictionary[key]!.count
        }
        else{
            //print("[numberOfRowsInSection]: 0")
            objc_sync_exit(udpListener?.udpCapturedInfoDictionary)
            return 0
        }
       
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        //print("[cell Identifier]: \(CONSTANTS.TABLE_CELL_UDP_LISTENER.getAssociatedString())")
        let cell = tableView.dequeueReusableCellWithIdentifier(CONSTANTS.TABLE_CELL_UDP_LISTENER.getAssociatedString(), forIndexPath: indexPath)
        if let udpCapturedInfoCell = cell as? UdpListenerCapturedInfoTableViewCell{
            objc_sync_enter(udpListener?.udpCapturedInfoDictionary)
            if let listener = udpListener{
                let key = Array(listener.udpCapturedInfoDictionary.keys)[indexPath.section]
                if let udpCapturedInfo = listener.udpCapturedInfoDictionary[key]?[indexPath.item]
                {
                    udpCapturedInfoCell.title.text = "[" + udpCapturedInfo.getTimestamp() + "]"
                    udpCapturedInfoCell.details.text = udpCapturedInfo.getDataStringWithEncodingType(listener.getDataEncoding())
                    //print(udpCapturedInfo.getDataHexdecimalString())
                }
            }
            objc_sync_exit(udpListener?.udpCapturedInfoDictionary)
        }
        return cell
    }
    
    override func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        var sectionTitle = ""
        objc_sync_enter(udpListener?.udpCapturedInfoDictionary)
        if let listener = udpListener{
            sectionTitle = "From : " + Array(listener.udpCapturedInfoDictionary.keys)[section]
        }
        objc_sync_exit(udpListener?.udpCapturedInfoDictionary)
        
        return sectionTitle
    }
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        if editingStyle == .Delete {
            // Delete the row from the data source
            if let listener = udpListener{
                listener.udpCapturedInfoDictionary[Array(listener.udpCapturedInfoDictionary.keys)[indexPath.section]]?.removeAtIndex(indexPath.item)
            }
            tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
        }
    }
    

    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if let identifier = segue.identifier
        {
            switch identifier{
            case CONSTANTS.SEGUE_UDP_LISTENER_OPTIONS.getAssociatedString():
                if let udpListenerOptionsVC = segue.destinationViewController as? UdpListenerOptionsViewController{
                    udpListenerOptionsVC.passbackUdpListenerModelDelegate = self
                    if let ppc = udpListenerOptionsVC.popoverPresentationController{
                        ppc.delegate = self
                    }
                    if let listener = udpListener{
                        //print("UdpListenerCapturedInfoTableViewController pass mode")
                        udpListenerOptionsVC.udpListener = listener
                    }
                }
            default:break
            }
        }
        
    }
    
    //
    func adaptivePresentationStyleForPresentationController(controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.None
    }
    
    func passbackUdpListenerModel(listener: UdpListener?) {
        //print("passbackUdpListenerModel")
        if let passbackListener = listener{
            udpListener = passbackListener
            if let listener = udpListener{
                if listener.isRunning{
                    if listener.udpCapturedInfoDictionary.count == 0{
                        SwiftSpinner.show("UDP Listener [Port \(listener.getUdpPortNum())], capturing...").addTapHandler({
                            SwiftSpinner.hide()
                        });
                    }
                    else{
                        SwiftSpinner.hide()
                    }
                }
            }
        }
    }
}





































