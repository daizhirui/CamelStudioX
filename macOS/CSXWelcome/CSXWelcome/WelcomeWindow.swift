//
//  WelcomeWindow.swift
//  CamelStudioX
//
//  Created by 戴植锐 on 2018/4/1.
//  Copyright © 2018年 戴植锐. All rights reserved.
//

import Cocoa

public class WelcomeWindow: NSWindow {
    
    public static var windowOnShow: NSWindow!
    public static var isWelcomeWindowShowed: Bool {
        return WelcomeWindow.windowOnShow != nil
    }
    
    // a bordeless window should be set canBecomeKey manually
    override public var canBecomeKey: Bool {
        return true
    }
    override public var canBecomeMain: Bool {
        return true
    }
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        // to make welcome window can be moved by the mouse
        self.isMovableByWindowBackground = true
        // borderless
        self.styleMask.insert(.borderless)
        // transparent
        self.isOpaque = true
        // no background color
        self.backgroundColor = NSColor.clear
        // has shadow
        self.hasShadow = true
    }
    override public func makeKeyAndOrderFront(_ sender: Any?) {
        super.makeKeyAndOrderFront(sender)
        WelcomeWindow.windowOnShow = self
    }
    
    override public func close() {
        WelcomeWindow.windowOnShow = nil
        super.close()
    }
}
