//
//  SendCrashReportViewController.swift
//  CamelStudioX
//
//  Created by 戴植锐 on 2019/7/12.
//  Copyright © 2019 Zhirui Dai. All rights reserved.
//

import Cocoa

class SendCrashReportViewController: NSViewController {
    
    @IBOutlet weak var progressInfo: NSTextField!
    @IBOutlet weak var okButton: NSButton!
    
    override func viewWillAppear() {
        self.okButton.isHidden = true
    }
    @IBAction func onOkButton(_ sender: Any) {
        self.view.window?.close()
    }
}
