//
//  LineNumberRulerMarker.swift
//  CSXTextView
//
//  Created by Zhirui Dai on 2018/7/11.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

private let LINENUMBER_CODING_KEY = "line"

class LineNumberRulerMarker: NSRulerMarker {
    
    var lineNumber: Int
    
    override init(rulerView ruler: NSRulerView, markerLocation location: CGFloat, image: NSImage, imageOrigin: NSPoint) {
        self.lineNumber = Int(location)
        super.init(rulerView: ruler, markerLocation: location, image: image, imageOrigin: imageOrigin)
    }
    
    required init(coder: NSCoder) {
        if coder.allowsKeyedCoding {
            self.lineNumber = coder.decodeObject(forKey: LINENUMBER_CODING_KEY) as! Int
        } else {
            self.lineNumber = coder.decodeObject() as! Int
        }
        super.init(coder: coder)
    }
    
    func setLineNumber(_ lineNumber: Int) {
        self.lineNumber = lineNumber
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        if aCoder.allowsKeyedCoding {
            aCoder.encode(self.lineNumber, forKey: LINENUMBER_CODING_KEY)
        } else {
            aCoder.encode(self.lineNumber)
        }
    }
    
    override func copy(with zone: NSZone? = nil) -> Any {
        let copy = super.copy(with: zone)
        (copy as! LineNumberRulerMarker).setLineNumber(self.lineNumber)
        return copy
    }
}
