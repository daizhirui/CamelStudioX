//
//  CSXAS.swift
//  CSXMake
//
//  Created by Zhirui Dai on 2018/9/30.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

class CSXAS: ToolchainTool {
    static let shared = CSXAS(executableURL: TOOLCHAIN_BIN_URL.appendingPathComponent("mips-netbsd-elf-as"))
    static let AS_OPTIONS = ["-EL", "-G0", "-msoft-float"]
    
    init(executableURL: URL) {
        super.init(url: executableURL)
    }
    
    func compile(input: URL, output: URL) -> ToolchainMessage {
        self.arguments = CSXAS.AS_OPTIONS
        self.arguments.append(contentsOf: ["-o",output.relativePath,input.relativePath])
        return self.run()
    }
}
