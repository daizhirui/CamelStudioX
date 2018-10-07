//
//  CSXWebViewController.swift
//  CSXWebView
//
//  Created by Zhirui Dai on 2018/10/5.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa
import WebKit

public class CSXWebViewController: NSViewController {

    public static func initiate() -> CSXWebViewController {
        return CSXWebViewController.init(nibName: NSNib.Name("CSXWebViewController"), bundle: Bundle(for: CSXWebViewController.self))
    }
    
    @IBOutlet weak var webView: WKWebView!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
//        self.webView.uiDelegate = self
        self.webView.navigationDelegate = self
        self.progressBar.stopAnimation(self)
        self.progressBar.isHidden = true
    }
    
    public func loadURL(_ url: URL) {
        let request = URLRequest(url: url)
        self.webView.load(request)
    }
    
    @IBAction func onForwardBackward(_ sender: NSSegmentedControl) {
        if sender.selectedSegment == 0 {
            self.webView.goBack()
        } else {
            self.webView.goForward()
        }
    }
}

extension CSXWebViewController: WKNavigationDelegate {
    public func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
        self.progressBar.startAnimation(self)
        self.progressBar.isHidden = false
    }
    
    public func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.progressBar.stopAnimation(self)
        self.progressBar.isHidden = true
    }
    
    public func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
        NSLog("CSXWebView: \(error.localizedDescription)")
    }
}

