//
//  FileBrowserMenu.swift
//  CSXFileBrowser
//
//  Created by Zhirui Dai on 2018/6/30.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

class FileBrowserMenu: NSMenu {

    static func loadFromXib() -> FileBrowserMenu? {
        var topLevelArray: NSArray?
        let nib = NSNib(nibNamed: "FileBrowserMenu", bundle: Bundle(for: FileBrowserMenu.self))
        if let success = nib?.instantiate(withOwner: self, topLevelObjects: &topLevelArray), success {
            for view in topLevelArray! {
                if let menu = view as? FileBrowserMenu {
                    return menu
                }
            }
        }
        return nil
    }
    
    @IBOutlet weak var newFileMenuItem: NSMenuItem!
    @IBOutlet weak var newFolderMenuItem: NSMenuItem!
    @IBOutlet weak var addFilesMenuItem: NSMenuItem!
    @IBOutlet weak var renameMenuItem: NSMenuItem!
    @IBOutlet weak var deleteMenuItem: NSMenuItem!
}
