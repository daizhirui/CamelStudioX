//
//  SerialRequest.swift
//  CSXSerialManager
//
//  Created by Zhirui Dai on 2018/9/28.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

public struct SerialRequest {
    let command: String
    let response: String
    let searchingRangeLength: Int
    let timeout: Int
    let userInfo: [Any]
    let regularExpr: NSRegularExpression
    let execute: (()->Void)?
    
    init?(command: String, response: String, searchingRangeLength: Int, timeout: Int, userInfo: [Any], execute: (()->Void)?) {
        self.command = command
        self.response = response
        self.searchingRangeLength = searchingRangeLength
        self.timeout = timeout
        self.userInfo = userInfo
        self.execute = execute
        
        do {
            try self.regularExpr = NSRegularExpression(pattern: "(\(response))", options: [])
        } catch {
            NSLog("Fail to generate the regular expression for the request pattern: %@", response)
            return nil
        }
    }
    
}
