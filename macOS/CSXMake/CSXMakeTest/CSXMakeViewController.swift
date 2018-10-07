//
//  CSXMakeViewController.swift
//  CSXMakeTest
//
//  Created by Zhirui Dai on 2018/9/30.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa
import CSXMake

class CSXMakeViewController: NSViewController {
    
    let build = CSXBuildViewController.initiate()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        CSXBuildViewController.addViewToContainer(of: self.build, to: self.view)
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
}

