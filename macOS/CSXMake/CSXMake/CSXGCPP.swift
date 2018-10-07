//
//  CSXGCPP.swift
//  CSXMake
//
//  Created by Zhirui Dai on 2018/9/30.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

class CSXGCPP: ToolchainTool {
    static let shared = CSXGCPP(executableURL: TOOLCHAIN_BIN_URL.appendingPathComponent("mips-netbsd-elf-g++"))
    static let GCPP_OPTIONS = ["-EL","-DPRT_UART","-march=mips1","-std=c++11","-c","-G0",
                              "-fno-builtin","-msoft-float","-G0","-Wall","-Wextra"]
    
    init(executableURL: URL) {
        super.init(url: executableURL)
    }
    
    func compile(input: URL, output: URL, includeDirectories: [URL]) -> ToolchainMessage {
        self.arguments = CSXGCPP.GCPP_OPTIONS
        for directory in includeDirectories {
            self.arguments.append(contentsOf: ["-I", directory.relativePath])
        }
        self.arguments.append(contentsOf: ["-o", output.relativePath, input.relativePath])
        
        return self.run()
    }
}
