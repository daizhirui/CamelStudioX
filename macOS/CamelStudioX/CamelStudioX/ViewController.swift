//
//  ViewController.swift
//  CamelStudioX
//
//  Created by Zhirui Dai on 2018/10/4.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa
import CSXFileBrowser
import CSXSerialManager
import CSXToolchains
import CSXWelcome
import CSXCodeView
import CSXTabViewController
import CSXWebView
import CSXLog
import CSXUtilities
import ORSSerial

class FileViewPackage: NSObject {
    var tabID: Int
    var fileNode: FileNode
    var codeViewController: CSXCodeViewController
    
    init(tabID: Int, fileNode: FileNode, codeViewController: CSXCodeViewController) {
        self.tabID = tabID
        self.fileNode = fileNode
        self.codeViewController = codeViewController
    }
}

class ViewController: NSViewController {
    
    static var viewControllerCount = 0
    
    var document: Document?

    @IBOutlet weak var viewSplitView: NSSplitView!
    @IBOutlet weak var sidePanelTabBar: NSSegmentedControl!
    @IBOutlet weak var sidePanelTabView: NSTabView!
    var sidePanelViewWidth: CGFloat = 0
    let fileBrowser = CSXFileBrowser.initiate()
    @IBOutlet weak var fileBrowserView: NSView!
    
    let targetManager = CSXTargetManagerViewController.initiate()
    @IBOutlet weak var projectSettingView: NSView!
    var csxMake: CSXMake {
        get {
            return self.targetManager.csxMake
        }
    }
    @IBOutlet weak var makeLogView: NSView!

    let serialMonitor = SerialMonitorViewController.initiate()
    @IBOutlet weak var serialMonitorView: NSView!
    @IBOutlet weak var mainAreaTabView: NSTabView!
    let editorViewController = CSXTabViewController.initiate()
    var fileViewPackages = Set<FileViewPackage>()
    
    let webView = CSXWebViewController.initiate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        
        self.fileBrowserView.addSubViewWithQuickLayout(view: self.fileBrowser.view,
                                                       topDistance: 0, bottomDistance: 0, leadingDistance: 0, trailingDistance: 0,
                                                       options: [])
        self.fileBrowser.delegate = self
        // set in `Document`
//        self.fileBrowser.folderURL = URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Desktop")
        self.targetManager.delegate = self
        self.projectSettingView.addSubViewWithQuickLayout(view: self.targetManager.view,
                                                          topDistance: 0, bottomDistance: 0, leadingDistance: 0, trailingDistance: 0,
                                                          options: [])
        self.makeLogView.addSubViewWithQuickLayout(view: self.csxMake.makeLogViewController.view,
                                                   topDistance: 0, bottomDistance: 0, leadingDistance: 0, trailingDistance: 0,
                                                   options: [])
        self.serialMonitorView.addSubViewWithQuickLayout(view: self.serialMonitor.view,
                                                         topDistance: 0, bottomDistance: 0, leadingDistance: 0, trailingDistance: 0,
                                                         options: [])
        self.mainAreaTabView.addTabViewItem(NSTabViewItem(viewController: self.editorViewController))
        self.mainAreaTabView.addTabViewItem(NSTabViewItem(viewController: self.webView))
        self.mainAreaTabView.selectTabViewItem(at: 1)
    }
    
    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        ViewController.viewControllerCount += 1
        
        if WelcomeWindow.isWelcomeWindowShowed {
            AppDelegate.wc.close()
        }
        
        guard let document = self.document else {
            self.dismiss(self)
            return
        }
        if document.cmsxFile == nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                let panel = NSSavePanel()
                panel.canCreateDirectories = true
                panel.allowedFileTypes = ["com.camel.cmsx"]
                panel.allowsOtherFileTypes = false
                let window = self.view.window!
                panel.beginSheetModal(for: window) {  (response) in
                    guard response.rawValue == NSApplication.ModalResponse.OK.rawValue else {
                        self.view.window?.close()
                        return
                    }
                    
                    guard let url = panel.url else {
                        self.view.window?.close()
                        return
                    }
                    
                    let projectURL = url.deletingPathExtension()
                    let projectName = projectURL.lastPathComponent
                    let cmsxURL = projectURL.appendingPathComponent(projectName).appendingPathExtension("cmsx")
                    document.cmsxFile = CMSX(projectName: projectName,
                                             projectURL: projectURL, serialPortName: "", codeThemeName: "")
                    document.fileURL = cmsxURL
                    document.fileType = "com.camel.cmsx"
                    
                    guard let data = document.cmsxFile.data() else {
                        self.view.window?.close()
                        return
                    }
                    
                    do {
                        try FileManager.default.createDirectory(at: projectURL,
                                                                withIntermediateDirectories: true,
                                                                attributes: nil)
                        try data.write(to: cmsxURL)
                        self.loadDocumentToView()
                    } catch {
                        CSXLog.printLog("\(ViewController.self): \(error.localizedDescription)")
                        self.view.window?.close()
                        return
                    }
                }
            }
        } else {
            self.loadDocumentToView()
        }
    }
    
    func loadDocumentToView() {
        guard let document = self.document else {
            self.view.window?.close()
            return
        }
        if let url = document.fileURL {
            document.cmsxFile.checkAndCorrectTargets(correctProjectURL: url.deletingLastPathComponent())
        }
        
        for target in document.cmsxFile.targets {
            self.targetManager.addTarget(target)
        }
        self.fileBrowser.folderURL = document.cmsxFile.projectURL
        self.fileBrowser.start()    // Start up the fileBrowser!
        self.targetManager.defaultBuildFolder = document.cmsxFile.projectURL.appendingPathComponent("build")
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        ViewController.viewControllerCount -= 1
        if ViewController.viewControllerCount == 0{
            AppDelegate.wc.showWindow(self)
        }
    }
}

enum MainAreaButtonFunction: Int {
    case SidePanel = 0
    case NewProject = 1
    case OpenProject = 2
    case OpenExample = 3
    case SaveAll = 4
    case BuildTarget = 5
    case DownloadToChip = 6
    case CamelDocumentation = 7
    case Tutorial = 8
    case InstallSerialDriver = 9
    case OpenExtraSerialMonitor = 10
}
// MARK:- MainAreaButton Action
extension ViewController {
    // MARK:- IBOutlet Actions
    @IBAction func onSidePanelTabBar(_ sender: Any) {
        var index = 0
        if let sender = sender as? NSSegmentedControl {
            index = sender.selectedSegment
        } else if let sender = sender as? NSButton {
            index = sender.tag
            self.sidePanelTabBar.selectSegment(withTag: index)
        }
        
        self.sidePanelTabView.selectTabViewItem(at: index)
        if index != 1 && self.mainAreaTabView.numberOfTabViewItems > 1 {    // not target manager
            self.mainAreaTabView.selectTabViewItem(at: 1)
        }
    }
    @IBAction func onMainAreaButtons(_ sender: Any) {
        
        var index = 0
        if let sender = sender as? NSSegmentedControl {
            index = sender.selectedSegment
        } else if let sender = sender as? NSButton {
            index = sender.tag
        }
        
        guard let function = MainAreaButtonFunction(rawValue: index) else { return }
        switch function {
        case .SidePanel:
            self.switchSidePanel(nil)
        case .NewProject:
            self.newProject()
        case .OpenProject:
            self.openProject()
        case .OpenExample:
            self.openExample(sender)
        case .SaveAll:
            self.saveAll(nil)
        case .BuildTarget:
            self.buildTarget()
        case .DownloadToChip:
            self.downloadToChip()
        case .CamelDocumentation:
            self.openCamelDocumentation()
        case .Tutorial:
            self.openTutorial()
        case .InstallSerialDriver:
            self.installSerialDriver()
        case .OpenExtraSerialMonitor:
            self.openExtraSerialMonitor()
        }
    }
    @IBAction func switchSidePanel(_ sender: Any?) {
        let sidePanelView = self.viewSplitView.subviews[0]
        if self.viewSplitView.isSubviewCollapsed(sidePanelView) {
            // Show side panel
            sidePanelView.isHidden = false
            self.viewSplitView.setPosition(self.sidePanelViewWidth, ofDividerAt: 0)
            self.viewSplitView.adjustSubviews()
        } else {
            // Hide side panel
            self.sidePanelViewWidth = sidePanelView.frame.width
            self.viewSplitView.setPosition(0, ofDividerAt: 0)
            sidePanelView.isHidden = true
            self.viewSplitView.adjustSubviews()
        }
    }
    
    func newProject() {
        NSDocumentController.shared.newDocument(self)
    }
    
    func openProject() {
        NSDocumentController.shared.openDocument(self)
    }
    
    func openExample(_ sender: Any) {
        guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
        appDelegate.showExampleMenu(sender)
    }
    
    @IBAction func saveAll(_ sender: Any?) {
        self.document?.save(self)
        for package in self.fileViewPackages {
            self.fileBrowser.save(node: package.fileNode, content: package.codeViewController.textView.string)
        }
    }
    
    func buildTarget() {
        self.sidePanelTabBar.selectSegment(withTag: 1)
        self.onSidePanelTabBar(self.sidePanelTabBar)
        self.targetManager.onBuild(nil)
    }
    
    func downloadToChip() {
        self.sidePanelTabBar.selectSegment(withTag: 2)
        self.onSidePanelTabBar(self.sidePanelTabBar)
        guard let target = self.targetManager.getSelectedTarget() else {
            self.serialMonitor.progressInfo.stringValue = "ERROR: No target is selected!"
            return
        }
        guard let document = self.document else {
            self.serialMonitor.progressInfo.stringValue = "ERROR: Internal document is lost!"
            return
        }
        if document.cmsxFile.serialPortName.count > 0 && self.serialMonitor.selectedPort == nil {
            for port in ORSSerialPortManager.shared().availablePorts {
                if port.name == document.cmsxFile.serialPortName {
                    self.serialMonitor.selectedPort = port
                    break
                }
            }
        }
        guard self.serialMonitor.selectedPort != nil else {
            self.serialMonitor.progressInfo.stringValue = "ERROR: No serial port is selected!"
            return
        }
        guard target.targetAddress.count > 0 else {
            self.serialMonitor.progressInfo.stringValue = "ERROR: Target Address is empty!"
            return
        }
        self.serialMonitor.targetAddress.stringValue = "10000000"
        self.serialMonitor.binaryPath.stringValue = target.binaryURL.relativePath
        self.serialMonitor.onLoad(self)
    }
    
    @IBAction func openCamelDocumentation(_ sender: Any? = nil) {
        // switch to webView
        guard let documentationFolder = Bundle.main.url(forResource: "Documentation", withExtension: nil) else { return }
        self.mainAreaTabView.selectTabViewItem(at: 2)
        self.webView.loadURL(documentationFolder.appendingPathComponent("index.html"))
    }
    
    func openTutorial() {
        // switch to webView
        guard let tutorialURL = Bundle.main.url(forResource: "Tutorial.pdf", withExtension: nil) else { return }
        self.mainAreaTabView.selectTabViewItem(at: 2)
        self.webView.loadURL(tutorialURL)
    }
    
    func installSerialDriver() {
        SerialDriver.chooseInstaller()
    }
    
    func openExtraSerialMonitor() {
        SerialMonitorWindowController.initiate().showWindow(nil)
    }
}

extension ViewController: CSXFileBrowserDelegate {
    func fileBrowser(_ fileBrowser: CSXFileBrowser, encounter error: Error, message: String) {
        CSXLog.printLog(error.localizedDescription)
    }
    
    func fileBrowser(_ fileBrowser: CSXFileBrowser, processedFileTasks: Int, expectedFileTasks: Int) {
        CSXLog.printLog("\(processedFileTasks)/\(expectedFileTasks)")
    }
    
    func fileBrowser(_ fileBrowser: CSXFileBrowser, startWith url: URL) {
        CSXLog.printLog("\(ViewController.self):\(#line): FileBrowser Load from \(url.relativePath)")
    }
    
    func fileBrowser(_ fileBrowser: CSXFileBrowser, alreadyStartedWith url: URL) {
        CSXLog.printLog("\(ViewController.self):\(#line): FileBrowser Did load from \(url.relativePath)")
    }
    
    func fileBrowserSelectionDidChange(_ fileBrowser: CSXFileBrowser, notification: Notification) {
        CSXLog.printLog("\(ViewController.self):\(#line): FileBrowser Selection changed")
        if self.fileBrowser.selections.count == 1 {
            let fileNode = self.fileBrowser.selections.first!
            
            guard fileNode.nodeType != .Directory else { return }
            
            if fileNode.fileExtension == "cmsx" { // refuse to open cmsx
//                self.sidePanelTabBar.selectSegment(withTag: 1)
//                self.onSidePanelTabBar(self.sidePanelTabBar)
                return
            } else if fileNode.fileExtension == "bin" { // refuse to open binary
                return
            }
            
            for package in self.fileViewPackages {
                if package.fileNode == fileNode {
                    self.editorViewController.selectTab(id: package.tabID)
                    return
                } else if package.fileNode.url == fileNode.url {
                    // fileNode is updated! Because the filebrowser refreshes!
                    package.fileNode = fileNode
                    self.editorViewController.selectTab(id: package.tabID)
                    return
                }
            }
            guard let data = fileNode.data else { return }
            guard let content = String(data: data, encoding: .utf8) else {
                return
            }
            let codeViewController = CSXCodeViewController.initiate()
            codeViewController.loadView()
            codeViewController.textView.string = content
            let fileExtension = fileNode.fileExtension.lowercased()
            if fileExtension == "c" || fileExtension == "cpp" {
                codeViewController.textView.codeLanguage = "cpp"
            } else if fileExtension == "s" {
                codeViewController.textView.codeLanguage = "mipsasm"
            }
            let tabID = self.editorViewController.createNewTab(for: codeViewController,
                                                               tabTitle: fileNode.fullName,
                                                               tabImage: fileNode.icon,
                                                               tabSelectedHandler: nil, tabCloseHandler: {
                                                                tabID in
                                                                for package in self.fileViewPackages {
                                                                    if package.tabID == tabID {
                                                                        // save file
                                                                        self.fileBrowser.save(node: package.fileNode,
                                                                                              content: package.codeViewController.textView.string)
                                                                        // remove package
                                                                        self.fileViewPackages.remove(package)
                                                                    }
                                                                }
            })
            self.fileViewPackages.insert(FileViewPackage(tabID: tabID,
                                                         fileNode: fileNode,
                                                         codeViewController: codeViewController))
        }
    }
    
    func fileBrowser(_ fileBrowser: CSXFileBrowser, didRename oldURL: URL, to newFileNode: FileNode) {
        for package in self.fileViewPackages {
            if package.fileNode.url.relativePath == oldURL.relativePath {
                self.editorViewController.updateTabTitle(tabID: package.tabID, newTitle: newFileNode.fullName)
                package.fileNode = newFileNode
                return
            }
        }
    }
    
    func fileBrowser(_ fileBrowser: CSXFileBrowser, didDelete fileNode: FileNode) {
        for package in self.fileViewPackages {
            if package.fileNode.url.relativePath == fileNode.url.relativePath {
                self.fileViewPackages.remove(package)
                self.editorViewController.closeTab(id: package.tabID)
                return
            }
        }
    }
    
    func fileBrowser(_ fileBrowser: CSXFileBrowser, didDetectFileChange file: URL) {
        fileBrowser.refreshFromDisk()
        for package in self.fileViewPackages {
            if package.fileNode.url.relativePath == file.relativePath {
                guard let tabViewItem = self.editorViewController.tabViewItem(for: package.tabID) else {
                    CSXLog.printLog("\(ViewController.self):\(#line): Fail to get the tabViewTem for \(file.relativePath)")
                    return
                }
                guard let vc = tabViewItem.viewController as? CSXCodeViewController else {
                    CSXLog.printLog("\(ViewController.self):\(#line): Fail to get the viewController for \(file.relativePath)")
                    return
                }
                guard let newContent = try? String(contentsOf: file) else {
                    CSXLog.printLog("\(ViewController.self):\(#line): Fail to read from \(file.relativePath)")
                    return
                }
                vc.textView.string = newContent
                return
            }
        }
    }
}

extension ViewController: CSXTargetManagerViewControllerDelegate {
    
    func csxTargetManagerWillBuildTarget(_ targetManager: CSXTargetManagerViewController) {
        self.mainAreaTabView.selectTabViewItem(at: 0)
    }
    
    func csxTargetManagerDidBuildTarget(_ targetManager: CSXTargetManagerViewController) {
        self.fileBrowser.refreshFromDisk()
        self.fileBrowser.start()
    }
}
