//
//  ViewControllerToShow.swift
//  CSXTabViewControllerTest
//
//  Created by Zhirui Dai on 2018/6/26.
//  Copyright © 2018 戴植锐. All rights reserved.
//

import Cocoa

class ViewControllerToShow: NSViewController {

    static var count = 0
    
    @IBOutlet weak var label: NSTextField!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.label.stringValue = "Tab Generated: \(ViewControllerToShow.count)"
        ViewControllerToShow.count += 1
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.systemOrange.cgColor
    }
    
}
