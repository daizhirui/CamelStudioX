//
//  SerialDriverManager.swift
//  CSXSerialManager
//
//  Created by 戴植锐 on 2018/5/31.
//  Copyright © 2018 戴植锐. All rights reserved.
//

import Cocoa

public class SerialDriver: NSObject {
    
    public static func chooseInstaller() {
        let alert = NSAlert()
        // add OK button
        alert.addButton(withTitle: "CH340")
        alert.addButton(withTitle: "PL2303")
        alert.addButton(withTitle: "Cancel")
        // set the alert title
        alert.messageText = "Install Serial Driver"
        alert.informativeText = "Please choose the serial chip model"
        alert.alertStyle = .critical
        
        // Search Main Window
        if let mainWindow = NSApp.mainWindow {
            alert.beginSheetModal(for: mainWindow, completionHandler: { returnCode in
                let bundle = Bundle(for: SerialDriver.self)
                if returnCode.rawValue == 1000 {
                    if let path = bundle.url(forResource: "ch34x", withExtension: "pkg")?.relativePath {
                        NSWorkspace.shared.openFile(path)
                    } else {
                        NSLog("%@: %@ lost!", #file, "ch34x.pkg")
                    }
                }
                if returnCode.rawValue == 1001 {
                    if let path = bundle.url(forResource: "pl2303", withExtension: "pkg")?.relativePath {
                        NSWorkspace.shared.openFile(path)
                    } else {
                        NSLog("%@: %@ lost!", #file, "pl2303.pkg")
                    }
                }
            })
        }
        
    }
    
    public static var pl2303DriverDetected: Bool {
        get {
            return FileManager.default.fileExists(atPath: "/Library/Extensions/ProlificUsbSerial.kext")
        }
    }
    
    public static var ch340DriverDetected: Bool {
        get {
            return FileManager.default.fileExists(atPath: "/Library/Extensions/usbserial.kext")
        }
    }
    
    public static var osx_ch341DriverDetected: Bool {
        get {
            return FileManager.default.fileExists(atPath: "/Library/Extensions/osx-ch341.kext")
        }
    }
    
    public static var osx_pl2303DriverDetected: Bool {
        get {
            return FileManager.default.fileExists(atPath: "/Library/Extensions/osx-pl2303.kext")
        }
    }
    
    public static var serialDriverDetected: Bool {
        get {
            return SerialDriver.pl2303DriverDetected ||
                SerialDriver.ch340DriverDetected ||
                SerialDriver.osx_ch341DriverDetected ||
                SerialDriver.osx_pl2303DriverDetected
        }
    }
}
