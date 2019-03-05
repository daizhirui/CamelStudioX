//
//  CSXFileManager.swift
//  CSXFileBrowser
//
//  Created by Zhirui Dai on 2018/10/6.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

let sysFileManager = FileManager.default

public class CSXFileManager: NSObject {
    
    public static var printLog: ((String)->Void)?
    
    let rootURL: URL
    var rootNode: FileNode!
    var nodeList = [String : FileNode]()
    var nodeAlreadyExistsHandler: ((FileNode)->Void)?
    
    init?(rootURL: URL) {
        self.rootURL = rootURL
        super.init()
        guard let node = FileNode(url: rootURL, parentNode: nil,
                                  nodeCreatedHandler: { node in self.nodeList[node.url.relativePath] = node })
            else { return nil }
        self.rootNode = node
    }
    
    func searchForNode(of url: URL) -> FileNode? {
//        guard url.relativePath.contains(self.rootURL.relativePath) else { return nil }
//        return CSXFileManager.fileTreeSearching(rootNode: self.rootNode, target: url)
        return self.nodeList[url.relativePath]   // use a dict to speed up searching
    }
    
    func createFile(atURL url: URL, contents: Data?, attributes: [FileAttributeKey : Any]?) -> Bool {
        
        if self.nodeList.keys.contains(url.relativePath) {
            self.nodeAlreadyExistsHandler?(self.nodeList[url.relativePath]!)
            return false
        }
        
        guard let parentNode = self.searchForNode(of: url.deletingLastPathComponent()) else {
            CSXFileManager.printLog?("In \(#file), line \(#line):\n\t \(CSXFileManager.self): Fail to create a file, parent node doesn't exist.")
            return false
        }
        guard parentNode.nodeType == .Directory else {
            CSXFileManager.printLog?("In \(#file), line \(#line):\n\t \(CSXFileManager.self): Fail to delete item, wrong node type \(parentNode.nodeType) of parent node \(parentNode.url.relativePath).")
            return false
        }
        if sysFileManager.createFile(atPath: url.relativePath, contents: contents, attributes: attributes) {
            guard let childNode = FileNode(url: url, parentNode: parentNode,
                                           nodeCreatedHandler: { node in self.nodeList[node.url.relativePath] = node })
                else {
                CSXFileManager.printLog?("In \(#file), line \(#line):\n\t \(CSXFileManager.self): Fail to create a new node for the created file.")
                return false
            }
            return parentNode.addChildNode(childNode)
        } else {
            return false
        }
    }
    
    func createDirectory(at url: URL, withIntermediateDirectories: Bool, attributes: [FileAttributeKey : Any]?) -> Bool {
        
        if self.nodeList.keys.contains(url.relativePath) {
            self.nodeAlreadyExistsHandler?(self.nodeList[url.relativePath]!)
            return false
        }
        
        guard let parentNode = self.searchForNode(of: url.deletingLastPathComponent()) else {
            CSXFileManager.printLog?("In \(#file), line \(#line):\n\t \(CSXFileManager.self): Fail to create a file, parent node doesn't exist.")
            return false
        }
        guard parentNode.nodeType == .Directory else {
            CSXFileManager.printLog?("In \(#file), line \(#line):\n\t \(CSXFileManager.self): Fail to delete item, wrong node type \(parentNode.nodeType) of parent node \(parentNode.url.relativePath).")
            return false
        }
        do {
            try sysFileManager.createDirectory(at: url,
                                               withIntermediateDirectories: withIntermediateDirectories,
                                               attributes: attributes)
        } catch {
            CSXFileManager.printLog?("In \(#file), line \(#line):\n\t \(CSXFileManager.self): \(error.localizedDescription)")
            return false
        }
        // dir is created
        if sysFileManager.fileExists(atPath: url.relativePath) {
            guard let childNode = FileNode(url: url, parentNode: parentNode,
                                           nodeCreatedHandler: { node in self.nodeList[node.url.relativePath] = node })
                else {
                    CSXFileManager.printLog?("In \(#file), line \(#line):\n\t \(CSXFileManager.self): Fail to create a new node for the created directory.")
                    return false
            }
            return parentNode.addChildNode(childNode)
        } else {
            return false
        }
    }
    
    @discardableResult
    func copyItem(at oldURL: URL, to newURL: URL) -> Bool {
        
        if self.nodeList.keys.contains(newURL.relativePath) {
            self.nodeAlreadyExistsHandler?(self.nodeList[newURL.relativePath]!)
            return false
        }
        let newNodeParentURL = newURL.deletingLastPathComponent()

        guard let newNodeParent = self.searchForNode(of: newNodeParentURL) else {
                CSXFileManager.printLog?("In \(#file), line \(#line):\n\t \(CSXFileManager.self): Fail to copy item, parent node or node doesn't exist.")
                return false
        }
        
        guard newNodeParent.nodeType == .Directory else {
            CSXFileManager.printLog?("In \(#file), line \(#line):\n\t \(CSXFileManager.self): Fail to delete item, wrong node type \(newNodeParent.nodeType) of parent node \(newNodeParent.url.relativePath).")
            return false
        }
        do {
            try sysFileManager.copyItem(at: oldURL, to: newURL)
            
            guard let newNode = FileNode(url: newURL, parentNode: newNodeParent,
                                         nodeCreatedHandler: { node in
                                            
                                            self.nodeList[node.url.relativePath] = node
                                            CSXFileManager.printLog?("\(CSXFileManager.self):\(#line): \(self.nodeList[node.url.relativePath]?.url.relativePath ?? node.fullName) added to nodeList")
            })
                else {
                CSXFileManager.printLog?("In \(#file), line \(#line):\n\t \(CSXFileManager.self): Fail to create a new node for the copied item.")
                return false
            }
            
            return newNodeParent.addChildNode(newNode)
        } catch {
            CSXFileManager.printLog?("In \(#file), line \(#line):\n\t \(CSXFileManager.self): \(error.localizedDescription)")
            return false
        }
    }
    
    @discardableResult
    func deleteItem(at url: URL) -> Bool {
        guard let node = self.searchForNode(of: url),
            let parentNode = self.searchForNode(of: url.deletingLastPathComponent()) else {
                CSXFileManager.printLog?("In \(#file), line \(#line):\n\t \(CSXFileManager.self): parent node or node doesn't exist. Delete node directly. NodeListMemberCount: \(self.nodeList.count)")
                self.nodeList.removeValue(forKey: url.relativePath)
                return false
        }
        do {
            guard parentNode.nodeType == .Directory else {
                CSXFileManager.printLog?("In \(#file), line \(#line):\n\t \(CSXFileManager.self): Fail to delete item, wrong node type \(parentNode.nodeType) of parent node \(parentNode.url.relativePath).")
                return false
            }
            try sysFileManager.trashItem(at: url, resultingItemURL: nil)
            
            if parentNode.removeChildNode(node) {
                self.nodeList.removeValue(forKey: url.relativePath)
                return true
            } else {
                return false
            }
        } catch {
            CSXFileManager.printLog?("In \(#file), line \(#line):\n\t \(CSXFileManager.self): \(error.localizedDescription)")
            return false
        }
    }
    
    @discardableResult
    func moveItem(at oldURL: URL, to newURL: URL) -> Bool {
        
        if self.nodeList.keys.contains(newURL.relativePath) {
            self.nodeAlreadyExistsHandler?(self.nodeList[newURL.relativePath]!)
            return false
        }
        
        guard self.copyItem(at: oldURL, to: newURL) else { return false }
        return self.deleteItem(at: oldURL)
    }
}
