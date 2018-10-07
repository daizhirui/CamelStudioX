//
//  WelcomeView.swift
//  CSXWelcome
//
//  Created by Zhirui Dai on 2018/10/7.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

class WelcomeView: NSView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
        // for dark mode
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor(named: NSColor.Name("WelcomeWindowBackgroundColor"),
                                              bundle: Bundle(for: WelcomeWindowController.self))?.cgColor
        self.layer?.cornerRadius = 10.0
    }
    
}
