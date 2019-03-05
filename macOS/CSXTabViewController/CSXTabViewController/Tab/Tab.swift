//
//  Tab.swift
//  TabViewController
//
//  Created by Zhirui Dai on 2018/6/26.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

public class TabAppearance {
    var backgroundColor: NSColor?
    var foregroundColor: NSColor?
    public init(backgroundColor: NSColor, foregroundColor: NSColor) {
        self.backgroundColor = backgroundColor
        self.foregroundColor = foregroundColor
    }
}

public typealias TabID = Int

public class Tab: NSView {
    // MARK:- Shared properties
    static var count = 0
    static let defaultHeight = 26 as CGFloat
    static let defaultWidth = 171 as CGFloat
    static let closeImage = NSImage(imageLiteralResourceName: "NSStopProgressFreestandingTemplate")
    
    public static var selectedAppearance: TabAppearance = {
        if #available(macOS 10.14, *) {
            let selectedTabColor = NSColor(named: NSColor.Name("SelectedTabColorForDarkMode"), bundle: Bundle(for: Tab.self))!
            let selectedFontColor = NSColor(named: NSColor.Name("SelectedFontColorForDarkMode"), bundle: Bundle(for: Tab.self))!
            return TabAppearance(backgroundColor: selectedTabColor, foregroundColor: selectedFontColor)
        } else {
            return TabAppearance(backgroundColor: NSColor.gray, foregroundColor: NSColor.black)
        }
    }()
    
    public static var unselectedAppearance: TabAppearance = {
        if #available(macOS 10.14, *) {
            let unselectedTabColor = NSColor(named: NSColor.Name("UnselectedTabColorForDarkMode"), bundle: Bundle(for: Tab.self))!
            return TabAppearance(backgroundColor: unselectedTabColor, foregroundColor: NSColor.white)
        } else {
            return TabAppearance(backgroundColor: NSColor.gray, foregroundColor: NSColor.white)
        }
    }()
    
    // MARK:- Properties
    var tabImage: NSImage? {
        didSet {
            if let image = self.tabImage {
                self.button.image = image
            }
        }
    }
    @IBOutlet weak var label: NSTextField!
    @IBOutlet weak var button: NSImageView!
    
    var selectedHandler: ((TabID) -> Void)?
    var closeHandler: ((TabID) -> Void)?
    var isSelected: Bool = false {
        didSet {
            if self.isSelected {
                self.setAppearance(with: Tab.selectedAppearance)
                self.delegate?.tabIsSelected(self)
                self.selectedHandler?(self.id)
            } else {
                self.setAppearance(with: Tab.unselectedAppearance)
            }
        }
    }
    var shouldClose: Bool = false {
        didSet {
            if self.shouldClose {
                self.delegate?.tabIsAskedToClose(self)
                self.closeHandler?(self.id)
            }
        }
    }
    var tabAppearance = Tab.unselectedAppearance
    //old: TabAppearance(backgroundColor: NSColor.white, foregroundColor: NSColor.black)
    var delegate: TabDelegate?
    public var id: TabID = 0
    
    // MARK:- Load
    public static func loadFromXib() -> Tab! {
        var topLevelArray: NSArray?
        let nib = NSNib.init(nibNamed: NSNib.Name(TAB_CLASS_NAME), bundle: Bundle.init(for: Tab.self))
        if let success = nib?.instantiate(withOwner: self, topLevelObjects: &topLevelArray), success {
            for view in topLevelArray! {
                if let tab = view as? Tab {
                    tab.id = Tab.count
                    Tab.count += 1
                    tab.setupTackingArea()
                    return tab
                }
            }
        }
        return nil
    }
    
    // MARK:- Mouse Tracking and reaction
    func setupTackingArea() {
        let labelArea = NSTrackingArea(rect: self.label.frame,
                                       options: [.activeAlways, .mouseEnteredAndExited],
                                       owner: self, userInfo: ["object":self.label as Any])
        self.addTrackingArea(labelArea)
        let buttonAera = NSTrackingArea(rect: self.button.frame,
                                        options: [.activeAlways, .mouseEnteredAndExited],
                                        owner: self, userInfo: ["object":self.button as Any])
        self.addTrackingArea(buttonAera)
        let tabArea = NSTrackingArea(rect: self.frame,
                                     options: [.activeAlways, .mouseEnteredAndExited],
                                     owner: self, userInfo: ["object":self as Any])
        self.addTrackingArea(tabArea)
    }
    
    private var mouseOnLabel = false
    private var mouseOnButton = false
    public override func mouseEntered(with event: NSEvent) {
        if let userInfo = event.trackingArea?.userInfo {
            if let object = userInfo["object"] as? NSTextField, object == self.label {
                self.mouseOnButton = false
                self.mouseOnLabel = true
            }
            else if let object = userInfo["object"] as? NSImageView, object == self.button {
                self.mouseOnLabel = false
                self.mouseOnButton = true
            }
            else if let object = userInfo["object"] as? NSView, object == self {
                self.button.image = Tab.closeImage
            }
        }
    }
    
    public override func mouseExited(with event: NSEvent) {
        if let userInfo = event.trackingArea?.userInfo {
            if let object = userInfo["object"] as? NSTextField, object == self.label {
                self.mouseOnLabel = false
            }
            else if let object = userInfo["object"] as? NSButton, object == self.button {
                self.mouseOnButton = false
            }
            else if let object = userInfo["object"] as? NSView, object == self {
                if let image = self.tabImage {
                    self.button.image = image
                }
            }
        }
    }
    
    override public func mouseDown(with event: NSEvent) {
        if self.mouseOnLabel {
            self.isSelected = true
            return
        }
        if self.mouseOnButton {
            self.shouldClose = true
            return
        }
    }
    
    // MARK:- Tab Action Handler
    public func setSelectedHandler(handler: ((TabID) -> Void)?) {
        self.selectedHandler = handler
    }
    
    public func setCloseHandler(handler: ((TabID) -> Void)? ) {
        self.closeHandler = handler
    }
    
    // MARK:- Tab Appearance
    public func setTitle(title: String) {
        self.label.stringValue = title
        self.setForegroundColor(color: self.tabAppearance.foregroundColor)
    }
    
    public func setAppearance(with colorSet: TabAppearance) {
        self.tabAppearance = colorSet
        self.setBackgroundColor(color: colorSet.backgroundColor?.cgColor)
        self.setForegroundColor(color: colorSet.foregroundColor)
    }
    
    private func setForegroundColor(color: NSColor?) {
        if let unwrappedColor = color {
            self.label.textColor = unwrappedColor
        }
    }
    
    private func setBackgroundColor(color: CGColor?) {
        if let backgroundColor = color {
            self.wantsLayer = true
            self.layer?.backgroundColor = backgroundColor
        } else {
            self.wantsLayer = false
        }
    }
    
    override public func updateLayer() {
        if #available(macOS 10.14, *) {
            // update shared appearance
            let selectedTabColor = NSColor(named: NSColor.Name("SelectedTabColorForDarkMode"), bundle: Bundle(for: Tab.self))!
            let selectedFontColor = NSColor(named: NSColor.Name("SelectedFontColorForDarkMode"), bundle: Bundle(for: Tab.self))!
            Tab.selectedAppearance = TabAppearance(backgroundColor: selectedTabColor, foregroundColor: selectedFontColor)
            
            let unselectedTabColor = NSColor(named: NSColor.Name("UnselectedTabColorForDarkMode"), bundle: Bundle(for: Tab.self))!
            Tab.unselectedAppearance = TabAppearance(backgroundColor: unselectedTabColor, foregroundColor: NSColor.white)
            
            // update own appearance
            if self.isSelected {
                self.setAppearance(with: Tab.selectedAppearance)
            } else {
                self.setAppearance(with: Tab.unselectedAppearance)
            }
        }
        // call super
        super.updateLayer()
    }
}

