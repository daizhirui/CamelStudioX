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
    @IBOutlet weak var sidePanelTabView: NSTabView!
    let PROJECT_FILES_TAB = 0
    let SERIAL_MONITOR_TAB = 1
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
    let PROJECT_SETTINGS_TAB = 0
    let CSXMAKE_LOG_TAB = 1
    let EDITOR_TAB = 2
    let editorViewController = CSXTabViewController.initiate()
    var fileViewPackages = Set<FileViewPackage>()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        // setup file browser
        self.fileBrowserView.addSubViewWithQuickLayout(view: self.fileBrowser.view,
                                                       topDistance: 0, bottomDistance: 0, leadingDistance: 0, trailingDistance: 0,
                                                       options: [])
        self.fileBrowser.delegate = self
        // set in `Document`
//        self.fileBrowser.folderURL = URL(fileURLWithPath:NSHomeDirectory()).appendingPathComponent("Desktop")
        // setup serial monitor
        self.serialMonitorView.addSubViewWithQuickLayout(view: self.serialMonitor.view,
                                                         topDistance: 0, bottomDistance: 0, leadingDistance: 0, trailingDistance: 0,
                                                         options: [])
        // setup project settings
        self.targetManager.delegate = self
        self.projectSettingView.addSubViewWithQuickLayout(view: self.targetManager.view,
                                                          topDistance: 0, bottomDistance: 0, leadingDistance: 0, trailingDistance: 0,
                                                          options: [])
        // setup csxmake log
        self.makeLogView.addSubViewWithQuickLayout(view: self.csxMake.makeLogViewController.view,
                                                   topDistance: 0, bottomDistance: 0, leadingDistance: 0, trailingDistance: 0,
                                                   options: [])
        
        self.mainAreaTabView.addTabViewItem(NSTabViewItem(viewController: self.editorViewController))
        // 0: project setting
        // 1: make log
        // 2: editor
        // 3: webview
        self.mainAreaTabView.selectTabViewItem(at: self.EDITOR_TAB)
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
            CSXLog.printLog("\(#file), \(#function): Failed to fetch the document instance!\n")
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
        self.targetManager.projectName = document.cmsxFile.projectName
    }
    
    override func viewDidDisappear() {
        super.viewDidDisappear()
        ViewController.viewControllerCount -= 1
        if ViewController.viewControllerCount == 0{
            AppDelegate.wc.showWindow(self)
        }
    }
}

enum ToolBarFunction: Int {
    case ProjectFiles = 0
    case SerialMonitor = 1
    case SidePanel = 2
    case NewProject = 3
    case OpenProject = 4
    case OpenExample = 5
    case ProjectSettings = 6
    case SaveAll = 7
    case BuildTarget = 8
    case DownloadToChip = 9
    case Documentations = 10
    case Help = 11
    case InstallSerialDriver = 12
}
// MARK:- MainAreaButton Action
extension ViewController {
    // MARK:- IBOutlet Actions
    @IBAction func onToolBarButtons(_ sender: Any) {
        guard let sender = sender as? NSButton else { return }
        let index = sender.tag

        guard let function = ToolBarFunction(rawValue: index) else {
            CSXLog.printLog("\(#function): Wrong Toolbar Button Tag: \(index)")
            return
        }
        
        switch function {
        case .ProjectFiles:
            self.sidePanelTabView.selectTabViewItem(at: self.PROJECT_FILES_TAB)
        case .SerialMonitor:
            self.sidePanelTabView.selectTabViewItem(at: self.SERIAL_MONITOR_TAB)
        case .SidePanel:
            self.switchSidePanel(nil)
        case .NewProject:
            self.newProject()
        case .OpenProject:
            self.openProject()
        case .OpenExample:
            self.openExample(sender)
        case .ProjectSettings:
            self.mainAreaTabView.selectTabViewItem(at: self.PROJECT_SETTINGS_TAB)
        case .SaveAll:
            self.saveAll(nil)
        case .BuildTarget:
            self.buildTarget()
        case .DownloadToChip:
            self.downloadToChip()
        case .Documentations:
            (NSApplication.shared.delegate as! AppDelegate).openCamelDocumentation(nil)
        case .Help:
            (NSApplication.shared.delegate as! AppDelegate).openHelp(nil)
        case .InstallSerialDriver:
            self.installSerialDriver()
        
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
            // set the view hidden at first to inactivate the constraints of views in the left panel
            sidePanelView.isHidden = true
            self.viewSplitView.setPosition(0, ofDividerAt: 0)
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
        self.targetManager.onBuild(nil)
    }
    
    func downloadToChip() {
        self.sidePanelTabView.selectTabViewItem(at: self.SERIAL_MONITOR_TAB)
        guard let target = self.targetManager.getSelectedTarget() else {
            self.serialMonitor.progressInfo.stringValue = "ERROR: No target is selected!"
            InfoAndAlert.shared.showAlertWindow(type: .alert, title: "Error Occurred", message: "No target is selected!")
            return
        }
        guard let document = self.document else {
            self.serialMonitor.progressInfo.stringValue = "ERROR: Internal document is lost!"
            InfoAndAlert.shared.showAlertWindow(type: .alert, title: "Error Occurred", message: "Internal document is lost!")
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
            InfoAndAlert.shared.showAlertWindow(type: .alert, title: "Error Occurred", message: "No serial port is selected!")
            return
        }
        guard target.targetAddress.count > 0 else {
            self.serialMonitor.progressInfo.stringValue = "ERROR: Target Address is empty!"
            InfoAndAlert.shared.showAlertWindow(type: .alert, title: "Error Occurred", message: "Target Address is empty!")
            return
        }
        self.serialMonitor.targetAddress.stringValue = "10000000"
        self.serialMonitor.binaryPath.stringValue = target.binaryURL.relativePath
        self.serialMonitor.onLoad(self)
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
            
            if fileNode.fileExtension == "cmsx" { // refuse to open cmsx, open project settings instead
                self.mainAreaTabView.selectTabViewItem(at: self.PROJECT_SETTINGS_TAB)
                return
            } else if fileNode.fileExtension == "bin" { // refuse to open binary
                return
            }
            
            for package in self.fileViewPackages {
                var shouldReturn = false
                if package.fileNode == fileNode {
                    shouldReturn = true
                } else if package.fileNode.url == fileNode.url {
                    // fileNode is updated! Because the filebrowser refreshes!
                    package.fileNode = fileNode
                    shouldReturn = true
                }
                if shouldReturn {
                    self.editorViewController.selectTab(id: package.tabID)
                    self.mainAreaTabView.selectTabViewItem(at: EDITOR_TAB)
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
            self.mainAreaTabView.selectTabViewItem(at: self.EDITOR_TAB)
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
        self.fileBrowser.outlineView.deselectAll(nil)
        self.mainAreaTabView.selectTabViewItem(at: self.CSXMAKE_LOG_TAB)
    }
    
    func csxTargetManagerDidBuildTarget(_ targetManager: CSXTargetManagerViewController) {
        self.fileBrowser.refreshFromDisk()
        self.fileBrowser.start()
    }
}
