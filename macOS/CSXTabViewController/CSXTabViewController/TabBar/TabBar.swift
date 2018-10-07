//
//  TabBar.swift
//  TabViewController
//
//  Created by Zhirui Dai on 2018/6/26.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

public class TabBar: NSScrollView {

    static let scrollerHeight = 20 as CGFloat
    
    var tabDict = [Int : Tab]()
    var tabOrder = [Int]()
    
    var delegate: TabBarDelegate?
    // MARK:- Initializer
    public static func loadFromXib() -> TabBar! {
        var topLevelArray: NSArray?
        let nib = NSNib(nibNamed: NSNib.Name("TabBar"), bundle: Bundle.init(for: TabBar.self))
        if let success = nib?.instantiate(withOwner: self, topLevelObjects: &topLevelArray), success {
            for view in topLevelArray! {
                if let tabBar = view as? TabBar {
                    tabBar.setupAppearance()
                    return tabBar
                }
            }
        }
        return nil
    }
    
    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
    }
    
    // MARK:- Draw tab bar
    /// Setup tab bar's component
    func setupAppearance() {
        // no background
        self.drawsBackground = false
        // setup scroller
        self.hasVerticalScroller = false    // no vertical scroller
        self.hasHorizontalRuler = true
    }
    /// Redraw tab bar
    public func reload() {
        let tabHeight = self.tabDict.first?.value.frame.height ?? Tab.defaultHeight
        let tabWidth = (self.tabDict.first?.value.frame.width ?? Tab.defaultWidth) + 1
        let allTabsWidth = tabWidth * CGFloat(self.tabDict.count)
        // a new document view to store all the tabs
        let newDocumentView = NSView(frame: NSMakeRect(0, 0, allTabsWidth, tabHeight + TabBar.scrollerHeight))
        if #available(macOS 10.14, *) {
            newDocumentView.wantsLayer = true
//            newDocumentView.layer?.backgroundColor = NSColor(named: NSColor.Name("SelectedTabColorForDarkMode"),
//                                                             bundle: Bundle(for: Tab.self))!.cgColor
            newDocumentView.layer?.backgroundColor = NSColor.white.cgColor
        }
        // get origin scroll position
        var newVisibleRect = self.contentView.bounds
        
        for (index, id) in self.tabOrder.enumerated() {
            guard let tab = self.tabDict[id] else { continue }
            newDocumentView.addSubview(tab)
            let x = tabWidth * CGFloat(index)
            tab.setFrameOrigin(NSPoint(x: x, y: TabBar.scrollerHeight))
            if tab.isSelected { // update scroll position
                if x > (newVisibleRect.origin.x + self.frame.width - tabWidth / 2)
                    || x < (newVisibleRect.origin.x - tabWidth) {
                    var newX = x + ( tabWidth - self.frame.width) / 2
                    if newX < 0 {
                        newX = 0
                    } else if newX > allTabsWidth - self.frame.width {
                        newX = allTabsWidth - self.frame.width
                    }
                    newVisibleRect.origin = NSPoint(x: newX, y: TabBar.scrollerHeight)
                }
            }
        }
        
        self.documentView = newDocumentView
        
        self.contentView.bounds = newVisibleRect
    }
    
    // MARK:- Add tab
    /// Just add a tab, it won't call the delegate
    public func addTab(title: String, tabImage: NSImage?, selectedHandler: ((TabID)->Void)?, closeHandler: ((TabID)->Void)?) -> Int {
        let tab = Tab.loadFromXib()!
        tab.setTitle(title: title)
        tab.tabImage = tabImage
        tab.setSelectedHandler(handler: selectedHandler)
        tab.setCloseHandler(handler: closeHandler)
        tab.delegate = self
        self.tabDict[tab.id] = tab
        self.tabOrder.append(tab.id)
        tab.isSelected = true       // set true, tab starts to call delegate and finally reload()
        return tab.id
    }
    // MARK:- Close tab
    /// Close a tab
    func closeTab(id: Int) {
        self.tabDict[id]?.shouldClose = true
    }
    /// Close a tab
    func closeTab(tabTitle: String) {
        if let tab = self.tab(forTitle: tabTitle) {
            tab.shouldClose = true
        }
    }
    // MARK:- Select a tab
    func selectTab(id: Int) {
        self.tabDict[id]?.isSelected = true
    }
    
    func selectTab(tabTitle: String) {
        if let tab = self.tab(forTitle: tabTitle) {
            tab.isSelected = true
        }
    }
    func updateTabTitle(tabID: TabID, newTitle: String) {
        guard let tab = self.tab(forID: tabID) else { return }
        tab.label.stringValue = newTitle
    }
    // MARK:- Search tab
    /// First tab in tab bar
    public func firstTab() -> Tab? {
        guard let id = self.tabOrder.first else { return nil }
        return self.tabDict[id]
    }
    /// Last tab in tab bar
    public func lastTab() -> Tab? {
        guard let id = self.tabOrder.last else { return nil }
        return self.tabDict[id]
    }
    /// Search a tab by id
    public func tab(forID: Int) -> Tab? {
        return self.tabDict[forID]
    }
    /// Search a tab by title, used
    public func tab(forTitle: String) -> Tab? {
        for (_, tab) in self.tabDict {
            if tab.label.stringValue == forTitle {
                return tab
            }
        }
        return nil
    }
}

extension TabBar: TabDelegate {
    public func tabIsSelected(_ tab: Tab) {
//        self.delegate?.tabBar?(self, willSelect: tab)        // call the delegate
        for (id, aTab) in self.tabDict {
            if id != tab.id {
                aTab.isSelected = false
            }
        }
        self.reload()
        self.delegate?.tabBar?(self, didSelect: tab)        // call the delegate
    }
    
    public func tabIsAskedToClose(_ tab: Tab) {
        self.tabDict.removeValue(forKey: tab.id)
//        self.delegate?.tabBar?(self, willClose: tab)
        for (index, ID) in self.tabOrder.enumerated() {
            if tab.id == ID {
                self.tabOrder.remove(at: index)
            }
        }
        self.reload()
        self.delegate?.tabBar?(self, didClose: tab)
    }
}

