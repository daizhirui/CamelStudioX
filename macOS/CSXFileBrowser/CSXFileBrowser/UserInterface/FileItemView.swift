//
//  FileItemView.swift
//  CSXFileBrowser
//
//  Created by Zhirui Dai on 2018/6/27.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

class FileItemView: NSTableCellView {
    
    static let uiIdentifier = NSUserInterfaceItemIdentifier(rawValue: "FileItem")
    
    // imageView and textField are set in the xib file.
    var fileNode: FileNode! {
        didSet {
            self.imageView?.image = self.fileNode.icon
            if self.fileNode != nil {
                self.textField?.stringValue = self.fileNode.fullName
                self.toolTip = self.fileNode.url.relativePath
            }
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
}
