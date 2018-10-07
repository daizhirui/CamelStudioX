//
//  NewTargetViewController.swift
//  CSXMake
//
//  Created by Zhirui Dai on 2018/10/1.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

class NewTargetViewController: NSViewController {
    
    static func initiate() -> NewTargetViewController {
        return NewTargetViewController(nibName: NSNib.Name("NewTargetView"), bundle: Bundle(for: NewTargetViewController.self))
    }

    weak var targetManagerViewController: CSXTargetManagerViewController?
    
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var targetNameField: NSTextField!
    @IBOutlet weak var targetTypeButton: NSPopUpButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    @IBAction func onAdd(_ sender: NSButton) {
        guard let targetType = CSXTarget.TargetType(rawValue: self.targetTypeButton.title) else { return }
        let targetName = self.targetNameField.stringValue
        guard let manager = self.targetManagerViewController else { return }
        guard let buildFolder = manager.defaultBuildFolder else {
            NSLog("%@:%@: `defaultBuildFolder` should be set to add new target.", #file, #line)
            return
        }
        // avoid repeated targets
        for target in manager.targets {
            if target.targetName == targetName && target.targetType == targetType {
                self.statusLabel.stringValue = "Repeated Target Name&Type!"
                self.view.shake()
                return
            }
        }
        let target = CSXTarget(chipType: .M2, targetType: targetType, cSourceFiles: [], cppSourceFiles: [],
                               aSourceFiles: [], includeFolders: [], libraries: [], buildFolder: buildFolder,
                               targetName: targetName, targetAddress: "10000000", dataAddress: "01000010",
                               rodataAddress: nil)
        manager.addTarget(target)
        self.dismiss(self)
    }
    @IBAction func onCancel(_ sender: NSButton) {
        self.dismiss(self)
    }
}

extension NSView {
    internal func shake() {
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = CGPoint(x: self.frame.origin.x - 10, y: self.frame.origin.y)
        animation.toValue = CGPoint(x: self.frame.origin.x + 10, y: self.frame.origin.y)
        self.layer?.add(animation, forKey: "position")
    }
}
