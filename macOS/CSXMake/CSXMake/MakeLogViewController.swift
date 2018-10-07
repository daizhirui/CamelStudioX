//
//  MakeLogViewController.swift
//  CSXMake
//
//  Created by Zhirui Dai on 2018/9/30.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

public class MakeLogViewController: NSViewController {

    @IBOutlet var logTextView: NSTextView!
    public override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction public func onSave(_ sender: NSButton) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "mm-dd-yyyy hh:mm"
        panel.nameFieldStringValue = "MakeLog-\(dateFormatter.string(from: Date())).txt"
        guard let mainWindow = NSApp.mainWindow else { return }
        panel.beginSheetModal(for: mainWindow) { (response: NSApplication.ModalResponse) in
            if response.rawValue == NSApplication.ModalResponse.OK.rawValue {
                guard let url = panel.url else { return }
                try? self.logTextView.string.write(to: url, atomically: true, encoding: .utf8)
            }
        }
    }
    @IBAction public func onClear(_ sender: NSButton) {
        self.logTextView.string = ""
    }
}
