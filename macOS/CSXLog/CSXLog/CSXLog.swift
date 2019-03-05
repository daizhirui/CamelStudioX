//
//  CSXLog.swift
//  CSXLog
//
//  Created by Zhirui Dai on 2018/10/6.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Foundation

public class CSXLog: NSObject {
    
    public static var shared = CSXLog()
    
    public static var enable = false {
        didSet {
            if enable {
                var url = URL(fileURLWithPath: NSHomeDirectory())
                url.appendPathComponent(Bundle.main.bundleURL.deletingPathExtension().lastPathComponent)
                url.appendPathExtension("log")
                if !FileManager.default.fileExists(atPath: url.relativePath) {
                    FileManager.default.createFile(atPath: url.relativePath, contents: nil, attributes: nil)
                }
                logFileHandler = try? FileHandle(forWritingTo: url)
            } else {
                logFileHandler?.closeFile()
                logFileHandler = nil
            }
        }
    }
    public static var logFileHandler: FileHandle?
    
    static var dateFormater: DateFormatter = {
        let df = DateFormatter()
        df.timeZone = TimeZone(secondsFromGMT: 8 * 3600)
        df.dateFormat = "yyyy-mm-dd hh:mm:ss zzzz"
        return df
    }()
    public static func printLog(_ log: String) {
        #if DEBUG
        print(log)
        #endif
        logFileHandler?.seekToEndOfFile()
        guard let data = "\(dateFormater.string(from: Date())) \(log)\n".data(using: .utf8) else { return }
        logFileHandler?.write(data)
    }
    
    deinit {
        CSXLog.logFileHandler?.closeFile()
    }
}
