//
//  SerialMonitorWindowController.swift
//  CSXSerialManager
//
//  Created by Zhirui Dai on 2018/11/3.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

public class SerialMonitorWindowController: NSWindowController {
    
    public static func initiate() -> SerialMonitorWindowController {
        let wc = SerialMonitorWindowController.init(windowNibName: NSNib.Name("SerialMonitorWindow"))
        return wc
    }

    override public func windowDidLoad() {
        super.windowDidLoad()
        
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
        self.contentViewController = SerialMonitorViewController.initiate()
        self.window?.contentView = self.contentViewController?.view
        self.window?.title = "Serial Monitor - \(SerialMonitorViewController.count)"
    }

}
