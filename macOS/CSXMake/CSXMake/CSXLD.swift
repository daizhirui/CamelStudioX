//
//  CSXLD.swift
//  CSXMake
//
//  Created by Zhirui Dai on 2018/9/30.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

class CSXLD: ToolchainTool {
    static let shared = CSXLD(executableURL: TOOLCHAIN_BIN_URL.appendingPathComponent("mips-netbsd-elf-ld"))
    static let LD_OPTIONS = ["-EL", "-eentry", "-s", "-N"]
    
    init(executableURL: URL) {
        super.init(url: executableURL)
    }
    
    func link(objects: [URL], output: URL, libraries: [URL],
              targetAddress: String, dataAddress: String, rodataAddress: String?) -> ToolchainMessage {
        self.arguments = CSXLD.LD_OPTIONS
        self.arguments.append(contentsOf: ["-Ttext", targetAddress])
        self.arguments.append(contentsOf: ["-Tdata", dataAddress])
        if let unwrappedRodataAddress = rodataAddress {
            if !(unwrappedRodataAddress.contains(" ") || unwrappedRodataAddress.count == 0) {
                self.arguments.append(contentsOf: ["--section-start", ".rodata=\(unwrappedRodataAddress)"])
            }
        }
        self.arguments.append(contentsOf: ["-o",output.relativePath])
        // add arguments of object files
        let objPaths = objects.reduce([String]()) { ( result, url) -> [String] in
            var newResult = result
            newResult.append(url.relativePath)
            return newResult
        }
        self.arguments.append(contentsOf: objPaths)
        // add arguments of libraries to link
        for library in libraries {
            let libName = (library.deletingPathExtension().lastPathComponent as NSString).substring(from: 3)
            self.arguments.append(contentsOf: ["-L", library.deletingLastPathComponent().relativePath,
                                               "-l\(libName)"])
        }
        return self.run()
    }
}
