//
//  CSXConvert.swift
//  CSXMake
//
//  Created by Zhirui Dai on 2018/9/30.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

class CSXConvert: ToolchainTool {
    static let shared = CSXConvert(executableURL:
        TOOLCHAIN_BIN_URL.appendingPathComponent("convert"))
    static let CONVERT_OPTIONS = ["-m", "-v"]
    
    init(executableURL: URL) {
        super.init(url: executableURL)
    }
    
    func convert(input: URL, buildDirectory: URL) -> ToolchainMessage {
        self.workingDirectory = buildDirectory
        self.arguments = CSXConvert.CONVERT_OPTIONS
        self.arguments.append(input.relativePath)
        return self.run()
    }
}
