//
//  GetAppIcon.swift
//  CSXFileBrowser
//
//  Created by Zhirui Dai on 2018/7/14.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Foundation

func getAppIcon() -> NSImage {
    
    if let infoDict = Bundle.main.infoDictionary {
        if let iconName = infoDict["CFBundleIconName"] as? String {
            return NSImage(imageLiteralResourceName: iconName)
        }
    }
    return NSApp.applicationIconImage
}
