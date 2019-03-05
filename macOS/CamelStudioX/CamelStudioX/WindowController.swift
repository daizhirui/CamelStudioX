//
//  WindowController.swift
//  CamelStudioX
//
//  Created by Zhirui Dai on 2018/10/8.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

class WindowController: NSWindowController {

    @IBOutlet var mainWindowTouchBar: NSTouchBar!
    override func windowDidLoad() {
        super.windowDidLoad()
        self.touchBar = self.mainWindowTouchBar
        // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    }

}
