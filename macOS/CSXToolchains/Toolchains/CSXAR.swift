//
//  CSXAR.swift
//  CSXMake
//
//  Created by Zhirui Dai on 2018/9/30.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

class CSXAR: ToolchainTool {
    static let shared = CSXAR(executableURL: TOOLCHAIN_BIN_URL.appendingPathComponent("mips-netbsd-elf-ar"))
    static let AR_OPTIONS = ["rcs"]
    
    init(executableURL: URL) {
        super.init(url: executableURL)
    }
    
    func archive(inputs: [URL], output: URL) -> ToolchainMessage {
        self.arguments = CSXAR.AR_OPTIONS
        self.arguments.append(contentsOf: ["-o",output.relativePath])
        let paths = inputs.reduce([String]()) { ( result, url) -> [String] in
            var newResult = result
            newResult.append(url.relativePath)
            return newResult
        }
        self.arguments.append(contentsOf: paths)
        return self.run()
    }
}
