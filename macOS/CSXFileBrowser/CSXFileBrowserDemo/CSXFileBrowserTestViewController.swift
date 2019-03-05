//
//  CSXFileBrowserTestViewController.swift
//  CSXFileBrowserTestViewController
//
//  Created by Zhirui Dai on 2018/6/27.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa
import CSXFileBrowser
//import CSXUtilities

class CSXFileBrowserTestViewController: NSViewController {
    
    @IBOutlet weak var fileBrowserView: NSView!
    @IBOutlet weak var textField: NSTextField!
    @IBOutlet weak var fileProcessProgress: NSProgressIndicator!
    
    var fileBrowser: CSXFileBrowser = {
        
//        CSXFileBrowser.printLog = {
//            log in
//            print(log)
//        }
        
        FileNode.printLog = {
            log in
            print(log)
        }
        
        CSXFileManager.printLog = {
            log in
            print(log)
        }
        
        let browser = CSXFileBrowser.init(nibName: "CSXFileBrowser", bundle: Bundle(for: CSXFileBrowser.self))
        return browser
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.fileBrowser.delegate = self
        // folderURL should be set before fileBrowser's view is loaded, to make sure all expaned items can be reloaded.
        self.fileBrowser.folderURL = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Desktop")
        self.fileBrowser.start()
        
        self.fileBrowserView.addSubview(self.fileBrowser.view)
        self.fileBrowser.viewDidLoad()
        self.fileBrowser.view.translatesAutoresizingMaskIntoConstraints = false
        let topConstraint = self.fileBrowser.view.topAnchor.constraint(equalTo: self.fileBrowserView.topAnchor)
        let leadingConstraint = self.fileBrowser.view.leadingAnchor.constraint(equalTo: self.fileBrowserView.leadingAnchor)
        let trailingConstraint = self.fileBrowser.view.trailingAnchor.constraint(equalTo: self.fileBrowserView.trailingAnchor)
        let bottomConstraint = self.fileBrowser.view.bottomAnchor.constraint(equalTo: self.fileBrowserView.bottomAnchor)
        
        NSLayoutConstraint.activate([topConstraint, leadingConstraint, trailingConstraint, bottomConstraint])
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    @IBAction func onRefresh(_ sender: Any) {
        self.fileBrowser.refresh(nil)
    }
    @IBAction func onExpand(_ sender: Any) {
        let selectedIndex = self.fileBrowser.outlineView.selectedRow
        let item = self.fileBrowser.outlineView.item(atRow: selectedIndex)
        self.fileBrowser.outlineView.expandItem(item)
    }
    
    @IBAction func onTextField(_ sender: NSTextField) {
//        CSXUtilities.CSXDebug("TextField")
//        guard let fileWrapper = self.fileBrowser.fileWrapper else {
//            return
//        }
//        try? fileWrapper.write(to: FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads").appendingPathComponent("CSX"),
//                               options: [], originalContentsURL: nil)
    }
}

extension CSXFileBrowserTestViewController: CSXFileBrowserDelegate {
    func fileBrowser(_ fileBrowser: CSXFileBrowser, encounter error: Error, message: String) {
        print(error.localizedDescription)
//        _ = InfoAndAlert.shared.showAlertWindow(type: InfoAndAlert.MessageType.alert,
//                                                title: message, message: error.localizedDescription, icon: nil,
//                                                allowCancel: false, showDontShowAgain: false, okayHandler: nil, cancelHandler: nil)
    }
    
    func fileBrowser(_ fileBrowser: CSXFileBrowser, processedFileTasks: Int, expectedFileTasks: Int) {
        self.fileProcessProgress.isIndeterminate = false
        if processedFileTasks == expectedFileTasks {
            self.fileProcessProgress.stopAnimation(self)
            self.fileProcessProgress.doubleValue = 0
        } else {
            self.fileProcessProgress.startAnimation(self)
            self.fileProcessProgress.maxValue = Double(expectedFileTasks)
            self.fileProcessProgress.doubleValue = Double(processedFileTasks)
        }
    }
    
    func fileBrowser(_ fileBrowser: CSXFileBrowser, startWith url: URL) {
        self.fileProcessProgress.isIndeterminate = true
        self.fileProcessProgress.startAnimation(self)
    }
    
    func fileBrowser(_ fileBrowser: CSXFileBrowser, alreadyStartedWith url: URL) {
        self.fileProcessProgress.isIndeterminate = false
        self.fileProcessProgress.stopAnimation(self)
    }
    
    func fileBrowserSelectionDidChange(_ fileBrowser: CSXFileBrowser, notification: Notification) {
        print("Selectio changed")
    }
}
