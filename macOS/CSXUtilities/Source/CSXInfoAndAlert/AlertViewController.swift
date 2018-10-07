//
//  AlertViewController.swift
//  CSXInfoAndAlert
//
//  Created by ZhiruiDai on 2018/5/24.
//  Copyright © 2018 ZhiruiDai. All rights reserved.
//

import Cocoa

class AlertViewController: NSViewController {

    @IBOutlet weak var icon: NSImageView!
    @IBOutlet weak var informativeText: NSTextField!
    
    var needDontShowAgain = false
    @IBOutlet weak var dontShowAgain: NSButton!
    
    var okayHandler: (()->Void)?
    var cancelHandler: (()->Void)?
    
    @IBOutlet weak var cancelButton: NSButton!
    var needCancelButton = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        if self.needCancelButton {
            self.view.window?.styleMask.insert(NSWindow.StyleMask.closable)
        } else {
            self.view.window?.styleMask.remove(NSWindow.StyleMask.closable)
        }
        
        self.dontShowAgain.isHidden = !self.needDontShowAgain
        self.cancelButton.isHidden = !self.needCancelButton
    }
    
    @IBAction func closeAlert(_ sender: Any) {
        if !self.dontShowAgain.isHidden && self.informativeText.stringValue.count > 0 {
            
            var newDict: [String : Bool]
            if let donotShowAgainDict = UserDefaults.standard.object(forKey: "Don'tShowAgain") as? [String : Bool] {
                newDict = donotShowAgainDict
            } else {
                newDict = [String : Bool]()
            }
            
            if self.dontShowAgain.state == .on {
                newDict[self.informativeText.stringValue] = true
            } else {
                newDict[self.informativeText.stringValue] = false
            }
            
            UserDefaults.standard.setValue(newDict as Any, forKey: "Don'tShowAgain")
        }
        self.view.window?.close()
        NSApp.abortModal()
        if let button = sender as? NSButton {
            if button.title == "OK" {
                self.okayHandler?()
            } else if button.title == "Cancel" {
                self.cancelHandler?()
            }
        }
    }
}
