//
//  CSXSymbol.swift
//  CSXToolchains
//
//  Created by Zhirui Dai on 2018/10/11.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

class CSXSymbol: NSObject {
    
    struct SymbolType {
        static let Block = CSXSymbol.SymbolType(byteSize: 0, typeName: "Block")
        static let Function = CSXSymbol.SymbolType(byteSize: 0, typeName: "Function")
        let byteSize: Int
        let typeName: String
        
        static func ==(prefix: CSXSymbol.SymbolType, posfix: CSXSymbol.SymbolType) -> Bool {
            return (prefix.typeName == posfix.typeName) && (prefix.byteSize == prefix.byteSize)
        }
    }
    
    let parentSymbol: CSXSymbol?
    let symbolType: CSXSymbol.SymbolType
    let symbolName: String
    var children: [CSXSymbol]?
    
    init(parent: CSXSymbol, type: SymbolType, name: String) {
        self.parentSymbol = parent
        self.symbolType = type
        if type == CSXSymbol.SymbolType.Block || type == CSXSymbol.SymbolType.Function {
            self.children = [CSXSymbol]()
        }
        self.symbolName = name
        super.init()
    }
    
}
