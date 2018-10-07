//
//  CSXInfoAndAlertTestViewController.swift
//  CSXInfoAndAlertTest
//
//  Created by Zhirui Dai on 2018/6/30.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa
import CSXUtilities

class CSXInfoAndAlertTestViewController: NSViewController {

    @IBOutlet weak var appIcon: NSImageView!
    @IBOutlet weak var appName: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.appIcon.image = CSXUtilities.getAppIcon() // NSImage(imageLiteralResourceName: "AppIcon")
        
        self.appName.stringValue = Bundle.main.bundleURL.deletingPathExtension().lastPathComponent
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    override func viewDidAppear() {
        _ = InfoAndAlert.shared.showAlertWindow(type: .info, title: "Test Info", message: "This is a test info", icon: nil,
                                            allowCancel: true, showDontShowAgain: true,
                                            okayHandler: { print("OK") }, cancelHandler: { print("Cancel") })
    }

}

