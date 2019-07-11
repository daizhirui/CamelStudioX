//
//  Shared.swift
//  CSXMake
//
//  Created by Zhirui Dai on 2018/9/30.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Foundation

let TOOLCHAIN_FOLDER_PATH = Bundle(for: CSXGCC.self).path(forResource: "Toolchains", ofType: nil)!
let TOOLCHAIN_FOLDER_URL = URL(fileURLWithPath: TOOLCHAIN_FOLDER_PATH)
let TOOLCHAIN_BIN_URL = TOOLCHAIN_FOLDER_URL.appendingPathComponent("bin")
let TOOLCHAIN_INCLUDE_URL = TOOLCHAIN_FOLDER_URL.appendingPathComponent("include")
public let TOOLCHAIN_LIB_URL = TOOLCHAIN_FOLDER_URL.appendingPathComponent("lib")
