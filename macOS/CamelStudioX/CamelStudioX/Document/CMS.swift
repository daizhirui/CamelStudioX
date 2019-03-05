//
//  CMS.swift
//  CamelStudioX
//
//  Created by Zhirui Dai on 2018/10/5.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Foundation
import CSXToolchains

class CMS: NSObject {
    
    public static var printLog: ((String)->Void)?
    
    enum Key: String {
        case TECH = "TECH"
        case TARGET = "TARGET"
        case TARGET_ADDRESS = "TARGET_ADDRESS"
        case DATA_ADDRESS = "DATA_ADDRESS"
        case RODATA_ADDRESS = "RODATA_ADDRESS"
        case C_SOURCE = "C_SOURCE"
        case A_SOURCE = "A_SOURCE"
        case LIBRARY = "LIBRARY"
    }
    
    static let cmsRegx = try! NSRegularExpression(pattern: "(//)?(TECH|COMPILER_PATH|TARGET|TARGET_ADDRESS|DATA_ADDRESS|RODATA_ADDRESS|ARCHITECT|AUTOLOAD|C_SOURCES|A_SOURCES|HEADERS|DEBUG|CUSTOM_LIBRARY|LIBRARY)[ ]*=[ ]*(.*)", options: [])
    
    var targetName: String = ""
    var chipType: CSXTarget.ChipType = .M2
    var targetAddress: String = ""
    var dataAddress: String = ""
    var rodataAddress: String = ""
    var cSource = [URL]()
    var aSource = [URL]()
    var library = [URL]()
    var buildFolderURL: URL
    
    init(content: String, folderURL: URL) {
        CMS.printLog?("\(CMS.self):\(#line): Start to create cms object from \(folderURL.relativePath)")
        
        self.buildFolderURL = folderURL.appendingPathComponent("build")
        super.init()
        let matches = CMS.cmsRegx.matches(in: content, options: [], range: NSMakeRange(0, (content as NSString).length))
        for match in matches {
            
            for index in 0..<match.numberOfRanges {
                let range = match.range(at: index)
                if range.upperBound < (content as NSString).length {    // unsufficient when the group doesn't exist
                    CMS.printLog?("\(CMS.self):\(#line): \((content as NSString).substring(with: range))")
                }
            }
            
            if match.range(at: 1).upperBound < (content as NSString).length { continue }    // find `//`
            guard let key = CMS.Key(rawValue: (content as NSString).substring(with: match.range(at: 2))) else { continue }
            let value = (content as NSString).substring(with: match.range(at: 3))
            switch key {
            case .TECH:
                if let tech = CSXTarget.ChipType(rawValue: value) {
                    self.chipType = tech
                }
            case .TARGET:
                self.targetName = value
            case .TARGET_ADDRESS:
                self.targetAddress = value
            case .DATA_ADDRESS:
                self.dataAddress = value
            case .RODATA_ADDRESS:
                self.rodataAddress = value
            case .C_SOURCE:
                let files = value.components(separatedBy: .whitespaces)
                for file in files {
                    guard file.count > 0 else { continue }
                    let url = folderURL.appendingPathComponent(file)
                    if FileManager.default.fileExists(atPath: url.relativePath) {
                        self.cSource.append(url)
                    }
                }
            case .A_SOURCE:
                let files = value.components(separatedBy: .whitespaces)
                for file in files {
                    guard file.count > 0 else { continue }
                    let url = folderURL.appendingPathComponent(file)
                    if FileManager.default.fileExists(atPath: url.relativePath) {
                        self.aSource.append(url)
                    }
                }
            case .LIBRARY:
                let files = value.components(separatedBy: .whitespaces)
                let libFolderURL = TOOLCHAIN_LIB_URL.appendingPathComponent(self.chipType.rawValue)
                for file in files {
                    guard file.count > 0 else { continue }
                    let url = libFolderURL.appendingPathComponent(file)
                    if FileManager.default.fileExists(atPath: url.relativePath) {
                        self.library.append(url)
                    }
                }
            } // End of switch
        } // End of for
    } // End of init
}
