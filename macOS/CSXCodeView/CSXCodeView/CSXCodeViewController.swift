//
//  CSXCodeViewController.swift
//  CSXCodeView
//
//  Created by Zhirui Dai on 2018/10/5.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

public class CSXCodeViewController: NSViewController {


    @IBOutlet public var textView: CSXCodeView!
    
    public static func initiate() -> CSXCodeViewController {
        return CSXCodeViewController(nibName: NSNib.Name("CSXCodeViewController"), bundle: Bundle(for: CSXCodeViewController.self))
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
}
