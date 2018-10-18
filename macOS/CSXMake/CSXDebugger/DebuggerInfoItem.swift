//
//  DebuggerInfoItem.swift
//  CSXToolchains
//
//  Created by Zhirui Dai on 2018/10/11.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

class DebuggerInfoItem: NSObject {
    var fileURL: URL
    var lineNumber: Int
    var assemblyCodeRange: NSRange
    
    init(fileURL: URL, lineNumber: Int, assemblyCodeRange: NSRange) {
        self.fileURL = fileURL
        self.lineNumber = lineNumber
        self.assemblyCodeRange = assemblyCodeRange
        super.init()
    }
}
