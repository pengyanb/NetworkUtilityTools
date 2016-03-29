//
//  DetectedIpDetailViewController.swift
//  NetworkUtilityTools
//
//  Created by Yanbing Peng on 12/02/16.
//  Copyright © 2016 Yanbing Peng. All rights reserved.
//

import UIKit

class DetectedIpDetailViewController: UIViewController, UITextFieldDelegate, UIWebViewDelegate {

    //MARK: -variables
    var urlString:String?
    
    //MARK: -outlets
    @IBOutlet weak var urlTextField: UITextField!
    
    @IBOutlet weak var webView: UIWebView!
    
    @IBOutlet weak var spinnerActivityIndicator: UIActivityIndicatorView!
    
    //MARK: -view life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        urlTextField.delegate = self
        webView.delegate = self
        // Do any additional setup after loading the view.
        spinnerActivityIndicator.stopAnimating()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        if let _urlString = urlString{
            if let url = NSURL.init(string: _urlString){
                urlTextField.text = _urlString
                testUrlInWebView(url)
            }
        }
    }

    //MARK: -private func
    private func testUrlInWebView(url:NSURL){
        spinnerActivityIndicator.startAnimating()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
        webView.loadRequest(NSURLRequest.init(URL: url))
    }
    
    //MARK: -delegate methods
    func textFieldShouldEndEditing(textField: UITextField) -> Bool {
        return true
    }
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        self.view.endEditing(true)
        if let _urlString = textField.text{
            if let url = NSURL.init(string: _urlString){
                urlString = _urlString
                testUrlInWebView(url)
            }
        }
        return false
    }
    func webViewDidFinishLoad(webView: UIWebView) {
        //print("[webViewDidFinishLoad]")
        UIApplication.sharedApplication().networkActivityIndicatorVisible = false
        spinnerActivityIndicator.stopAnimating()
    }
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        //print("[webViewDidFailLoadWithError]")
        spinnerActivityIndicator.stopAnimating()
        UIApplication.sharedApplication().networkActivityIndicatorVisible = true
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
