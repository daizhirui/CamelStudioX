//
//  ToolchainTool.swift
//  CSXMake
//
//  Created by Zhirui Dai on 2018/9/30.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

class ToolchainTool: NSObject {
    
    var url: URL
    var workingDirectory: URL?
    var arguments = [String]()
    
    init(url: URL) {
        self.url = url
    }
    
    func run() -> ToolchainMessage {
        let process = Process()
        
        if #available(macOS 10.13, *) {
            if let url = self.workingDirectory {
                process.currentDirectoryURL = url
            }
            process.executableURL = self.url
        } else {
            if let url = self.workingDirectory {
                process.currentDirectoryPath = url.relativePath
            }
            process.launchPath = self.url.relativePath
        }
        
        // arguments: should be set by subclass
        process.arguments = self.arguments
        
        // set pipe
        let stdout = Pipe()
        let stderr = Pipe()
        process.standardOutput = stdout
        process.standardError = stderr
        
        // launch
        process.launch()
        
        // get result
        let stdoutHandler = stdout.fileHandleForReading
        let stderrHandler = stderr.fileHandleForReading
        let stdoutData = stdoutHandler.readDataToEndOfFile()
        let stderrData = stderrHandler.readDataToEndOfFile()
        let stdoutString = String(data: stdoutData, encoding: .utf8)
        let stderrString = String(data: stderrData, encoding: .utf8)
        
        DispatchQueue.main.async {
            process.terminate()
        }
        
        return ToolchainMessage(exitCode: Int(process.terminationStatus), stdoutString: stdoutString ?? "", stderrString: stderrString ?? "")
    }
}
