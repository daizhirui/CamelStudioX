//
//  CSXFileBrowserDelegate.swift
//  CSXFileBrowser
//
//  Created by Zhirui Dai on 2018/6/27.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Foundation

@objc public protocol CSXFileBrowserDelegate {
    
    func fileBrowser(_ fileBrowser: CSXFileBrowser, encounter error: Error, message: String)
    @objc optional func fileBrowser(_ fileBrowser: CSXFileBrowser, startWith url: URL)
    @objc optional func fileBrowser(_ fileBrowser: CSXFileBrowser, alreadyStartedWith url: URL)
    @objc optional func fileBrowserSelectionIsChanging(_ fileBrowser: CSXFileBrowser, notification: Notification)
    @objc optional func fileBrowserSelectionDidChange(_ fileBrowser: CSXFileBrowser, notification: Notification)
    @objc optional func fileBrowser(_ fileBrowser: CSXFileBrowser, processedFileTasks: Int, expectedFileTasks: Int)
    // TODO:- functions for asking the delegate some information about items to create, add, delete, rename
    @objc optional func fileBrowser(_ fileBrowser: CSXFileBrowser, didRename oldURL: URL, to newFileNode: FileNode)
    @objc optional func fileBrowser(_ fileBrowser: CSXFileBrowser, didDelete fileNode: FileNode)
    @objc optional func fileBrowser(_ fileBrowser: CSXFileBrowser, didDetectFileChange file: URL)
}
