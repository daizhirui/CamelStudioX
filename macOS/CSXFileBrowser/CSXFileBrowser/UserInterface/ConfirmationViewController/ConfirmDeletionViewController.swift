//
//  AskConfirmationViewController.swift
//  CSXFileBrowser
//
//  Created by Zhirui Dai on 2018/7/13.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

class ConfirmDeletionViewController: NSViewController {
    
    static var applyToAll = false
    
    static func initiate() -> ConfirmDeletionViewController {
        return ConfirmDeletionViewController.init(nibName: NSNib.Name("ConfirmDeletionView"),
                                                  bundle: Bundle(for: ConfirmDeletionViewController.self))
    }

    @IBOutlet weak var customTouchBar: NSTouchBar!
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var confirmationTextLine1: NSTextField!
    @IBOutlet weak var confirmationTextLine2: NSTextField!
    @IBOutlet weak var okButton: NSButton!
    @IBOutlet weak var applyToAllButton: NSButton!
    var okHandler: (() -> Void)?
    var presentHandler: (()->Void)?
    var isPresented = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.image = getAppIcon()
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        self.isPresented = true
    }
    
    override func makeTouchBar() -> NSTouchBar? {
        return self.customTouchBar
    }
    
    func present() {
        if !ConfirmDeletionViewController.applyToAll {
            self.presentHandler?()
        } else {
            self.okAction(self)
        }
    }
    
    @IBAction func okAction(_ sender: Any) {
        self.okHandler?()
        self.close()
    }
    
    @IBAction func applyToAllAction(_ sender: Any) {
        ConfirmDeletionViewController.applyToAll = true
        self.okHandler?()
        self.close()
    }
    
    @IBAction func cancelAction(_ sender: NSButton) {
        self.close()
    }
    
    func close() {
        if self.isPresented {
            self.dismiss(self)
        }
    }
}
