//
//  StreamPlayerViewController.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 23/02/16.
//  Copyright © 2016 Yanbing Peng. All rights reserved.
//

import UIKit

class StreamPlayerViewController: UIViewController, UITextFieldDelegate, GCDAsyncSocketDelegate{

    //MARK: -Variables
    var ipAddress:String!
    var portNum:String!
    var needToResolveUrl:Bool = false
    
    var mediaPlayer : VLCMediaPlayer?
    private var tcpSocket:GCDAsyncSocket?
    
    //MARK: -Outlets
    
    @IBOutlet weak var playButton: UIButton!
    
    @IBOutlet weak var stopButton: UIButton!
    
    @IBOutlet weak var logTextView: UITextView!
    
    @IBOutlet weak var mediaView: UIView!
    
    @IBOutlet weak var streamUrlTextField: UITextField!
    
    @IBOutlet weak var logTextViewHeightLayoutConstraint: NSLayoutConstraint!
    //MARK: -Action Methods
    @IBAction func playButtonPressed() {
        if let player = mediaPlayer{
            if player.isPlaying(){
                player.pause()
                playButton.setTitle("||", forState: UIControlState.Normal)
            }
            else
            {
                playMedia(player)
            }
        }
    }
    
    @IBAction func stopButtonPressed() {
        mediaPlayer?.stop()
    }
    
    
    //MARK: -View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        mediaPlayer = VLCMediaPlayer.init()
        mediaPlayer?.drawable = mediaView
        streamUrlTextField.text = "rtsp://\(ipAddress):\(portNum)"
        // Do any additional setup after loading the view.
        
        streamUrlTextField.delegate = self
        
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if needToResolveUrl{
            logTextViewHeightLayoutConstraint.constant = 50
            tryResolveUrl()
        }
        else{
            logTextViewHeightLayoutConstraint.constant = 0
        }
    }
    //MARK: -Delegate methods [Socket]
    @objc func socket(sock: GCDAsyncSocket!, didConnectToHost host: String!, port: UInt16) {
        let dataString = "DESCRIBE rtsp://\(host) RTSP/1.0\r\nCSeq: 2\r\n\r\n"
        if let dataToSend = dataString.dataUsingEncoding(CONSTANTS.ENCODING_ASCII.getAssociatedUInt()){
            sock.writeData(dataToSend, withTimeout: 5, tag: 0)
            sock.readDataWithTimeout(5, tag: 0)
            print("[Sent: \(dataString)]")
        }
        else
        {
            sock.disconnect()
        }
    }
    
    @objc func socket(sock: GCDAsyncSocket!, didReadData data: NSData!, withTag tag: Int) {
        if let rtspResponse = String.init(data: data, encoding: CONSTANTS.ENCODING_ASCII.getAssociatedUInt())
        {
            logTextView.text = rtspResponse
        }
    }
    
    //MARK: -keyboard Related
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        return false
    }
    
    //MARK: -private func
    private func tryResolveUrl()->Bool{
        print("[TryResolveUrl]")
        tcpSocket = GCDAsyncSocket.init(delegate: self, delegateQueue: dispatch_get_main_queue())
        do{
            try tcpSocket?.connectToHost(ipAddress, onPort: UInt16.init(portNum)!, withTimeout: 5)
            return true
        }
        catch{
            return false
        }
    }
    
    private func playMedia(player:VLCMediaPlayer){
        if let url = getMediaURL(){
            if let media = VLCMedia(URL: url){
                player.setMedia(media)
                player.play()
                playButton.setTitle("▶︎", forState: UIControlState.Normal)
            }
            else
            {
                UIAlertView.init(title: "Error", message: "Invalid URL", delegate: nil, cancelButtonTitle: "OK").show()
            }
        }
        else
        {
            UIAlertView.init(title: "Error", message: "Invalid URL", delegate: nil, cancelButtonTitle: "OK").show()
        }
    }
    
    private func getMediaURL()->NSURL?{
        return NSURL.init(string: streamUrlTextField.text!)
    }

}


















