//
//  Document.swift
//  CamelStudioX
//
//  Created by Zhirui Dai on 2018/10/4.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa
import CSXToolchains
import CSXLog

class Document: NSDocument {
    
    var viewController: ViewController!
    var cmsxFile: CMSX!
    
    override init() {
        super.init()
        // Add your subclass-specific initialization here.
    }

    override class var autosavesInPlace: Bool {
        return true
    }

    override func makeWindowControllers() {
        // Returns the Storyboard that contains your Document window.
        let storyboard = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let windowController = storyboard.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("Document Window Controller")) as! NSWindowController
        guard let vc = windowController.contentViewController as? ViewController else {
            CSXLog.printLog("\(Document.self):\(#line): Fail to connect the document to the corresponding viewController")
            return
        }
        // setup viewController
        vc.document = self
        self.viewController = vc
        
        self.addWindowController(windowController)
    }
    
    override func fileWrapper(ofType typeName: String) throws -> FileWrapper {
        CSXLog.printLog("Document: going to save file as `\(typeName)`")
        guard let fileType = Document.FileType(rawValue: typeName) else {
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        }
        switch fileType {
        case .CMS:
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        case .CMSX:
            if let selectedTarget = self.viewController.targetManager.getSelectedTarget() {
                self.viewController.targetManager.updateInfoOfTarget(selectedTarget)
            }
            self.cmsxFile.targets = Set(self.viewController.targetManager.targets)
            self.cmsxFile.serialPortName = self.viewController.serialMonitor.selectedPort?.name ?? ""
            guard let data = self.cmsxFile.data() else {
                throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
            }
            let fileWrapper = FileWrapper(regularFileWithContents: data)
            fileWrapper.preferredFilename = self.fileURL!.lastPathComponent
            return fileWrapper
        case .CMSPROJ:
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        }
    }

    override func read(from fileWrapper: FileWrapper, ofType typeName: String) throws {
        CSXLog.printLog("Document: Read \(fileWrapper.preferredFilename ?? "Unknown")")
        guard let fileType = Document.FileType(rawValue: typeName) else {
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        }
        switch fileType {
        case .CMS:
            try self.readCMS(fileWrapper)
        case .CMSX:
            try self.readCMSX(fileWrapper)
        case .CMSPROJ:
            try self.readCMSPROJ(fileWrapper)
        }
    }

}

extension Document {
    
    func readCMS(_ fileWrapper: FileWrapper) throws {
        guard let url = self.fileURL else {
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        }
        // change format from cms to cmsx
        // update `self.fileURL`
        let name = url.deletingPathExtension().lastPathComponent
        let cmsxURL = url.deletingPathExtension().appendingPathExtension("cmsx")
        self.fileURL = cmsxURL
        self.fileType = "com.camel.cmsx"
        if FileManager.default.fileExists(atPath: cmsxURL.relativePath) {
            guard let cmsxFileWrapper = try? FileWrapper(url: cmsxURL, options: [.immediate]) else { return }
            try self.readCMSX(cmsxFileWrapper)
        } else {
            guard let cmsRawData = fileWrapper.regularFileContents else { return }
            guard let cmsContent = String(data: cmsRawData, encoding: .utf8) else { return }
            let cms = CMS(content: cmsContent, folderURL: cmsxURL.deletingPathExtension())
            let target = CSXTarget(chipType: cms.chipType, targetType: .Binary, optimization: CSXTarget.OptimizationLevel.O0,
                                   cSourceFiles: cms.cSource, cppSourceFiles: [], aSourceFiles: cms.aSource,
                                   includeFolders: [], libraries: cms.library, buildFolder: cms.buildFolderURL,
                                   targetName: cms.targetName, targetAddress: cms.targetAddress,
                                   dataAddress: cms.dataAddress, rodataAddress: cms.rodataAddress)
            self.cmsxFile = CMSX(projectName: name, projectURL: cmsxURL.deletingLastPathComponent(),
                                 serialPortName: "", codeThemeName: "")
            self.cmsxFile.targets.insert(target)
            if let data = self.cmsxFile.data() {
                try data.write(to: self.fileURL!)
            }
        }
    }
    
    func readCMSX(_ fileWrapper: FileWrapper) throws {
        guard let url = self.fileURL else {
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        }
        guard let cmsxRawData = fileWrapper.regularFileContents else { return }
        guard let cmsxDict = (try? JSONSerialization.jsonObject(with: cmsxRawData,
                                                                options: [.allowFragments]))
            as? Dictionary<String, AnyObject> else { return }
        guard let cmsx = CMSX(cmsxDict: cmsxDict, folderURL: url.deletingLastPathComponent()) else {
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        }
        self.cmsxFile = cmsx
    }
    
    func readCMSPROJ(_ fileWrapper: FileWrapper) throws {

        guard let url = self.fileURL else {
            throw NSError(domain: NSOSStatusErrorDomain, code: unimpErr, userInfo: nil)
        }
        // change format from cmsproj to cmsx
        let name = url.deletingPathExtension().lastPathComponent
        let tempURL = url.deletingLastPathComponent().appendingPathComponent("\(name)-\(name.hashValue)")
        let folderURL = url.deletingPathExtension()
        let cmsxURL = url.deletingPathExtension().appendingPathComponent("\(name).cmsx")
        
        try FileManager.default.moveItem(at: url, to: tempURL)
        try FileManager.default.createDirectory(at: folderURL, withIntermediateDirectories: true, attributes: nil)
        let content = try FileWrapper(url: tempURL, options: [.immediate])
        if content.isDirectory, let fileWrappers = content.fileWrappers {
            for (name, file) in fileWrappers {
                try file.write(to: folderURL.appendingPathComponent(name), options: [.atomic], originalContentsURL: nil)
            }
        }
        try FileManager.default.trashItem(at: tempURL, resultingItemURL: nil)
        // update `self.fileURL`
        
        self.fileURL = cmsxURL
        self.fileType = "com.camel.cmsx"
        // get Config.json
        guard let fileWrappers = fileWrapper.fileWrappers else { return }
        guard let configRawData = fileWrappers["Config.json"]?.regularFileContents else { return }
        guard let configDict = (try? JSONSerialization.jsonObject(with: configRawData,
                                                                  options: [.allowFragments]))
            as? Dictionary<String, AnyObject> else { return }
        guard let cmsproj = CMSPROJ(configDict: configDict, url: url.deletingPathExtension()) else { return }
        let target = CSXTarget(chipType: cmsproj.chipType, targetType: .Binary, optimization: CSXTarget.OptimizationLevel.O0,
                               cSourceFiles: cmsproj.C_Source, cppSourceFiles: [], aSourceFiles: cmsproj.A_Source,
                               includeFolders: [], libraries: [], buildFolder: cmsproj.buildFolderURL,
                               targetName: cmsproj.targetName, targetAddress: cmsproj.targetAddress,
                               dataAddress: cmsproj.dataAddress, rodataAddress: cmsproj.rodataAddress)
        self.cmsxFile = CMSX(projectName: name, projectURL: url.deletingPathExtension(),
                                   serialPortName: "", codeThemeName: "")
        self.cmsxFile.targets.insert(target)
        if let data = self.cmsxFile.data() {
            try data.write(to: self.fileURL!)
        }
    }
    
}

extension Document {
    enum FileType: String {
        case CMS = "com.camel.cms"
        case CMSX = "com.camel.cmsx"
        case CMSPROJ = "com.camel.cmsproj"
    }
}
