//
//  ConfirmAddingViewController.swift
//  CSXFileBrowser
//
//  Created by Zhirui Dai on 2018/7/13.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

class ConfirmAdditionViewController: NSViewController {

    static func initiate() -> ConfirmAdditionViewController {
        return ConfirmAdditionViewController.init(nibName: NSNib.Name("ConfirmAdditionView"),
                                                  bundle: Bundle(for: ConfirmAdditionViewController.self))
    }
    
    @IBOutlet weak var imageView: NSImageView!
    @IBOutlet weak var confirmationTextLine1: NSTextField!
    @IBOutlet weak var confirmationTextLine2: NSTextField!
    var skipHandler: (() -> Void)?
    var keepBothHandler: (() -> FileNode?)?
    var replaceHandler: (() -> FileNode?)?
    var successHandler: ((FileNode)->Void)?
    var newNode: FileNode?
    var isPresented = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.imageView.image = getAppIcon()
    }
    
    override func viewDidDisappear() {
        if let node = self.newNode {
            self.successHandler?(node)
        }
    }
    
    @IBAction func skipAction(_ sender: Any) {
        self.skipHandler?()
        self.close()
    }
    @IBAction func keepBothAction(_ sender: Any) {
        self.newNode = self.keepBothHandler?()
        self.close()
    }
    @IBAction func replaceAction(_ sender: Any) {
        self.newNode = self.replaceHandler?()
        self.close()
    }
    @IBAction func cancelAction(_ sender: NSButton) {
        self.close()
    }
    
    func close() {
        if self.isPresented {
            self.dismiss(self)
        }
    }
}
