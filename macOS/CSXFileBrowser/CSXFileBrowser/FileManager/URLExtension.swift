//
//  URLExtension.swift
//  CSXFileBrowser
//
//  Created by Zhirui Dai on 2018/7/14.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Foundation

extension URL {
    var isAlias: Bool? {
        get {
            let values = try? self.resourceValues(forKeys: [.isSymbolicLinkKey, .isAliasFileKey])
            let alias = values?.isAliasFile
            let symbolic = values?.isSymbolicLink
            
            guard alias != nil, symbolic != nil else { return nil }
            if alias! && !symbolic! {
                return true
            }
            return false
        }
    }
    
    var isDirectory: Bool? {
        get {
            var objBool: ObjCBool = false
            if FileManager.default.fileExists(atPath: self.relativePath, isDirectory: &objBool) {
                return objBool.boolValue
            } else {
                return nil  // item doesn't exist
            }
        }
    }
    
    var isHidden: Bool {
        get {
            return (try? resourceValues(forKeys: [.isHiddenKey]))?.isHidden == true
        }
        set {
            var resourceValues = URLResourceValues()
            resourceValues.isHidden = newValue
            do {
                try setResourceValues(resourceValues)
            } catch {
                print("URLExtension: isHidden error:", error)
            }
        }
    }
}
