//
//  FileBrowserScrollView
//  CSXFileBrowser
//
//  Created by Zhirui Dai on 2018/6/27.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

public class CSXFileBrowser: NSViewController {
    
    public static var printLog: ((String) -> Void)?
    
    public static func initiate() -> CSXFileBrowser {
        return CSXFileBrowser.init(nibName: NSNib.Name("CSXFileBrowser"), bundle: Bundle(for: CSXFileBrowser.self))
    }
    
    private static let fileProcessQueue = DispatchQueue(label: "\(Bundle.main.bundleIdentifier!).fileBrowser")
    private static var fileProcessArray = [()->Void]()
    private static var expectedFileTasks = 0    // for informing the delegate the progress
    private static func processNextFile() {
        if CSXFileBrowser.fileProcessArray.count > 0 {
            let task = CSXFileBrowser.fileProcessArray.removeFirst()
            CSXFileBrowser.fileProcessQueue.async {
                task()
            }
        } else {
            CSXFileBrowser.expectedFileTasks = 0
        }
    }
    
    var diskMonitor: Witness?
    var sendFileEventToDelegate = false
    
    public var itemViewHeight = 24 as CGFloat
    public var fileManager: CSXFileManager?
    public var delegate: CSXFileBrowserDelegate?
    public var folderURL: URL? {
        didSet {
            if let url = self.folderURL {
                DispatchQueue.main.async {
                    self.diskMonitor = Witness(paths: [url.relativePath], flags: .FileEvents, latency: 0.3, changeHandler: {
                        (fileEvents) in
                        for fileEvent in fileEvents {
                            CSXFileBrowser.printLog?("\(CSXFileBrowser.self):\(#line): FileEvent[flags: \(fileEvent.flags), path: \(fileEvent.path) ]")
                            if self.sendFileEventToDelegate {
                                DispatchQueue.main.async {
                                    self.delegate?.fileBrowser?(self, didDetectFileChange: URL(fileURLWithPath: fileEvent.path))
                                }
                            }
                        }
                    })
                    self.sendFileEventToDelegate = true
                }
            }
            
            self.refreshFromDisk()
        }
    }
    public var selections = [FileNode]()
    @IBOutlet weak var headerView: NSTableHeaderView!
    @IBOutlet public weak var outlineView: FileBrowserOutlineView!
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        self.outlineView.browser = self
        self.outlineView.delegate = self
        self.outlineView.dataSource = self
        self.outlineView.autosaveExpandedItems = true
        self.outlineView.autosaveName = "daizhirui.CSXFileBrowser"
        self.outlineView.selectionHighlightStyle = .sourceList
    }
    
    // MARK:- expansion
    var expandedItem = [String : FileNode]()
    private func restoreExpansion() {
        DispatchQueue.main.async {
            for (_, item) in self.expandedItem {
                self.outlineView.expandItem(item)
            }
        }
    }
    
//    override public func draw(_ dirtyRect: NSRect) {
//        super.draw(dirtyRect)
//    }
    
    // MARK:- Refresh
    @IBAction func __refreshFromDisk(_ sender: Any) {
        self.refreshFromDisk()
        self.start()
    }
    public func refreshFromDisk() {
        guard let url = self.folderURL else { return }
        
        var isFolder: ObjCBool = false
        if FileManager.default.fileExists(atPath: url.relativePath, isDirectory: &isFolder), isFolder.boolValue {
            
            CSXFileBrowser.fileProcessArray.append {
                // initialize fileManager
                DispatchQueue.main.async {
                    self.delegate?.fileBrowser?(self, startWith: url)
                }
                guard let url = self.folderURL else { return }
                let fileManager = CSXFileManager(rootURL: url)
                fileManager?.nodeAlreadyExistsHandler = {
                    node in
                    let alert = NSAlert()
                    alert.messageText = "\(node.fullName) already exists!"
                    guard let window = self.view.window else { return }
                    alert.beginSheetModal(for: window, completionHandler: nil)
                }
                
                self.fileManager = fileManager
                // initialize view
                DispatchQueue.main.async {
                    while self.headerView == nil {}
                    
                    let label = NSTextField(labelWithString: url.lastPathComponent)
                    label.drawsBackground = false
                    
                    let imageView = NSImageView(image: NSWorkspace.shared.icon(forFile: url.relativePath))
                    let visualEffectView = NSVisualEffectView(frame: self.headerView.bounds)
                    visualEffectView.blendingMode = .behindWindow
                    visualEffectView.material = .mediumLight
                    
                    self.headerView.subviews.removeAll()
                    self.headerView.addSubViewWithQuickLayout(view: visualEffectView, topDistance: 1, bottomDistance: 1,
                                                              leadingDistance: 0, trailingDistance: 0, options: [])
                    
                    self.headerView.addSubViewWithQuickLayout(view: imageView, topDistance: 2, bottomDistance: 2,
                                                              leadingDistance: 5, trailingDistance: nil, options: [.squre])
                    self.headerView.addSubViewWithQuickLayout(view: label, topDistance: 3, bottomDistance: 1,
                                                              leadingDistance: 5 + imageView.frame.width + 15,
                                                              trailingDistance: 10, options: [] )
                    self.refresh(nil)
                    self.delegate?.fileBrowser?(self, alreadyStartedWith: url)
                }
            }
            CSXFileBrowser.processNextFile()
            
        } // End of if
    }
    
    @IBAction public func showInFinder(_ sender: Any) {
        guard let node = self.nodeForCurrentSelection() else { return }
        NSWorkspace.shared.activateFileViewerSelecting([node.url])
    }
    
    @IBAction public func refresh(_ sender: Any?) {
        let selections = self.outlineView.selectedRowIndexes
        self.outlineView.reloadData()
        self.outlineView.selectRowIndexes(selections, byExtendingSelection: true)
    }
    
    // MARK:- Selection
    var mouseOnRow = false
    func currentSelection() -> (row: Int, column: Int) {
        return (self.outlineView.selectedRow, self.outlineView.selectedColumn)
    }
    /// Return the `FileItemView` of current selection
    func viewForCurrentSelection() -> FileItemView? {
        if self.outlineView.selectedRow < 0 { return nil }
        return self.outlineView.view(atColumn: self.outlineView.selectedColumn, row: self.outlineView.selectedRow, makeIfNecessary: false) as? FileItemView
    }
    func nodeForCurrentSelection() -> FileNode? {
        if let node = self.outlineView.item(atRow: self.outlineView.selectedRow) as? FileNode {
            return node
        } else {
            return self.fileManager?.rootNode
        }
    }
    func nodesForCurrentSelectedIndecies() -> [FileNode] {
        var array = [FileNode]()
        let indecies = self.outlineView.selectedRowIndexes
        for index in indecies {
            if let descriptor = self.outlineView.item(atRow: index) as? FileNode {
                array.append(descriptor)
            }
        }
        return array
    }
}

// MARK:- File Access
extension CSXFileBrowser {
    
    public func start() {
        CSXFileBrowser.processNextFile()
    }
    
    public func open(node: FileNode) -> String? {
        guard let data = node.data else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    public func save(node: FileNode, content: String) {
        self.sendFileEventToDelegate = false
        guard let data = content.data(using: .utf8) else {
            return
        }
        node.data = data
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.sendFileEventToDelegate = true
        }
    }
}

// MARK:- UI Action
extension CSXFileBrowser {
    public override func mouseEntered(with event: NSEvent) {
        self.mouseOnRow = true
        super.mouseEntered(with: event)
    }
    
    public override func mouseExited(with event: NSEvent) {
        self.mouseOnRow = false
        super.mouseEntered(with: event)
    }
    
    @IBAction func fileNameEditedAction(_ sender: NSTextField) {  // rename action
        guard let fileItemView = sender.superview as? FileItemView else { return }
        let oldURL = fileItemView.fileNode.url
        let newURL = oldURL.deletingLastPathComponent().appendingPathComponent(sender.stringValue)
        
        if oldURL != newURL {
            self.fileManager?.moveItem(at: oldURL, to: newURL)
            guard let newNode = self.fileManager?.nodeList[newURL.relativePath] else {
                CSXFileBrowser.printLog?("\(CSXFileBrowser.self):\(#line): Node \(newURL.relativePath) is not found yet.")
                return
            }
            
            fileItemView.fileNode = newNode
            
            self.delegate?.fileBrowser?(self, didRename: oldURL, to: newNode)
        }
    }
    
    var fileBrowserMenu: FileBrowserMenu! {
        get {
            return self.outlineView.menu as? FileBrowserMenu
        }
    }
    
    private func newItem(type: FileNode.NodeType) {
        guard let node = self.nodeForCurrentSelection() else { return }
        let parentNode: FileNode
        if node.nodeType == .Directory {
            parentNode = node
        } else {
            guard let unwrappedParentNode = node.parentNode else { return }
            parentNode = unwrappedParentNode
        }
        let nameVC = RequireNameViewController.initiate()
        nameVC.loadView()
        nameVC.viewDidLoad()
        nameVC.tipLabel.stringValue = "Enter the name for the new \(type.rawValue):"
        nameVC.okHandler = {
            (name: String) in
            let newNodeURL = parentNode.url.appendingPathComponent(name)
            if type == .Directory {
                if self.fileManager?.createDirectory(at: newNodeURL,
                                                     withIntermediateDirectories: true,
                                                     attributes: nil) != true {
                    CSXFileBrowser.printLog?("\(CSXFileBrowser.self):\(#line): Fail to create directory \(name)")
                }
            } else if type == .File {
                if self.fileManager?.createFile(atURL: newNodeURL,
                                                contents: nil, attributes: nil) != true {
                    CSXFileBrowser.printLog?("\(CSXFileBrowser.self):\(#line): Fail to create directory \(name)")
                }
            } else {
                return
            }
            
            guard let newNode = self.fileManager?.nodeList[newNodeURL.relativePath] else {
                CSXFileBrowser.printLog?("\(CSXFileBrowser.self):\(#line): Node \(node.url.relativePath) is not found yet.")
                return
            }
            
            self.refresh(nil)

            self.outlineView.expandItem(parentNode)
            self.outlineView.selectRowIndexes([self.outlineView.row(forItem: newNode)], byExtendingSelection: false)
        }
        
        self.presentAsSheet(nameVC)
    }
    @IBAction func newFolderAction(_ sender: Any) {
        self.newItem(type: .Directory)
    }
    @IBAction func newFileAction(_ sender: Any) {
        self.newItem(type: .File)
    }
    @IBAction func renameItemAction(_ sender: Any) {
        guard let view = self.viewForCurrentSelection() else { return }
        view.textField?.selectText(nil)
    }
    @IBAction func deleteItemAction(_ sender: Any) {
        let nodes = self.nodesForCurrentSelectedIndecies()
        ConfirmDeletionViewController.applyToAll = false
        for node in nodes {
            CSXFileBrowser.fileProcessArray.append {
                let deletionVC = ConfirmDeletionViewController.initiate()
               
                // setup messages to show
                DispatchQueue.main.async {
                    deletionVC.loadView()
                    deletionVC.viewDidLoad()
                    deletionVC.applyToAllButton.isHidden = (nodes.count <= 1)
                    deletionVC.confirmationTextLine1.stringValue = "Do you really want to delete:"
                    deletionVC.confirmationTextLine2.stringValue = "\(node.fullName) ?"
                }
                // setup okhandler
                deletionVC.okHandler = {
                    if self.fileManager?.deleteItem(at: node.url) != true {
                        CSXFileBrowser.printLog?("\(CSXFileBrowser.self):\(#line): Fail to delete \(node.url.relativePath)")
                    }
                    self.delegate?.fileBrowser?(self, didDelete: node)
                    DispatchQueue.main.async {
                        for index in self.outlineView.selectedRowIndexes {
                            self.outlineView.deselectRow(index)
                        }
                        self.refresh(nil)
                        self.delegate?.fileBrowser?(self, processedFileTasks: CSXFileBrowser.expectedFileTasks - CSXFileBrowser.fileProcessArray.count, expectedFileTasks: CSXFileBrowser.expectedFileTasks)
                        
                        CSXFileBrowser.processNextFile()
                    }
                }
                // setup presentHandler
                deletionVC.presentHandler = {
                    self.presentAsSheet(deletionVC)
                }
                // start
                DispatchQueue.main.async {
                    deletionVC.present()
                }
            }
            CSXFileBrowser.expectedFileTasks += 1
        }
        CSXFileBrowser.processNextFile()
    }
    
    @IBAction func addItemAction(_ sender: Any) {
        guard let node = self.nodeForCurrentSelection() else { return }
        let parentNodeURL: URL
        if node.nodeType == .Directory {
            parentNodeURL = node.url
        } else {
            guard let parentNode = node.parentNode else { return }
            parentNodeURL = parentNode.url
        }
        guard let parentNode = self.fileManager?.nodeList[parentNodeURL.relativePath] else { return }
        
        let openFileDlg = NSOpenPanel()
        openFileDlg.canChooseFiles = true
        openFileDlg.canChooseDirectories = true
        openFileDlg.allowsMultipleSelection = true
        guard let unwrappedWindow = NSApp.mainWindow else { return }

        openFileDlg.beginSheetModal(for: unwrappedWindow) {
            result in
            
            if (result.rawValue == NSApplication.ModalResponse.OK.rawValue) {
                let fileURLs = openFileDlg.urls
                
                for url in fileURLs {
                    
                    CSXFileBrowser.fileProcessArray.append {
                        let newURL = parentNodeURL.appendingPathComponent(url.lastPathComponent)
                        
                        self.fileManager?.nodeAlreadyExistsHandler = {
                            node in
                            
                            let additionVC = ConfirmAdditionViewController.initiate()
                            
                            DispatchQueue.main.async {
                                additionVC.loadView()
                                additionVC.viewDidLoad()
                                // setup messages
                                additionVC.confirmationTextLine1.stringValue = "\(url.lastPathComponent) already exists:"
                                additionVC.confirmationTextLine2.stringValue = "Do you want to replace, keep both or skip?"
                            }
                            // setup replace handler
                            additionVC.replaceHandler = {
                                self.fileManager?.deleteItem(at: node.url)
                                self.fileManager?.copyItem(at: url, to: node.url)
                                return self.fileManager?.nodeList[node.url.relativePath]
                            }
                            // setup keep both handler
                            additionVC.keepBothHandler = {
                                var newURL = node.url
                                var index = 1
                                while self.fileManager?.nodeList.keys.contains(newURL.relativePath) == true {
                                    newURL = node.url.deletingLastPathComponent().appendingPathComponent("\(node.name)-\(index)\(node.fileExtension)")
                                    index += 1
                                }
                                
                                self.fileManager?.copyItem(at: url, to: newURL)
                                
                                return self.fileManager?.nodeList[newURL.relativePath]
                            }
                            // setup skip handler
                            additionVC.skipHandler = { self.refresh(nil) }
                            // setup success handler
                            additionVC.successHandler = {
                                (node) in
                                DispatchQueue.main.async {
                                    self.outlineView.expandItem(node)
                                    self.outlineView.selectRowIndexes(IndexSet(arrayLiteral: self.outlineView.row(forItem: node)),
                                                                      byExtendingSelection: true)
                                    
                                    self.refresh(nil)
                                }
                                CSXFileBrowser.processNextFile()
                            }
                            // start!
                            DispatchQueue.main.async {
                                self.view.window?.contentViewController?.presentAsSheet(additionVC)
                            }
                        }
                        
                        if self.fileManager?.copyItem(at: url, to: newURL) == true {
                            DispatchQueue.main.async {
                                self.outlineView.expandItem(parentNode)
                                if let newNode = self.fileManager?.nodeList[newURL.relativePath] {
                                    self.outlineView.selectRowIndexes(IndexSet(arrayLiteral: self.outlineView.row(forItem: newNode)),
                                                                      byExtendingSelection: true)
                                }
                                self.refresh(nil)
                                self.delegate?.fileBrowser?(self, processedFileTasks: CSXFileBrowser.expectedFileTasks - CSXFileBrowser.fileProcessArray.count, expectedFileTasks: CSXFileBrowser.expectedFileTasks)
                            }
                        } else {
                            CSXFileBrowser.printLog?("\(CSXFileBrowser.self):\(#line): Fail to copy \(url.relativePath) to \(newURL.relativePath)")
                        }
                        
                        CSXFileBrowser.processNextFile()
                    } // End of closure
                    
                    CSXFileBrowser.expectedFileTasks += 1
                }// End of for
                CSXFileBrowser.processNextFile()
            } // End of if
            openFileDlg.endSheet(unwrappedWindow)
        }
    }
}

// MARK:- NSOutlineViewDataSource
extension CSXFileBrowser: NSOutlineViewDataSource {
    // MARK:- Information for generating file items in file browser
    public func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        
        guard let manager = self.fileManager else { return 0 }
        
        let node: FileNode
        
        if let unwrappedNode = item as? FileNode {
            node = unwrappedNode
        } else {
            guard let rootNode = manager.rootNode else { return 0 }
            node = rootNode
        }
        
        CSXFileBrowser.printLog?("\(CSXFileBrowser.self):\(#line): Enter folder\(node.url.relativePath), childrenNumber: \(node.numberOfChildren)")
        return node.numberOfChildren
    }
    
    public func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        guard let node = item as? FileNode else { return false }
        return node.nodeType == .Directory
    }
    // node for an item
    public func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        
        guard let manager = self.fileManager else { return 0 as Any }
        let parentNode: FileNode
        if let node = item as? FileNode {   // require child node directly
            parentNode = node
        } else {                            // require root node at first
            guard let root = manager.rootNode else { return 0 as Any }
            CSXFileBrowser.printLog?("\(CSXFileBrowser.self):\(#line): Get Root: \(root.url.relativePath)")
            parentNode = root
        }
        
        let childNodes = parentNode.childNodes.sorted(by: { (node1, node2) -> Bool in
            return node1.url.relativePath < node2.url.relativePath
        })
        return childNodes[index]
    }
    // MARK:- Drag-Drop
    // Allow dragging
    public func outlineView(_ outlineView: NSOutlineView, validateDrop info: NSDraggingInfo, proposedItem item: Any?, proposedChildIndex index: Int) -> NSDragOperation {
        return NSDragOperation.every
    }
    // Store the data of dragged item to the pasteboard
    /// This function supports multi-drag
    public func outlineView(_ outlineView: NSOutlineView, pasteboardWriterForItem item: Any) -> NSPasteboardWriting? {
        
        guard let node = item as? FileNode else { return nil }
        let propertyList = NSMutableDictionary(capacity: 1)
        propertyList.addEntries(from: ["Item" : node.url as Any])  // dragged item
        
        guard let pasteboardItem = NSPasteboardItem(pasteboardPropertyList: propertyList, ofType: .CSXFileBrowserPasteboardType)
            else { return nil }
        return pasteboardItem
    }
    /// This function accepts drop
    public func outlineView(_ outlineView: NSOutlineView, acceptDrop info: NSDraggingInfo, item: Any?, childIndex index: Int) -> Bool {
        
        guard let manager = self.fileManager else { return false }
        
        let destNode: FileNode
        if let node = item as? FileNode {
            destNode = node
        } else {    // root node
            guard let node = manager.rootNode else { return false }
            destNode = node
        }
        
        let pasteboard = info.draggingPasteboard
        guard let pasteboardItems = pasteboard.pasteboardItems else {
            return false
        }
        for pasteboardItem in pasteboardItems {
            guard let propertyList = pasteboardItem.propertyList(forType: .CSXFileBrowserPasteboardType) as? NSDictionary
                else { return false }
            guard let nodeURL = propertyList.value(forKey: "Item") as? URL else { return false }
            manager.moveItem(at: nodeURL, to: destNode.url.appendingPathComponent(nodeURL.lastPathComponent))
        }
        
        self.refresh(nil)
        self.restoreExpansion()
        
        return true
    }
}

// MARK:- NSOutlineViewDelegate
extension CSXFileBrowser: NSOutlineViewDelegate {
    // MARK:- Provide view to show
    public func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let identifier = tableColumn?.identifier else { return nil }
        guard let node = item as? FileNode else { return nil }
        guard let view = outlineView.makeView(withIdentifier: identifier, owner: self) as? FileItemView else { return nil }
        view.fileNode = node    // FileItemView will auto-setup the view.
        self.itemViewHeight = view.frame.height
        
        view.textField?.action = #selector(self.fileNameEditedAction(_:))
        
        let trackArea = NSTrackingArea(rect: view.frame, options: [.activeAlways, .mouseEnteredAndExited], owner: self, userInfo: ["object":view])
        view.addTrackingArea(trackArea)
        CSXFileBrowser.printLog?("\(CSXFileBrowser.self):\(#line): View generated for \(node.url.relativePath)")
        return view
    }
    public func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        return self.itemViewHeight
    }
    // MARK:- Selection
    public func outlineView(_ outlineView: NSOutlineView, selectionIndexesForProposedSelection proposedSelectionIndexes: IndexSet) -> IndexSet {
        guard let browserOutlineView = outlineView as? FileBrowserOutlineView else {
            CSXFileBrowser.printLog?("\(CSXFileBrowser.self):\(#line): The outlineview is not FileBrowserOutlineView!")
            return proposedSelectionIndexes
        }
        var newIndexSet = proposedSelectionIndexes
        if browserOutlineView.commandKeyPressed {
            newIndexSet.formUnion(outlineView.selectedRowIndexes)
            browserOutlineView.isMultiSelecting = true
            return newIndexSet
        } else {
            browserOutlineView.isMultiSelecting = false
            _ = newIndexSet.union(outlineView.selectedRowIndexes)
            return newIndexSet
        }
    }
    public func outlineViewSelectionIsChanging(_ notification: Notification) {
        self.delegate?.fileBrowserSelectionIsChanging?(self, notification: notification)
    }
    public func outlineViewSelectionDidChange(_ notification: Notification) {
        guard let browserOutlineView = notification.object as? FileBrowserOutlineView else {
//            CSXFileBrowser.printLog?("\(CSXFileBrowser.self):\(#line): The outlineview is not FileBrowserOutlineView!")
            return
        }
        let indexSet = browserOutlineView.selectedRowIndexes
        var nodes = [FileNode]()
        for index in indexSet {
            if let node = browserOutlineView.item(atRow: index) as? FileNode {
                nodes.append(node)
            }
        }
        self.selections = nodes
        // call delegate
        self.delegate?.fileBrowserSelectionDidChange?(self, notification: notification)
    }
    
    // MARK:- Expansion
    // reload expaned item when the app is launching
    public func outlineView(_ outlineView: NSOutlineView, itemForPersistentObject object: Any) -> Any? {
        // to reload all expaned items, fileManager and its nodeList should be prepared.
        var timeout = 1000000
        while self.fileManager == nil, timeout > 0 { timeout -= 1 }
        while FileNode.operationCount > 0, timeout > 0 { timeout -= 1 }    // wait for all nodes loaded
        
        // get saved object
        guard let data = object as? Data else { return nil }
        guard let path = String(data: data, encoding: .utf8) else { return nil }
        let url = URL(fileURLWithPath: path)
        let node = self.fileManager?.nodeList[url.relativePath]
        return node
    }
    // save expanded item, for the next time when the app is opened
    public func outlineView(_ outlineView: NSOutlineView, persistentObjectForItem item: Any?) -> Any? {
        // get file node
        guard let node = item as? FileNode else { return 0 as Any }
        return node.url.relativePath.data(using: .utf8)
    }
    // record expansion
    public func outlineViewItemDidExpand(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        guard let node = userInfo["NSObject"] as? FileNode else { return }
        self.expandedItem[node.url.relativePath] = node //self.outlineView.row(forItem: descriptor)
    }
    public func outlineViewItemDidCollapse(_ notification: Notification) {
        guard let node = notification.object as? FileNode else { return }
        _ = self.expandedItem.removeValue(forKey: node.url.relativePath)
    }
}



