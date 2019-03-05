//
//  ViewController.swift
//  CSXCodeViewTest
//
//  Created by Zhirui Dai on 2018/10/2.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa
import CSXCodeView

class CSXCodeViewTestViewController: NSViewController {

    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet var codeViewTextView: CSXCodeView!
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        
    }

}

