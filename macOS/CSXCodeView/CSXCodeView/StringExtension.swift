//
//  StringExtension.swift
//  CSXCodeView
//
//  Created by 戴植锐 on 2019/2/3.
//  Copyright © 2019 Zhirui Dai. All rights reserved.
//

import Foundation

extension String {
    func index(_ offset: Int) -> String.Index {
        return self.index(self.startIndex, offsetBy: offset)
    }
    
    func range(pos: Int, length: Int) -> Range<String.Index> {
        let startIndex = self.index(pos)
        let endIndex = self.index(startIndex, offsetBy: length)
        return startIndex..<endIndex
    }
}
