//
//  TargetManagerViewController.swift
//  CSXMake
//
//  Created by Zhirui Dai on 2018/10/1.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

public class CSXTargetManagerViewController: NSViewController {
    
    static public func initiate() -> CSXTargetManagerViewController {
        return CSXTargetManagerViewController(nibName: NSNib.Name("CSXTargetManagerView"),
                                              bundle: Bundle(for: CSXTargetManagerViewController.self))
    }
    // MARK:- Properties
    // MARK:- UI
    @IBOutlet weak var targetNameButton: NSPopUpButton!
    @IBOutlet weak var chipTypeButton: NSPopUpButton!
    @IBOutlet weak var targetTypeButton: NSPopUpButton!
    @IBOutlet weak var cSourceListView: NSView!
    @IBOutlet weak var cppSourceListView: NSView!
    @IBOutlet weak var aSourceListView: NSView!
    @IBOutlet weak var includeFolderListView: NSView!
    @IBOutlet weak var libraryListView: NSView!
    @IBOutlet weak var targetAddressTextField: NSTextField!
    @IBOutlet weak var dataAddressTextField: NSTextField!
    @IBOutlet weak var rodataAddressTextField: NSTextField!
    @IBOutlet weak var buildPathTextField: NSTextField!
    @IBOutlet weak var officialLibraryButton: NSPopUpButton!
    // MARK:- SourceListViewControllers
    let cSourceListViewController = CSXSourceListViewController.initiate(title: "C Source:")
    let cppSourceListViewController = CSXSourceListViewController.initiate(title: "C++ Source:")
    let aSourceListViewController = CSXSourceListViewController.initiate(title: "Assembly Source:")
    let includeFolderListViewController = CSXSourceListViewController.initiate(title: "Include Folders:")
    let libraryListViewController = CSXSourceListViewController.initiate(title: "Libraries:")
    // MARK:- Make System
    public let csxMake = CSXMake()
    public var delegate: CSXTargetManagerViewControllerDelegate?
    // MARK:- Target attributes
    public var defaultBuildFolder: URL?
    @objc public var targets = [CSXTarget]()
    var selectedTarget: CSXTarget? {
        willSet {
            if let target = self.selectedTarget {
                self.updateInfoOfTarget(target)
            }
        }
        
        didSet {
            if let target = self.selectedTarget {
                self.updateAllListController(with: target)
                self.reloadAllLists()
                self.updateOfficialLibraryButton()
            }
        }
    }
    
    // MARK:- View Management
    override public func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        CSXTargetManagerViewController.addListView(of: self.cSourceListViewController, to: self.cSourceListView)
        CSXTargetManagerViewController.addListView(of: self.cppSourceListViewController, to: self.cppSourceListView)
        CSXTargetManagerViewController.addListView(of: self.aSourceListViewController, to: self.aSourceListView)
        CSXTargetManagerViewController.addListView(of: self.includeFolderListViewController, to: self.includeFolderListView)
        CSXTargetManagerViewController.addListView(of: self.libraryListViewController, to: self.libraryListView)
    }
    
    public override func viewWillAppear() {
        super.viewWillAppear()
        for target in self.targets {
            self.targetNameButton.addItem(withTitle: target.name)
        }
    }
    
    func updateOfficialLibraryButton() {
        guard let target = self.selectedTarget else { return }
        let libDirURL = TOOLCHAIN_LIB_URL.appendingPathComponent(target.chipType.rawValue)
        guard let libs = try? FileManager.default.contentsOfDirectory(atPath: libDirURL.relativePath) else { return }
        self.officialLibraryButton.removeAllItems()
        self.officialLibraryButton.addItems(withTitles: libs)
    }
    
    // MARK:- Target Management
    public func getSelectedTarget() -> CSXTarget? {
        guard let target = self.selectedTarget else { return nil }
        self.updateInfoOfTarget(target)
        return target
    }
    
    func addTarget(_ target: CSXTarget) {
        self.targets.append(target)
        self.targetNameButton.addItem(withTitle: target.name)
        self.selectedTarget = target
    }
    
    func deleteTarget(_ target: CSXTarget) {
        for (index, item) in self.targets.enumerated() {
            if item.targetName == target.targetName && item.targetType == target.targetType {
                self.targets.remove(at: index)
                self.targetNameButton.removeItem(withTitle: target.name)
                return
            }
        }
    }
    
    // MARK:- Target <-> SourceListViewControllers
    public func updateInfoOfTarget(_ target: CSXTarget) {
        target.targetAddress = self.targetAddressTextField.stringValue
        target.dataAddress = self.dataAddressTextField.stringValue
        if self.rodataAddressTextField.stringValue.count > 0 {
            target.rodataAddress = self.rodataAddressTextField.stringValue
        } else {
            target.rodataAddress = nil
        }
        target.buildFolder = URL(fileURLWithPath: self.buildPathTextField.stringValue)
        target.cSourceFiles = CSXTarget.PathStringSetToURLArray(self.cSourceListViewController.fileList)
        target.cppSourceFiles = CSXTarget.PathStringSetToURLArray(self.cppSourceListViewController.fileList)
        target.aSourceFiles = CSXTarget.PathStringSetToURLArray(self.aSourceListViewController.fileList)
        target.includeFolders = CSXTarget.PathStringSetToURLArray(self.includeFolderListViewController.fileList)
        target.libraries = CSXTarget.PathStringSetToURLArray(self.libraryListViewController.fileList)
    }
    
    func updateAllListController(with target: CSXTarget) {
        self.cSourceListViewController.fileList = CSXTarget.URLArrayToPathStringSet(target.cSourceFiles)
        self.cppSourceListViewController.fileList = CSXTarget.URLArrayToPathStringSet(target.cppSourceFiles)
        self.aSourceListViewController.fileList = CSXTarget.URLArrayToPathStringSet(target.aSourceFiles)
        self.includeFolderListViewController.fileList = CSXTarget.URLArrayToPathStringSet(target.includeFolders)
        self.libraryListViewController.fileList = CSXTarget.URLArrayToPathStringSet(target.libraries)
        self.targetAddressTextField.stringValue = target.targetAddress
        self.dataAddressTextField.stringValue = target.dataAddress
        self.rodataAddressTextField.stringValue = target.rodataAddress ?? ""
        self.buildPathTextField.stringValue = target.buildFolder.relativePath
    }
    
    func reloadAllLists() {
        self.cSourceListViewController.sourceList.reloadData()
        self.cppSourceListViewController.sourceList.reloadData()
        self.aSourceListViewController.sourceList.reloadData()
        self.includeFolderListViewController.sourceList.reloadData()
        self.libraryListViewController.sourceList.reloadData()
    }
    
    // MARK:- Actions
    @IBAction func onTargetName(_ sender: NSPopUpButton) {
        let name = sender.title
        for target in self.targets {
            if target.name == name {
                self.selectedTarget = target
                return
            }
        }
    }
    @IBAction func onChipType(_ sender: NSPopUpButton) {
        guard let type = CSXTarget.ChipType(rawValue: sender.title) else { return }
        self.selectedTarget?.chipType = type
        self.updateOfficialLibraryButton()
    }
    @IBAction func onTargetTypeButton(_ sender: NSPopUpButton) {
        guard let type = CSXTarget.TargetType(rawValue: sender.title) else { return }
        self.selectedTarget?.targetType = type
    }
    @IBAction func onNewTarget(_ sender: NSButton) {
        let newTargetViewController = NewTargetViewController.initiate()
        newTargetViewController.targetManagerViewController = self
        self.presentAsSheet(newTargetViewController)
        
    }
    @IBAction func onDeleteTarget(_ sender: NSButton) {
        guard let target = self.selectedTarget else { return }
        self.deleteTarget(target)
        self.selectedTarget = self.targets.first
    }
    @IBAction func onOpenBuildFolder(_ sender: NSButton) {
        let panel = NSOpenPanel()
        panel.canChooseDirectories = true
        panel.canChooseFiles = false
        guard let window = NSApp.mainWindow else { return }
        panel.beginSheetModal(for: window) { (response) in
            if response.rawValue == NSApplication.ModalResponse.OK.rawValue {
                guard let url = panel.url else { return }
                self.selectedTarget?.buildFolder = url
                self.buildPathTextField.stringValue = url.relativePath
                panel.endSheet(window)
            }
        }
    }
    @IBAction func onOfficialLibraryButton(_ sender: NSPopUpButton) {
        guard let target = self.selectedTarget else { return }
        let lib = sender.title
        let url = TOOLCHAIN_LIB_URL.appendingPathComponent(target.chipType.rawValue).appendingPathComponent(lib)
        self.libraryListViewController.fileList.insert(url.relativePath)
        self.libraryListViewController.sourceList.reloadData()
    }
    
    @IBAction public func onBuild(_ sender: NSButton?) {
        guard let target = self.getSelectedTarget() else {
            self.csxMake.printLog("ERROR: No target is selected!\n")
            return
        }
        let messages = self.csxMake.build(target: target)
        for message in messages {
            message.check()
        }
        self.delegate?.csxTargetManagerDidBuildTarget(self)
    }
    
    // MARK:- Static functions
    private static func addListView(of controller: CSXSourceListViewController, to superView: NSView) {
        let view = controller.view
        view.translatesAutoresizingMaskIntoConstraints = false
        
        superView.addSubview(view)
        view.frame = superView.bounds
        let top = view.topAnchor.constraint(equalTo: superView.topAnchor)
        let bottom = view.bottomAnchor.constraint(equalTo: superView.bottomAnchor)
        let leading = view.leadingAnchor.constraint(equalTo: superView.leadingAnchor)
        let trailing = view.trailingAnchor.constraint(equalTo: superView.trailingAnchor)
        NSLayoutConstraint.activate([top, bottom, leading, trailing])
    }
}

public protocol CSXTargetManagerViewControllerDelegate {
    func csxTargetManagerDidBuildTarget(_ targetManager: CSXTargetManagerViewController)
}
