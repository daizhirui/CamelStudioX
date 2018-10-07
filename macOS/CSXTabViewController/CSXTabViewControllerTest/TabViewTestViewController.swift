//
//  TabViewTestViewController.swift
//  TabViewControllerTest
//
//  Created by Zhirui Dai on 2018/6/26.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa
import CSXTabViewController

class TabViewTestViewController: NSViewController {

    lazy var csxTabViewController: CSXTabViewController! = {
        for vc in self.children {
            if let csxVC = vc as? CSXTabViewController {
                return csxVC
            }
        }
        return nil
    }()
    var viewControllersForTabView = [NSViewController]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear() {
        
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func onCloseTab(_ sender: Any) {
        guard let id = self.csxTabViewController.tabBar.lastTab()?.id else {
            return
        }
        self.csxTabViewController.closeTab(id: id)
    }
    
    @IBAction func onAddTab(_ sender: Any) {
        let sb = NSStoryboard(name: NSStoryboard.Name("Main"), bundle: nil)
        let vc = sb.instantiateController(withIdentifier: NSStoryboard.SceneIdentifier("ViewControllerToShow")) as! NSViewController
        _ = self.csxTabViewController.createNewTab(for: vc, tabTitle: "ViewControllerToShowViewControllerToShow", tabImage: #imageLiteral(resourceName: "ic_close"),
                                                   tabSelectedHandler: { tabID in print("\(tabID) Selected!") }, tabCloseHandler: { tabID in print("\(tabID) Close!") })
    }
    
    @IBOutlet weak var idTextField: NSTextField!
    @IBAction func onSelectTab(_ sender: NSButton) {
        guard let id = Int(self.idTextField.stringValue) else { return }
        self.csxTabViewController.selectTab(id: id)
    }
}
