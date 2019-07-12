//
//  WelcomeWindowController.swift
//  CamelStudioX
//
//  Created by 戴植锐 on 2018/4/4.
//  Copyright © 2018年 戴植锐. All rights reserved.
//

import Cocoa

@available(OSX 10.12.2, *)
public class WelcomeWindowController: NSWindowController {
    
    public static func initiate() -> WelcomeWindowController {
        let wc = WelcomeWindowController.init(windowNibName: NSNib.Name("WelcomeWindow"))
        
        return wc
    }
    
    @IBOutlet weak var welcomeTouchBar: NSTouchBar!
    @IBOutlet var welcomeView: NSView!
    @IBOutlet weak var closeButton: NSButton!
    @IBOutlet weak var appIconView: NSImageView!
    @IBOutlet public weak var openExampleButton: NSButton!
    @IBOutlet weak var leftView: NSView!
    @IBOutlet weak var recentProjectTable: NSTableView!
    var selectedProjectNameTextField: NSTextField?
    var selectedProjectURLTextField: NSTextField?
    @IBOutlet weak var versionLabel: NSTextField!
    var recentProjectURLs: [URL] = {
        var urls = [URL]()
        for url in NSDocumentController.shared.recentDocumentURLs {
            if FileManager.default.fileExists(atPath: url.relativePath) {
                urls.append(url)
            }
        }
        return urls
    }()
    
    override public func windowDidLoad() {
//        super.windowDidLoad()
        NSApp.touchBar = welcomeTouchBar
        // Set the app icon
        self.appIconView.image = {
            if let infoDict = Bundle.main.infoDictionary {
                if let iconName = infoDict["CFBundleIconName"] as? String {
                    return NSImage(imageLiteralResourceName: iconName)
                }
            }
            return NSApp.applicationIconImage
        }()
        // Set the version label
        let version: Any = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")!
        // Set the build info
        let build: Any = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion")!
        self.versionLabel.stringValue = "Version \(version) (Build \(build))"
        // Set the background color of left part white
//        self.leftView.wantsLayer = true
//        self.leftView.layer?.backgroundColor = NSColor.white.cgColor
        // Set the looking of the recent project table
        self.recentProjectTable.selectionHighlightStyle = .sourceList
        // Set the double click action
        self.recentProjectTable.doubleAction = #selector(self.doubleClickRecentProject)
        // Load the recent project table
        self.recentProjectTable.delegate = self
        self.recentProjectTable.dataSource = self
        self.recentProjectTable.reloadData()
        let area = NSTrackingArea(rect: self.leftView.frame, options: [.activeAlways, .mouseEnteredAndExited], owner: self, userInfo: nil)
        self.window?.contentView?.addTrackingArea(area)
    }
    
    public override func showWindow(_ sender: Any?) {
        super.showWindow(sender)
        self.updateRecentProjectTable()
    }
    
    /// show close button when the mouse enters left view
    override public func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        self.closeButton.isHidden = false
    }
    
    /// hide close button when the mouse exits left view
    override public func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        self.closeButton.isHidden = true
    }
    
    public func updateRecentProjectTable() {
        var urls = [URL]()
        for url in NSDocumentController.shared.recentDocumentURLs {
            if FileManager.default.fileExists(atPath: url.relativePath) {
                urls.append(url)
            }
        }
        self.recentProjectURLs = urls
        self.recentProjectTable.reloadData()
    }
    
    // MARK: action
    @IBAction func closeWelcomeWindow(_ sender: Any) {
        self.window?.close()
    }

    /// Create a new project
    @IBAction func createNewProject(_ sender: Any) {
        NSDocumentController.shared.newDocument(nil)
        self.closeWelcomeWindow(self)
    }
    
    /// Choose and open a project
    @IBAction func openProject(_ sender: Any) {
        NSDocumentController.shared.openDocument(self)
        self.closeWelcomeWindow(self)
    }
}

extension WelcomeWindowController {
    /// Open project from recent project list
    @objc func doubleClickRecentProject() {
        if let stackView = self.getSelectedCellView()?.subviews[0] as? NSStackView {
            if let urlLabel = stackView.subviews[1] as? NSTextField {
                NSDocumentController.shared.openDocument(withContentsOf: URL(fileURLWithPath: urlLabel.stringValue), display: true, completionHandler: { _,_,_ in })
                self.closeWelcomeWindow(self)
            }
        }
    }
}

// MARK: NSTableViewDataSource
extension WelcomeWindowController: NSTableViewDataSource {
    
    public func numberOfRows(in tableView: NSTableView) -> Int {
        return self.recentProjectURLs.count
    }
    
    public func getSelectedCellView() -> NSView? {
        let row = self.recentProjectTable.selectedRow
        let column = self.recentProjectTable.selectedColumn
        if row >= 0 {
            return self.recentProjectTable.view(atColumn: column, row: row, makeIfNecessary: false)
        } else {
            return nil
        }
        
    }
}
// MARK: NSTableViewDelegate
extension WelcomeWindowController: NSTableViewDelegate {
    
    public func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 50
    }
    
    public func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        // 表格列的标识
        let key = (tableColumn?.identifier)!
        // 单元格数据
        let value = self.recentProjectURLs[row]
        // 根据表格列的标识，创建单元视图
        let view = tableView.makeView(withIdentifier: key, owner: self)
        let subviews = view?.subviews
        if (subviews?.count)! <= 0 {
            return nil
        }
        // 存储此单元格视图
        if let stackView = subviews?[0] as? NSStackView {
            if let projectNameLabel = stackView.subviews[0] as? NSTextField {
                projectNameLabel.stringValue = value.deletingPathExtension().lastPathComponent
                if #available(macOS 10.13, *) {
                    projectNameLabel.textColor = NSColor(named: NSColor.Name("UnselectionColor"),
                                                         bundle: Bundle(for: WelcomeWindowController.self))
                } else {
                    projectNameLabel.textColor = NSColor.systemGray
                }
            }
            if let projectURLLabel = stackView.subviews[1] as? NSTextField {
                projectURLLabel.stringValue = value.relativePath
                if #available(macOS 10.13, *) {
                    projectURLLabel.textColor = NSColor(named: NSColor.Name("UnselectionColor"),
                                                        bundle: Bundle(for: WelcomeWindowController.self))
                } else {
                    projectURLLabel.textColor = NSColor.systemGray
                }
            }
        }
        let projectImage = subviews?[1] as? NSImageView
        projectImage?.image = NSWorkspace.shared.icon(forFile: value.relativePath)
        return view
    }
    
    public func tableViewSelectionDidChange(_ notification: Notification) {
        // old selection
        if #available(macOS 10.13, *) {
            print(1)
            self.selectedProjectNameTextField?.textColor = NSColor(named: NSColor.Name("UnselectionColor"),
                                                                   bundle: Bundle(for: WelcomeWindowController.self))
            print(2)
            self.selectedProjectURLTextField?.textColor = NSColor(named: NSColor.Name("UnselectionColor"),
                                                                  bundle: Bundle(for: WelcomeWindowController.self))
        } else {
            print(3)
            self.selectedProjectNameTextField?.textColor = NSColor.systemGray
            
            print(4)
            self.selectedProjectURLTextField?.textColor = NSColor.systemGray
        }
        // new selection
        if let stackView = self.getSelectedCellView()?.subviews[0] as? NSStackView {
            self.selectedProjectNameTextField = stackView.arrangedSubviews[0] as? NSTextField
            self.selectedProjectURLTextField = stackView.arrangedSubviews[1] as? NSTextField
            self.selectedProjectNameTextField?.textColor = NSColor.white
            self.selectedProjectURLTextField?.textColor = NSColor.white
        }
    }
    
}
