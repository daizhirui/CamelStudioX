//
//  CSXUtilities.swift
//  CSXUtilities
//
//  Created by Zhirui Dai on 2018/6/30.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Foundation

public class CSXUtilities {
    /// get app icon
    public static func getAppIcon() -> NSImage {
        
        if let infoDict = Bundle.main.infoDictionary {
            if let iconName = infoDict["CFBundleIconName"] as? String {
                return NSImage(imageLiteralResourceName: iconName)
            }
        }
        return NSApp.applicationIconImage
    }
    /// check if sandbox is enabled
    public static func isSandboxingEnabled() -> Bool {
        let environment = ProcessInfo.processInfo.environment
        return environment["APP_SANDBOX_CONTAINER_ID"] != nil
    }
    /// calculate the directory path of studio documents, check the existence and create it when it doesn't exist.
    public static func getStudioDocumentDirectory() -> URL {
        let url = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Documents").appendingPathComponent("CamelStudioX")
        if !FileManager.default.fileExists(atPath: url.relativePath) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }
        return url
    }
    /// calculate the directory path of studio official library
    public static func getStudioLibraryDirectory() -> URL {
        return Bundle.main.bundleURL.appendingPathComponent("Contents").appendingPathComponent("Resources").appendingPathComponent("Library")
    }
    /// calculate the directory path of studio official library for M2
    public static func getStudioM2LibraryDirectory() -> URL {
        return CSXUtilities.getStudioLibraryDirectory().appendingPathComponent("M2")
    }
    /// calculate the directory path of studio official library for M3
    public static func getStudioM3LibraryDirectory() -> URL {
        return CSXUtilities.getStudioLibraryDirectory().appendingPathComponent("M3")
    }
    /// run shell script by applescript
    public static func runCommandByAppleScript(command: String, root: Bool = false) -> (String, NSDictionary?) {
        let myAppleScript = "do shell script \"\(command)\"\(root ? "":" with administrator privileges")"
        var error: NSDictionary?
        
        guard let scriptObject = NSAppleScript(source: myAppleScript) else { return ("", nil) }
        let outputString = scriptObject.executeAndReturnError(&error).stringValue
        return (outputString ?? "", error)
    }
    /// print debug message
    public static func CSXDebug(_ items: Any..., seperator: String = " ", terminator: String = "\n", _ function: String = #function) {
        #if DEBUG
        Swift.print("DEBUG: \(function) >> ", separator: seperator, terminator: "")
        for item in items {
            Swift.print(item, separator: seperator, terminator: "")
        }
        print(terminator, terminator: "")
        #endif
    }
    public static func loadFramework(with identifier: String) -> Bundle? {
        for bundle in Bundle.allFrameworks {
            if bundle.bundleIdentifier == identifier {
                return bundle
            }
        }
        return nil
    }
}


