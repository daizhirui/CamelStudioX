//
//  CSXTarget.swift
//  CSXMake
//
//  Created by Zhirui Dai on 2018/10/1.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

public class CSXTarget: NSObject {
    public enum Key: String {
        case TargetName = "TargetName"
        case TargetType = "TargetType"
        case ChipType = "ChipType"
        case C_Source = "C_Source"
        case Cpp_Source = "Cpp_Source"
        case A_Source = "A_Source"
        case IncludeFolders = "IncludeFolders"
        case Libraries = "Libraries"
        case TargetAddress = "TargetAddress"
        case DataAddress = "DataAddress"
        case RodataAddress = "RodataAddress"
        case BuildFolder = "BuildFolder"
    }
    
    public enum CSXTargetError: String, Error, LocalizedError {
        case DictError = "Fail to convert a dict to a CSXTarget"
        
        var localizedDescription: String {
            get {
                return self.rawValue
            }
        }
    }
    
    public enum TargetType: String {
        case Binary = "Binary"
        case StaticLibrary = "Library"
    }
    public enum ChipType: String {
        case M2 = "M2"
    }
    var chipType: ChipType
    var targetType: TargetType
    public var cSourceFiles: [URL]
    public var cppSourceFiles: [URL]
    public var aSourceFiles: [URL]
    public var includeFolders: [URL]
    public var libraries: [URL]
    
    public var buildFolder: URL
    public var binaryURL: URL {
        get {
            return self.buildFolder.appendingPathComponent("\(self.targetName).bin")
        }
    }
    
    let targetName: String
    public var targetAddress: String
    var dataAddress: String
    var rodataAddress: String?
    
    @objc var name: String
    
    public var dict: [String : Any] {
        get {
            var dict = [String : Any]()
            dict[CSXTarget.Key.TargetName.rawValue] = self.targetName
            dict[CSXTarget.Key.TargetType.rawValue] = self.targetType.rawValue
            dict[CSXTarget.Key.ChipType.rawValue] = self.chipType.rawValue
            dict[CSXTarget.Key.C_Source.rawValue] = CSXTarget.URLArrayToPathStringArray(self.cSourceFiles)
            dict[CSXTarget.Key.Cpp_Source.rawValue] = CSXTarget.URLArrayToPathStringArray(self.cppSourceFiles)
            dict[CSXTarget.Key.A_Source.rawValue] = CSXTarget.URLArrayToPathStringArray(self.aSourceFiles)
            dict[CSXTarget.Key.IncludeFolders.rawValue] = CSXTarget.URLArrayToPathStringArray(self.includeFolders)
            dict[CSXTarget.Key.Libraries.rawValue] = CSXTarget.URLArrayToPathStringArray(self.libraries)
            dict[CSXTarget.Key.TargetAddress.rawValue] = self.targetAddress
            dict[CSXTarget.Key.DataAddress.rawValue] = self.dataAddress
            dict[CSXTarget.Key.RodataAddress.rawValue] = self.rodataAddress ?? ""
            dict[CSXTarget.Key.BuildFolder.rawValue] = self.buildFolder.relativePath
            return dict
        }
    }
    
    public init(chipType: CSXTarget.ChipType, targetType: CSXTarget.TargetType,
                cSourceFiles: [URL], cppSourceFiles: [URL], aSourceFiles: [URL],
                includeFolders: [URL], libraries: [URL], buildFolder: URL,
                targetName: String, targetAddress: String, dataAddress: String, rodataAddress: String?) {
        self.chipType = chipType
        self.targetType = targetType
        self.cSourceFiles = cSourceFiles
        self.cppSourceFiles = cppSourceFiles
        self.aSourceFiles = aSourceFiles
        self.includeFolders = includeFolders
        self.libraries = libraries
        self.buildFolder = buildFolder
        self.targetName = targetName
        self.targetAddress = targetAddress
        self.dataAddress = dataAddress
        self.rodataAddress = rodataAddress
        self.name = "\(self.targetName)-\(self.targetType.rawValue)"
        super.init()
    }
    
    public init(dict: [String : Any]) throws {
        
        func getAttribute<T>(key: CSXTarget.Key, type: T) throws -> T {
            guard let attribute = dict[key.rawValue] as? T else { throw CSXTargetError.DictError }
            return attribute
        }
        
        self.targetName = try getAttribute(key: .TargetName, type: String())
        guard let targetType = CSXTarget.TargetType(rawValue: try getAttribute(key: .TargetType, type: String())) else { throw CSXTargetError.DictError }
        self.targetType = targetType
        guard let chipType = CSXTarget.ChipType(rawValue: try getAttribute(key: .ChipType, type: String())) else { throw CSXTargetError.DictError }
        self.chipType = chipType
        self.cSourceFiles = CSXTarget.PathStringSetToURLArray(Set(try getAttribute(key: .C_Source, type: [String]())))
        self.cppSourceFiles = CSXTarget.PathStringSetToURLArray(Set(try getAttribute(key: .Cpp_Source, type: [String]())))
        self.aSourceFiles = CSXTarget.PathStringSetToURLArray(Set(try getAttribute(key: .A_Source, type: [String]())))
        self.includeFolders = CSXTarget.PathStringSetToURLArray(Set(try getAttribute(key: .IncludeFolders, type: [String]())))
        self.libraries = CSXTarget.PathStringSetToURLArray(Set(try getAttribute(key: .Libraries, type: [String]())))
        self.targetAddress = try getAttribute(key: .TargetAddress, type: String())
        self.dataAddress = try getAttribute(key: .DataAddress, type: String())
        self.rodataAddress = try getAttribute(key: .RodataAddress, type: String())
        self.buildFolder = URL(fileURLWithPath: try getAttribute(key: .BuildFolder, type: String()))
        self.name = "\(self.targetName)-\(self.targetType.rawValue)"
        super.init()
    }
    
    func getURLInBuildFolder(for input: URL, fileExtension: String?) -> URL {
        let fileName = input.deletingPathExtension().lastPathComponent
        let url = self.buildFolder.appendingPathComponent(fileName)
        if let unwrappedFileExtension = fileExtension {
            return url.appendingPathExtension(unwrappedFileExtension)
        } else {
            return url
        }
    }
    
    static func URLArrayToPathStringSet(_ urls: [URL]) -> Set<String> {
        return urls.reduce(Set<String>(), { (result, url) -> Set<String> in
            return result.union([url.relativePath])
        })
    }
    
    static func URLArrayToPathStringArray(_ urls: [URL]) -> [String] {
        return Array(urls.reduce(Set<String>(), { (result, url) -> Set<String> in
            return result.union([url.relativePath])
        }))
    }
    
    static func PathStringSetToURLArray(_ paths: Set<String>) -> [URL] {
        return paths.reduce([URL](), { (result, path) -> [URL] in
            var newResult = result
            newResult.append(URL(fileURLWithPath: path))
            return newResult
        })
    }
}
