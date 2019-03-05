//
//  AskForNameViewController.swift
//  CSXFileBrowser
//
//  Created by Zhirui Dai on 2018/7/13.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

class RequireNameViewController: NSViewController {
    
    static func initiate() -> RequireNameViewController {
        return RequireNameViewController.init(nibName: NSNib.Name("RequireNameView"),
                                              bundle: Bundle(for: RequireNameViewController.self))
    }

    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var tipLabel: NSTextField!
    @IBOutlet weak var nameTextField: NSTextField!
    
    var okHandler: ((_ name: String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.image = getAppIcon()
    }
    
    @IBAction func okAction(_ sender: Any) {
        if self.nameTextField.stringValue.count > 0 {
            self.okHandler?(self.nameTextField.stringValue)
            self.dismiss(self)
        }
    }
    
    @IBAction func cancelAction(_ sender: NSButton) {
        self.dismiss(self)
    }
}
