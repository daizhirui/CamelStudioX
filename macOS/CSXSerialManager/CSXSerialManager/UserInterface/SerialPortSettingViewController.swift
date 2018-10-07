//
//  SerialPortSettingViewController.swift
//  CSXSerialManager
//
//  Created by Zhirui Dai on 2018/9/29.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa
import ORSSerial

public class SerialPortSettingViewController: NSViewController {
    
    static func initiate() -> SerialPortSettingViewController {
        return SerialPortSettingViewController.init(nibName: NSNib.Name("SerialPortSettingView"),
                                                    bundle: Bundle(for: SerialPortSettingViewController.self))
    }
    
    var monitorViewController: SerialMonitorViewController?
    
    @objc var serialManager: CSXSerialManager = CSXSerialManager.shared
    @objc var selectedPort: ORSSerialPort? {
        didSet {
            guard let port = self.selectedPort else { return }
            // portStateLabel is initialized after selectedPort!
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                if port.isOpen == true {
                    self.portStateLabel.stringValue = "Opened"
                } else {
                    self.portStateLabel.stringValue = "Closed"
                }
            }
        }
    }
    
    @IBOutlet weak var portStateLabel: NSTextField!
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func onCancel(_ sender: NSButton) {
        self.dismiss(nil)
    }
    @IBAction func onOK(_ sender: NSButton) {
        self.monitorViewController?.updateBaudrateLabel()
        self.dismiss(nil)
    }
}
