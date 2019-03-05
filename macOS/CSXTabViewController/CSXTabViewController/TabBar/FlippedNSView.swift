//
//  FlippedNSView.swift
//  CSXTabViewController
//
//  Created by 戴植锐 on 2019/1/24.
//  Copyright © 2019 戴植锐. All rights reserved.
//

import Cocoa

class FlippedNSView: NSView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
        if #available(macOS 10.14, *) {
            self.wantsLayer = true
            self.layer?.backgroundColor = NSColor(named: NSColor.Name("SelectedTabColorForDarkMode"),
                                                  bundle: Bundle(for: Tab.self))!.cgColor
            //            newDocumentView.layer?.backgroundColor = NSColor.white.cgColor
        }
    }
    
    override var isFlipped: Bool {
        get {
            return true
        }
    }
    
}
