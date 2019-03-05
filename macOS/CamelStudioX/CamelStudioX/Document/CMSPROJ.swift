//
//  CMSPROJ.swift
//  CamelStudioX
//
//  Created by Zhirui Dai on 2018/10/4.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Foundation
import CSXToolchains

class CMSPROJ: NSObject {
    enum Key: String {
        case ChipType = "ChipType"
        case C_Source = "C_Source"
        case A_Source = "A_Source"
        case Library = "Library"
        case TargetAddress = "TargetAddress"
        case DataAddress = "DataAddress"
        case RodataAddress = "RodataAddress"
        case TargetName = "TargetName"
    }
    
    var targetName: String
    var chipType: CSXTarget.ChipType
    var C_Source = [URL]()
    var A_Source = [URL]()
    var Library = [URL]()
    var targetAddress: String
    var dataAddress: String
    var rodataAddress: String
    var buildFolderURL: URL
    
    init?(configDict: Dictionary<String, AnyObject>, url: URL) {
        guard let targetName = configDict[CMSPROJ.Key.TargetName.rawValue] as? String else { return nil }
        guard let chipTypeString = configDict[CMSPROJ.Key.ChipType.rawValue] as? String else { return nil }
        guard let chipType = CSXTarget.ChipType(rawValue: chipTypeString) else { return nil }
        self.targetName = targetName
        self.chipType = chipType
        self.targetAddress = (configDict[CMSPROJ.Key.TargetAddress.rawValue] as? String) ?? ""
        self.dataAddress = (configDict[CMSPROJ.Key.DataAddress.rawValue] as? String) ?? ""
        self.rodataAddress = (configDict[CMSPROJ.Key.RodataAddress.rawValue] as? String) ?? ""
        // c source
        if let cFiles = configDict[CMSPROJ.Key.C_Source.rawValue] as? [String] {
            for file in cFiles {
                let fileURL = url.appendingPathComponent(file)
                if FileManager.default.fileExists(atPath: fileURL.relativePath) {
                    self.C_Source.append(fileURL)
                }
            }
        }
        // asm source
        if let aFiles = configDict[CMSPROJ.Key.A_Source.rawValue] as? [String] {
            for file in aFiles {
                let fileURL = url.appendingPathComponent(file)
                if FileManager.default.fileExists(atPath: fileURL.relativePath) {
                    self.A_Source.append(fileURL)
                }
            }
        }
        // lib
        if let libFiles = configDict[CMSPROJ.Key.Library.rawValue] as? [String] {
            for file in libFiles {
                let fileURL = TOOLCHAIN_LIB_URL.appendingPathComponent(chipType.rawValue).appendingPathComponent("lib\(file).a")
                if FileManager.default.fileExists(atPath: fileURL.relativePath) {
                    self.Library.append(fileURL)
                }
            }
        }
        self.buildFolderURL = url.appendingPathComponent("build")
    }
}
