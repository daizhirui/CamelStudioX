//
//  FileBrowserOutlineView.swift
//  CSXFileBrowser
//
//  Created by Zhirui Dai on 2018/6/28.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

public class FileBrowserOutlineView: NSOutlineView {

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        self.allowsMultipleSelection = true
        self.autosaveExpandedItems = true
        // very important. This makes drag-drop allowed.
        self.registerForDraggedTypes([.CSXFileBrowserPasteboardType])
        // connect menu
        self.menu = FileBrowserMenu.loadFromXib()
    }
    
    public var isMultiSelecting = false
    public var commandKeyPressed = false
    var browser: CSXFileBrowser?
    
    public override func keyDown(with event: NSEvent) {
        if event.keyCode == 51 {    // delete
            self.browser?.deleteItemAction(self)
        }
        
        super.keyDown(with: event)
    }
    
    override public func mouseDown(with event: NSEvent) {
        self.commandKeyPressed = event.modifierFlags.contains(.command)
        super.mouseDown(with: event)
    }
    
    public override func rightMouseDown(with event: NSEvent) {
        
        guard let browser = self.browser else { return }
        guard let manager = browser.fileManager else { return }
        
        if let selectedNode = self.item(atRow: self.selectedRow) as? FileNode {
            guard let parent = selectedNode.parentNode else { return }
            
            // check mouse position
            if browser.mouseOnRow { // operation on node
                if selectedNode.nodeType == .Directory {
                    self.updateMenuForOperationOnNode(nodeName: selectedNode.fullName, folderNodeName: selectedNode.fullName)
                } else {
                    self.updateMenuForOperationOnNode(nodeName: selectedNode.fullName, folderNodeName: parent.fullName)
                }
            } else {    // operation on root
                self.updateMenuForOperationOnRoot(rootNodeName: browser.fileManager?.rootNode.fullName ?? "")
            }
            
        } else {    // root node
            guard let rootNode = manager.rootNode else { return }
            self.updateMenuForOperationOnRoot(rootNodeName: rootNode.fullName)
        }
        super.rightMouseDown(with: event)
    }
    /// Update the title of every menu
    private func updateMenuForOperationOnNode(nodeName: String, folderNodeName: String) {
        guard let menu = self.menu as? FileBrowserMenu else { return }
        
        menu.addFilesMenuItem.title = "Add Files to \"\(folderNodeName)\"..."
        menu.addFilesMenuItem.isEnabled = true
        menu.renameMenuItem.title = "Rename \"\(nodeName)\""
        menu.renameMenuItem.isEnabled = true
        menu.deleteMenuItem.title = "Delete \"\(nodeName)\""
        menu.deleteMenuItem.isEnabled = true
        if self.numberOfSelectedRows > 1 {   // more than one row are selected
            menu.renameMenuItem.title = "Rename"
            menu.renameMenuItem.isEnabled = false
            menu.deleteMenuItem.title = "Delete \(self.numberOfSelectedRows) files or folders"
            menu.deleteMenuItem.isEnabled = true
        }
    }
    
    private func updateMenuForOperationOnRoot(rootNodeName: String) {
        guard let menu = self.menu as? FileBrowserMenu else { return }
        
        if rootNodeName.count > 1 {
            menu.addFilesMenuItem.title = "Add Files to \"\(rootNodeName)\"..."
        } else {
            menu.addFilesMenuItem.title = "Add Files..."
        }
        
        menu.renameMenuItem.title = "Rename"
        menu.renameMenuItem.isEnabled = false
        menu.deleteMenuItem.title = "Delete"
        menu.deleteMenuItem.isEnabled = false
    }
    
}
