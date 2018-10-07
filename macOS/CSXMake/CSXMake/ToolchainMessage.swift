//
//  ToolchainMessage.swift
//  CSXMake
//
//  Created by Zhirui Dai on 2018/9/30.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

public class ToolchainMessage: NSObject {
    let exitCode: Int
    let stdoutString: String
    let stderrString: String
    
    public init(exitCode: Int, stdoutString: String, stderrString: String) {
        self.exitCode = exitCode
        self.stdoutString = stdoutString
        self.stderrString = stderrString
    }
    
    @discardableResult
    public func check() -> Bool {
        if self.exitCode != 0 {
            print("exitCode = \(self.exitCode)")
            print("stdout = \(self.stdoutString)")
            print("stderr = \(self.stderrString)")
        }
        return self.exitCode == 0
    }
}
