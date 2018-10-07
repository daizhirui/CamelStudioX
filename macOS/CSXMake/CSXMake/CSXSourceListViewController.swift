//
//  CSXSourceListViewController.swift
//  CSXMake
//
//  Created by Zhirui Dai on 2018/10/1.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

class CSXSourceListViewController: NSViewController {

    static func initiate(title: String) -> CSXSourceListViewController {
        let vc = CSXSourceListViewController(nibName: NSNib.Name("CSXSourceListView"),
                                           bundle: Bundle(for: CSXSourceListViewController.self))
        vc.title = title
        return vc
    }
    

    @IBOutlet weak var listTitle: NSTextField!
    @IBOutlet weak var sourceList: NSTableView!
    var fileList = Set<String>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.listTitle.stringValue = title ?? ""
        self.sourceList.dataSource = self
    }
    
    @IBAction func onAddSource(_ sender: NSButton) {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = true
        panel.canChooseFiles = true
        panel.canChooseDirectories = false
        guard let window = NSApp.mainWindow else { return }
        panel.beginSheetModal(for: window) { (response) in
            if response.rawValue == NSApplication.ModalResponse.OK.rawValue {
                for url in panel.urls {
                    self.fileList.insert(url.relativePath)
                }
                self.sourceList.reloadData()
                panel.endSheet(window)
            }
        }
    }
    @IBAction func onRemoveSource(_ sender: NSButton) {
        let fileArray = self.fileList.sorted()
        for index in self.sourceList.selectedRowIndexes {
            self.fileList.subtract([fileArray[index]])
        }
        self.sourceList.reloadData()
    }
}

extension CSXSourceListViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.fileList.count
    }
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return self.fileList.sorted()[row]
    }
}
