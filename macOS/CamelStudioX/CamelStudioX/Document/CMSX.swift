//
//  CMSX.swift
//  CamelStudioX
//
//  Created by Zhirui Dai on 2018/10/4.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa
import CSXToolchains
import CSXLog

let CMSXVersion = 1.0

class CMSX: NSObject {
    
    
    enum Key: String {
        case ProjectName = "ProjectName"
        case ProjectURL = "ProjectURL"
        case SerialPortName = "SerialPortName"
        case CodeThemeName = "CodeThemeName"
        case Targes = "Targets"
        case CMSXVersion = "CMSXVersion"
    }
    
    var cmsxVersion: String = "\(CMSXVersion)"
    var projectName: String
    var projectURL: URL
    var serialPortName: String
    var codeThemeName: String
    
    var targets = Set<CSXTarget>()
    
    init(projectName: String, projectURL: URL,
         serialPortName: String, codeThemeName: String) {
        self.projectName = projectName
        self.projectURL = projectURL
        self.serialPortName = serialPortName
        self.codeThemeName = codeThemeName
        super.init()
    }
    
    init?(cmsxDict: Dictionary<String, AnyObject>, folderURL: URL) {
        guard let projectName = cmsxDict[CMSX.Key.ProjectName.rawValue] as? String else { return nil }
        self.projectName = projectName
        if let projectPath = cmsxDict[CMSX.Key.ProjectURL.rawValue] as? String {
            self.projectURL = URL(fileURLWithPath: projectPath)
        } else {
            self.projectURL = folderURL
        }
        self.serialPortName = (cmsxDict[CMSX.Key.SerialPortName.rawValue] as? String) ?? ""
        self.codeThemeName = (cmsxDict[CMSX.Key.CodeThemeName.rawValue] as? String) ?? ""
        if let targets = cmsxDict[CMSX.Key.Targes.rawValue] as? [Dictionary<String, AnyObject>] {
            for targetDict in targets {
                do {
                    let target = try CSXTarget(dict: targetDict)
                    self.targets.insert(target)
                } catch {
                    CSXLog.printLog("\(CMSX.self): \(error.localizedDescription)")
                }
            }
        }
    }
    
    func checkAndCorrectTargets(correctProjectURL: URL) {
        guard FileManager.default.fileExists(atPath: correctProjectURL.relativePath) else {
            CSXLog.printLog("\(CMSX.self): Try to correct targets with an unexisting project url!")
            return
        }
        for target in self.targets {
            target.cSourceFiles = self.checkAndCorrectURLs(urls: target.cSourceFiles, correctFolderURL: correctProjectURL)
            target.cppSourceFiles = self.checkAndCorrectURLs(urls: target.cppSourceFiles, correctFolderURL: correctProjectURL)
            target.aSourceFiles = self.checkAndCorrectURLs(urls: target.aSourceFiles, correctFolderURL: correctProjectURL)
            target.includeFolders = self.checkAndCorrectURLs(urls: target.includeFolders, correctFolderURL: correctProjectURL)
            target.libraries = self.checkAndCorrectURLs(urls: target.libraries, correctFolderURL: correctProjectURL)
            target.buildFolder = self.checkAndCorrectURLs(urls: [target.buildFolder], correctFolderURL: correctProjectURL).first!
        }
        self.projectURL = correctProjectURL
    }
    
    func checkAndCorrectURLs(urls: [URL], correctFolderURL: URL) -> [URL] {
        var newURLs = [URL]()
        for fileURL in urls {
            var filePath = fileURL.relativePath
            guard !FileManager.default.fileExists(atPath: filePath) else {
                // file exists
                newURLs.append(fileURL)
                continue
            }
            guard let range = filePath.range(of: self.projectURL.relativePath) else {
                // file doesn't exist but doesn't have `self.projectURL.relativePath` as prefix
                CSXLog.printLog("\(CMSX.self): `\(fileURL.relativePath)` doesn't exist but doesn't have `\(self.projectURL.relativePath)` as prefix.")
                newURLs.append(fileURL)
                continue
            }
            filePath.replaceSubrange(range, with: correctFolderURL.relativePath)
            guard FileManager.default.fileExists(atPath: filePath) else {
                // new file path doesn't exist still
                CSXLog.printLog("\(CMSX.self): `\(filePath)` doesn't exist still.")
                newURLs.append(fileURL)
                continue
            }
            // new path exists!
            newURLs.append(URL(fileURLWithPath: filePath))
        }
        return newURLs
    }
    
    func data() -> Data? {
        var dict = [String : Any]()
        dict[CMSX.Key.CMSXVersion.rawValue] = self.cmsxVersion
        dict[CMSX.Key.ProjectName.rawValue] = self.projectName
        dict[CMSX.Key.ProjectURL.rawValue] = self.projectURL.relativePath
        dict[CMSX.Key.SerialPortName.rawValue] = self.serialPortName
        dict[CMSX.Key.CodeThemeName.rawValue] = self.codeThemeName
        var array = [[String : Any]]()
        for target in self.targets {
            array.append(target.dict)
        }
        dict[CMSX.Key.Targes.rawValue] = array
        let data = try? JSONSerialization.data(withJSONObject: dict,
                                               options: [.prettyPrinted])
        return data
    }
}
