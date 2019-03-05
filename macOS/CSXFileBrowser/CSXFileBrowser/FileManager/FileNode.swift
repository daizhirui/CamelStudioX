//
//  FileNode.swift
//  CSXFileBrowser
//
//  Created by Zhirui Dai on 2018/10/6.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

/**
 * Feature:
 Small Size: every node only contains some necessary information
 Fast and safe: when it tries to load a huge structure, all the initializations of child nodes can be exectue asynchronously and safely.
 Managable: every directory node can add or remove node from its childnodes.
 Informative: every node posts a notification when it is destroyed, so other objects can update something timely.
 */

public class FileNode: NSObject {
    
    // MARK: ==== Class Properties and Functions ====
    // MARK:- Debug
    public static var printLog: ((String) -> Void)?
    static var testPast: (()->Void)?
    
    // MARK:- Operation Queue
    static var operationQueue = DispatchQueue(label: "com.daizhirui.fileNode")
    public static var operationCount = 0 {
        didSet {
            if operationCount == 0, nodeCount > 0 {
                testPast?()
            }
        }
    }
    public static func addOperationToQueue(_ block: @escaping ()->Void) {
        FileNode.operationCount += 1
        FileNode.operationQueue.async {
            block()
            FileNode.operationCount -= 1
        }
    }
//
//    static var contentMonitor: Witness!
//    public static func startContentMonitor(paths: [String]) {
//        FileNode.contentMonitor = Witness(paths: paths, flags: .FileEvents, latency: 0.3, changeHandler: { (event) in
//            NotificationCenter.default.post(name: FileNode.NodeContentIsModifiedNotification,
//                                            object: self,
//                                            userInfo: [FileNode.NodeEventKey.Event : event])
//        })
//    }
    static var nodeCount = 0
    static var ignoreHidden = true
    
    public let url: URL
    public let nodeType: FileNode.NodeType
    weak var parentNode: FileNode?
    var childNodes: Set<FileNode>!
    
    public var fullName: String {
        return self.url.lastPathComponent
    }
    
    public var fileExtension: String {
        return self.url.pathExtension
    }
    
    public var name: String {
        return self.url.deletingPathExtension().lastPathComponent
    }
    
    public var data: Data? {
        get {
            if self.nodeType == .File {
                do {
                    let data = try Data(contentsOf: self.url)
                    return data
                } catch {
                    FileNode.printLog?("\(FileNode.self):(#line): \(error.localizedDescription), node: \(self.url.relativePath)")
                    return nil
                }
            } else {
                return nil
            }
        }
        set(newData) {
            if self.nodeType == .File {
                do {
                    try newData?.write(to: self.url)
                } catch {
                    FileNode.printLog?("\(FileNode.self):(#line): \(error.localizedDescription), node: \(self.url.relativePath)")
                }
            } else {
                FileNode.printLog?("\(FileNode.self):(#line): Cannot save data to \(self.nodeType.rawValue) node")
            }
        }
    }
    
    public var icon: NSImage {
        if FileManager.default.fileExists(atPath: url.relativePath) {
            return NSWorkspace.shared.icon(forFile: url.relativePath)
        } else {
            switch self.nodeType {
            case .Directory:
                return NSWorkspace.shared.icon(forFileType: "public.directory")
            case .File:
                return NSWorkspace.shared.icon(forFileType: url.pathExtension)
            case .AliasOrSymbolic:
                return NSWorkspace.shared.icon(forFile: self.url.relativePath)
            }
        }
    }
    
    public var numberOfChildren: Int {
        guard self.nodeType == .Directory else {
            return 0
        }
        return self.childNodes.count
    }
    
    init?(url: URL, parentNode: FileNode?,
          nodeCreatedHandler: ((FileNode)->Void)?) {
        self.url = url
        
        if FileNode.ignoreHidden, url.isHidden {
            return nil
        }
        
        guard FileManager.default.fileExists(atPath: url.relativePath) else {
            FileNode.printLog?("\(FileNode.self):(#line): \(url) doesn't exist!")
            return nil
        }
        
        if url.isDirectory! {
            self.nodeType = .Directory
            self.childNodes = Set<FileNode>()
        } else if url.isAlias! {
            self.nodeType = .AliasOrSymbolic
            self.childNodes = nil
        } else {
            self.nodeType = .File
            self.childNodes = nil
        }
        
        if let parent = parentNode {
            if url.relativePath.hasPrefix(parent.url.relativePath) {
                self.parentNode = parent
            } else {
                FileNode.printLog?("\(FileNode.self):(#line): A wrong parent node is posted to \(#function)")
            }
        }
        
        super.init()
        nodeCreatedHandler?(self)
        FileNode.nodeCount += 1
        
        if self.nodeType == .Directory {
            FileNode.addOperationToQueue {
                do {
                    let subpaths = try FileManager.default.contentsOfDirectory(atPath: url.relativePath)
                    for subpath in subpaths {
                        let suburl = url.appendingPathComponent(subpath)
                        guard let childNode = FileNode(url: suburl, parentNode: self,
                                                       nodeCreatedHandler: nodeCreatedHandler) else {
                            continue
                        }
                        self.childNodes.insert(childNode)
                    }
                } catch {
                    FileNode.printLog?("\(FileNode.self):(#line): \(error.localizedDescription), node: \(self.url.relativePath)")
                    return
                }
            }
        }
    }
    
    deinit {
        NotificationCenter.default.post(name: FileNode.NodeWillBeRuinedNotification, object: self.url)
        FileNode.nodeCount -= 1
    }
    
    public func addChildNode(_ childNode: FileNode) -> Bool {
        guard self.nodeType == .Directory else {
            FileNode.printLog?("\(FileNode.self):(#line): Cannot add a child node to a \(self.nodeType.rawValue) node")
            return false
        }
        guard !self.childNodes.contains(childNode) else {
            FileNode.printLog?("\(FileNode.self):(#line): The child node already exists!")
            return false
        }
        self.childNodes.insert(childNode)
        return true
    }
    
    @discardableResult
    public func removeChildNode(_ childNode: FileNode) -> Bool {
        guard self.nodeType == .Directory else {
            FileNode.printLog?("\(FileNode.self):(#line): Cannot remove a child node from a \(self.nodeType.rawValue) node")
            return false
        }
        guard self.childNodes.contains(childNode) else {
            FileNode.printLog?("\(FileNode.self):(#line): The child node does not exist!")
            return false
        }
        self.childNodes.remove(childNode)
        return true
    }
    
    public override func isEqual(_ object: Any?) -> Bool {
        guard let node = object as? FileNode else { return false }
        return node.url == self.url
    }
    
    public override func isGreaterThan(_ object: Any?) -> Bool {
        guard let node = object as? FileNode else { return false }
        return self.url.relativePath > node.url.relativePath
    }
    
    public override func isGreaterThanOrEqual(to object: Any?) -> Bool {
        guard let node = object as? FileNode else { return false }
        return self.url.relativePath >= node.url.relativePath
    }
    
    public override func isLessThan(_ object: Any?) -> Bool {
        guard let node = object as? FileNode else { return false }
        return self.url.relativePath < node.url.relativePath
    }
    
    public override func isLessThanOrEqual(to object: Any?) -> Bool {
        guard let node = object as? FileNode else { return false }
        return self.url.relativePath <= node.url.relativePath
    }
}

extension FileNode {
    public enum NodeType: String {
        case Directory = "Directory"
        case File = "File"
        case AliasOrSymbolic = "AliasOrSymbolic"
    }
    
    public enum NodeEventKey: String {
        case Event = "event"
    }
    
    public static let NodeWillBeRuinedNotification = NSNotification.Name.init("FileNode will be ruined")
    public static let NodeContentIsModifiedNotification = NSNotification.Name.init("Content of the file node is modified")
}

