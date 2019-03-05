//
//  SerialMonitorViewController.swift
//  CSXSerialManager
//
//  Created by Zhirui Dai on 2018/9/29.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa
import ORSSerial

public class SerialMonitorViewController: NSViewController {
    
    public static var count = 0
    
    public static func initiate() -> SerialMonitorViewController {
        return SerialMonitorViewController.init(nibName: NSNib.Name("SerialMonitorView"), bundle: Bundle(for: SerialMonitorViewController.self))
    }
    
    @IBOutlet weak var portPopupButton: NSPopUpButton!
    @IBOutlet weak var openPortButton: NSButton!
    @IBOutlet var outputView: SerialOutputView!
    @IBOutlet weak var baudrateLabel: NSTextField!
    @IBOutlet weak var sendTextView: NSTextView!
    @IBOutlet weak var autoClearSendTextView: NSButton!
    
    @IBOutlet weak public var targetAddress: NSTextField!
    @IBOutlet weak public var binaryPath: NSTextField!
    @IBOutlet weak var loadButton: NSButton!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    @IBOutlet weak public var progressInfo: NSTextField!
    @IBOutlet weak var saveAsButton: NSButton!
    
    @objc var serialManager: CSXSerialManager = CSXSerialManager.shared
    @objc public var selectedPort: ORSSerialPort? {
        willSet {
            if let port = self.selectedPort, port.isOpen {
                self.onOpenOrClosePort(self.openPortButton)
            }
        }
        didSet {
            self.updateBaudrateLabel()
        }
    }
    var uploader = CSXUploader(csxSerialManager: CSXSerialManager.shared)

    deinit {
        SerialMonitorViewController.count -= 1
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.sendTextView.toolTip = "Input what you want to send"
        self.outputView.userInputDelegate = self
        self.uploader.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.serialPortEmergencyReaction(_:)),
                                               name: CSXSerialManager.didDisconnectSerialPortNotification,
                                               object: self.serialManager)
        NotificationCenter.default.addObserver(self, selector: #selector(self.serialPortEmergencyReaction(_:)),
                                               name: CSXSerialManager.didEncounterErrorNotification,
                                               object: self.serialManager)
    }
    
    public override func viewDidAppear() {
        super.viewDidAppear()
        SerialMonitorViewController.count += 1
    }
    
    override public func viewWillDisappear() {
        super.viewWillDisappear()
        SerialMonitorViewController.count -= 1
        
        guard let port = self.selectedPort else { return }
        port.close()
        guard let buffer = self.serialManager.getSerialBuffer(for: port) else { return }
        buffer.requestCheckTimer?.invalidate()
        buffer.requestCheckTimer = nil
        buffer.requestTimeoutTimer?.invalidate()
        buffer.requestTimeoutTimer = nil
    }
    
    func updateBaudrateLabel() {
        if let port = self.selectedPort {
            self.baudrateLabel.stringValue = "Baudrate: \(port.baudRate) bps"
        }
    }
    
    @objc func serialPortEmergencyReaction(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        
        guard let portName = userInfo[CSXSerialManager.Key.PortName] as? String else { return }
        if self.selectedPort?.name == portName {
            self.openPortButton.title = "Open"
            self.portPopupButton.select(nil)    // deselect all the ports
        }
    }
 
    @IBAction func onOpenOrClosePort(_ sender: NSButton) {
        guard let port = self.selectedPort else { return }
        if port.isOpen {
            port.close()
            sender.title = "Open"
        } else {
            port.open()
            self.serialManager.connectTextViewToPort(with: self.outputView, to: port)
            sender.title = "Close"
        }
    }
    @IBAction func onClearOutput(_ sender: NSButton) {
        self.outputView.string = ""
    }
    @IBAction func onSend(_ sender: NSButton) {
        guard let port = self.selectedPort, port.isOpen else { return }
        guard let buffer = self.serialManager.getSerialBuffer(for: port) else { return }
        buffer.sendString(self.sendTextView.string)
        if self.autoClearSendTextView.state == .on {
            self.sendTextView.string = ""
        }
    }
    @IBAction func onSendFile(_ sender: NSButton) {
        guard let port = self.selectedPort, port.isOpen else { return }
        
        let openDlg = NSOpenPanel()
        openDlg.allowsMultipleSelection = false
        openDlg.canChooseDirectories = false
        openDlg.canChooseFiles = true
        guard let window = NSApp.mainWindow else { return }
        openDlg.beginSheetModal(for: window) { (response) in
            if response.rawValue == NSApplication.ModalResponse.OK.rawValue {
                guard let url = openDlg.url else { return }
                guard let data = try? Data(contentsOf: url) else { return }
                port.send(data)
                openDlg.endSheet(window)
            }
        }
    }
    var logURL: URL?
    @IBAction func onSave(_ sender: NSButton) {
        if let url = self.logURL {
            try? self.outputView.string.write(to: url, atomically: true, encoding: .utf8)
        } else {
            self.onSaveAs(self.saveAsButton)
        }
    }
    @IBAction func onSaveAs(_ sender: NSButton) {
        let panel = NSSavePanel()
        panel.canCreateDirectories = true
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "mm-dd-yyyy hh:mm"
        panel.nameFieldStringValue = "MakeLog-\(dateFormatter.string(from: Date())).txt"
        guard let mainWindow = NSApp.mainWindow else { return }
        panel.beginSheetModal(for: mainWindow) { (response: NSApplication.ModalResponse) in
            if response.rawValue == NSApplication.ModalResponse.OK.rawValue {
                guard let url = panel.url else { return }
                try? self.outputView.string.write(to: url, atomically: true, encoding: .utf8)
                self.logURL = url
            }
        }
        
    }
    @IBAction func onOpenBinary(_ sender: NSButton) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = false
        guard let window = NSApp.mainWindow else { return }
        panel.beginSheetModal(for: window) { (response) in
            if response.rawValue == NSApplication.ModalResponse.OK.rawValue {
                guard let url = panel.url else { return }
                self.binaryPath.stringValue = url.relativePath
                self.binaryPath.toolTip = url.relativePath
                panel.endSheet(window)
            }
        }
    }
    @IBAction public func onLoad(_ sender: Any) {
        if self.loadButton.title == "Load" {
            guard self.binaryPath.stringValue.count > 0 else {
                self.progressInfo.stringValue = "Binary path is empty!"
                return
            }
            guard self.targetAddress.stringValue.count > 0 else {
                self.progressInfo.stringValue = "Target Address is empty!"
                return
            }
            guard let port = self.selectedPort else {
                self.progressInfo.stringValue = "Serial Port is not selected!"
                return }
            guard let buffer = self.serialManager.getSerialBuffer(for: port) else {
                self.progressInfo.stringValue = "Fail to get buffer!"
                return
            }
            if !port.isOpen { self.onOpenOrClosePort(self.openPortButton) }
            
            self.uploader.upload(with: URL(fileURLWithPath: self.binaryPath.stringValue),
                                 to: buffer, targetAddress: self.targetAddress.stringValue)
            self.loadButton.title = "Cancel"
        } else if self.loadButton.title == "Cancel" {
            self.uploader.stopUpload()
            self.loadButton.title = "Load"
        }
    }
    @IBAction func onJumpTo(_ sender: NSButton) {
        guard let data1 = "3".data(using: .ascii) else { return }
        guard let data2 = "\(self.targetAddress.stringValue)\n".data(using: .ascii) else { return }
        if self.selectedPort?.isOpen == false {
            self.onOpenOrClosePort(self.openPortButton)
        }
        self.selectedPort?.send(data1)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.selectedPort?.send(data2)
        }
    }
    @IBAction func onMoreSettings(_ sender: NSButton) {
        let settingVC = SerialPortSettingViewController.initiate()
        settingVC.selectedPort = self.selectedPort
        settingVC.monitorViewController = self
        self.presentAsSheet(settingVC)
    }
    @IBAction func onAutoScroll(_ sender: NSButton) {
        guard let port = self.selectedPort else { return }
        guard let buffer = self.serialManager.getSerialBuffer(for: port) else { return }
        buffer.autoScroll = (sender.state == .on)
    }
}

extension SerialMonitorViewController: SerialOutputViewDelegate {
    func serialOutputView(_ textView: SerialOutputView, userDidInput content: String) {
        guard let port = self.selectedPort, port.isOpen else { return }
        guard let data = content.data(using: .ascii) else { return }
        port.send(data)
    }
}

extension SerialMonitorViewController: CSXUploaderDelegate {
    func didCloseSerialPort(_ uploader: CSXUploader, portName: String) {
        if portName == self.selectedPort?.name {
            self.openPortButton.title = "Open"
        }
    }
    
    func csxUploader(_ uploader: CSXUploader, didFinish stage: CSXUploader.UploadStage) {
        self.progressBar.maxValue = Double(CSXUploader.UploadStage.setBaudrate9600.rawValue)
        self.progressBar.doubleValue = Double(stage.rawValue)
        self.progressInfo.stringValue = "\((Float(stage.rawValue) / Float(CSXUploader.UploadStage.setBaudrate9600.rawValue) * 100).rounded(.up))%"
    }
    
    func csxUploader(_ uplodaer: CSXUploader, failure reason: String, suggestedPortAction: SerialPortAction?) {
        self.progressInfo.stringValue = reason
        self.progressInfo.toolTip = reason
        self.progressBar.stopAnimation(self)
        self.loadButton.title = "Load"
    }
    
    func didUploadSuccessfully(_ uploader: CSXUploader) {
        self.progressInfo.stringValue = "Upload successfully"
        self.progressBar.stopAnimation(self)
        self.loadButton.title = "Load"
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.progressInfo.stringValue = "CSXUploader"
        }
    }
    
    
}
