//
//  CSXMake.swift
//  CSXMake
//
//  Created by Zhirui Dai on 2018/9/30.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

public class CSXMake: NSObject {
    
//    static let shared = CSXMake()
    
    let mipsGCC = CSXGCC.shared
    let mipsGCPP = CSXGCPP.shared
    let mipsAS = CSXAS.shared
    let mipsLD = CSXLD.shared
    let mipsAR = CSXAR.shared
    let csxConvert = CSXConvert.shared
    
    public let makeLogViewController = MakeLogViewController.init(nibName: NSNib.Name("MakeLogView"),
                                                                  bundle: Bundle(for: MakeLogViewController.self))
    public var outputLog = true
    
    func printLog(_ content: String) {
        if self.outputLog {
            self.makeLogViewController.logTextView.string.append(content)
            self.makeLogViewController.logTextView.scrollToEndOfDocument(self)
        }
    }
    
    public func build(target: CSXTarget) -> [ToolchainMessage] {
        // create build directory if it doesn't exist
        if !FileManager.default.fileExists(atPath: target.buildFolder.relativePath) {
            do {
                try FileManager.default.createDirectory(at: target.buildFolder, withIntermediateDirectories: true, attributes: nil)
            } catch {
                let message = ToolchainMessage(exitCode: 1, stdoutString: "", stderrString: error.localizedDescription)
                return [message]
            }
        }
        var includeFolders = [TOOLCHAIN_INCLUDE_URL.appendingPathComponent(target.chipType.rawValue)]
        includeFolders.append(contentsOf: target.includeFolders)
        
        var messages = [ToolchainMessage]()
        var objects = [URL]()
        var encounterError = false
        
        // c
        for file in target.cSourceFiles {
            self.printLog("Compile \(file.lastPathComponent)\n")
            let outputURL = target.getURLInBuildFolder(for: file, fileExtension: "o")
            objects.append(outputURL)
            let message = self.mipsGCC.compile(input: file, output: outputURL,
                                               includeDirectories: includeFolders)
            messages.append(message)
            if message.exitCode != 0 {
                self.printLog("ERROR: \(message.stderrString)\n")
                encounterError = true
            }
        }
        // cpp
        for file in target.cppSourceFiles {
            self.printLog("Compile \(file.lastPathComponent)\n")
            let outputURL = target.getURLInBuildFolder(for: file, fileExtension: "o")
            objects.append(outputURL)
            let message = self.mipsGCPP.compile(input: file, output: outputURL,
                                                includeDirectories: includeFolders)
            messages.append(message)
            if message.exitCode != 0 {
                self.printLog("ERROR: \(message.stderrString)\n")
                encounterError = true
            }
        }
        // as
        for file in target.aSourceFiles {
            self.printLog("Compile \(file.lastPathComponent)\n")
            let outputURL = target.getURLInBuildFolder(for: file, fileExtension: "o")
            objects.append(outputURL)
            let message = self.mipsAS.compile(input: file, output: outputURL)
            messages.append(message)
            if message.exitCode != 0 {
                self.printLog("ERROR: \(message.stderrString)\n")
                encounterError = true
            }
        }
        
        if encounterError { // There are some errors, exit
            return messages
        }
        
        // link or archive
        switch target.targetType {
        case .Binary:
            self.printLog("Linking....\n")
            // add entry.o by default
            objects.insert(TOOLCHAIN_LIB_URL.appendingPathComponent(target.chipType.rawValue).appendingPathComponent("entry.o"), at: 0)
            let elfURL = target.buildFolder.appendingPathComponent(target.targetName)
            // link isr by default
            var libraries = [TOOLCHAIN_LIB_URL.appendingPathComponent(target.chipType.rawValue).appendingPathComponent("libisr.a")]
            libraries.append(contentsOf: target.libraries)
            var message = self.mipsLD.link(objects: objects,
                                           output: elfURL,
                                           libraries: libraries,
                                           targetAddress: target.targetAddress,
                                           dataAddress: target.dataAddress,
                                           rodataAddress: target.rodataAddress)
            messages.append(message)
            if message.exitCode != 0 {
                self.printLog("ERROR: \(message.stderrString)\n")
                return messages
            }
            
            self.printLog("Converting.... TargetName: \(target.targetName)\n")
            message = self.csxConvert.convert(input: elfURL, buildDirectory: target.buildFolder)
            messages.append(message)
            if message.exitCode != 0 {
                self.printLog("ERROR: \(message.stderrString)\n")
            }
            
        case .StaticLibrary:
            let libURL = target.buildFolder.appendingPathComponent("lib\(target.targetName)").appendingPathExtension("a")
            self.printLog("Archiving.... TargetName: \(libURL.lastPathComponent)\n")
            let message = self.mipsAR.archive(inputs: objects, output: libURL)
            messages.append(message)
            if message.exitCode != 0 {
                self.printLog("ERROR: \(message.stderrString)\n")
            }
        }
        
        self.printLog("Done!\n\n")
        
        return messages
    }
}
