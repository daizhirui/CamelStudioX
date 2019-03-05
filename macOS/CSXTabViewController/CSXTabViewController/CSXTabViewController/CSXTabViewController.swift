//
//  CSXTabViewController.swift
//  CSXTabViewController
//
//  Created by Zhirui Dai on 2018/6/26.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

public class CSXTabViewController: NSViewController {
    
    public static func initiate() -> CSXTabViewController {
        return CSXTabViewController(nibName: NSNib.Name("CSXTabViewController"), bundle: Bundle(for: CSXTabViewController.self))
    }
    // MARK:- public properties
    let tabBar = TabBar.loadFromXib()!
    public var delegate: CSXTabViewControllerDelegate?
    // MARK:- private properties
    let tabView = NSTabView()
    var tabViewItemDict = [ Int : NSTabViewItem ]()
    var tabSelectedList = [Int]()
    
    // MARK:- View Setup
    override public func viewDidLoad() {
        super.viewDidLoad()
        self.tabBar.delegate = self         // important!
        self.setupTabBar()
        self.setupTabViewController()
        
//        self.view.wantsLayer = true
//        self.view.layer?.backgroundColor = NSColor.systemPink.cgColor
    }
    /// Setup tab bar
    func setupTabBar() {
        self.view.addSubview(self.tabBar)

        self.tabBar.translatesAutoresizingMaskIntoConstraints = false
        let topConstraint = self.tabBar.topAnchor.constraint(equalTo: self.view.topAnchor)
        let leadingConstraint = self.tabBar.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        let heightConstraint = self.tabBar.heightAnchor.constraint(equalToConstant: Tab.defaultHeight + TabBar.scrollerHeight)
        let widthConstraint = self.tabBar.widthAnchor.constraint(equalTo: self.view.widthAnchor)
        let miniWidthConstraint = self.tabBar.widthAnchor.constraint(greaterThanOrEqualToConstant: 3 * Tab.defaultWidth)
        
        NSLayoutConstraint.activate([topConstraint,leadingConstraint,heightConstraint, widthConstraint, miniWidthConstraint])
    }
    /// Setup tab view
    func setupTabViewController() {
        self.view.addSubview(self.tabView)
        self.tabView.tabViewType = .noTabsNoBorder
        
        self.tabView.translatesAutoresizingMaskIntoConstraints = false
        let bottomConstraint = self.tabView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor)
        let leadingConstraint = self.tabView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor)
        let widthConstraint = self.tabView.widthAnchor.constraint(equalTo: self.view.widthAnchor)
        let heightConstraint = self.tabView.heightAnchor.constraint(equalTo: self.view.heightAnchor, constant: -Tab.defaultHeight)
        
        NSLayoutConstraint.activate([bottomConstraint, leadingConstraint, widthConstraint, heightConstraint])
    }
    // MARK:- create tab
    public func createNewTab(for viewController: NSViewController, tabTitle: String, tabImage: NSImage?,
                      tabSelectedHandler: ((TabID) -> Void)?, tabCloseHandler: ((TabID) -> Void)?) -> Int {
        // create a new tab view item
        let tabViewItem = NSTabViewItem()
        tabViewItem.viewController = viewController
        tabViewItem.view = viewController.view
        // create a new tab
        let id = self.tabBar.addTab(title: tabTitle, tabImage: tabImage, selectedHandler: tabSelectedHandler, closeHandler: tabCloseHandler)
        self.tabView.addTabViewItem(tabViewItem)
        self.tabView.selectTabViewItem(tabViewItem)     // switch to the view for this tab
        // store this tab view item to dict
        tabViewItem.identifier = id
        self.tabViewItemDict[id] = tabViewItem
        self.selectTab(id: id)
        return id
    }
    // MARK:- select tab
    public func selectTab(id: Int) {
        self.tabBar.selectTab(id: id)
    }
    
    public func selectTab(title: String) {
        self.tabBar.selectTab(tabTitle: title)
    }
    // MARK:- close tab
    public func closeTab(id: Int) {
        self.tabBar.closeTab(id: id)
    }
    
    public func closeTab(title: String) {
        self.tabBar.closeTab(tabTitle: title)
    }
    
    public func updateTabTitle(tabID: TabID, newTitle: String) {
        self.tabBar.updateTabTitle(tabID: tabID, newTitle: newTitle)
    }
    
    public func tabViewItem(for tabID: TabID) -> NSTabViewItem? {
        return self.tabViewItemDict[tabID]
    }
}

extension CSXTabViewController: TabBarDelegate {
    /// Response to selection of tab
    func tabBar(_ tabBar: TabBar, didSelect tab: Tab) {
        self.delegate?.csxTabViewController?(self, willChange: tab.id)  // call delegate
        self.tabView.selectTabViewItem(self.tabViewItemDict[tab.id])    // switch to the view for this tab
        self.tabSelectedList.append(tab.id)                             // record this selection
        self.delegate?.csxTabViewController?(self, didChange: tab.id)   // call delegate
    }
    /// Response to closing of tab
    func tabBar(_ tabBar: TabBar, didClose tab: Tab) {
        self.delegate?.csxTabViewController?(self, willClose: tab.id)   // call delegate
        if let item = self.tabViewItemDict[tab.id] {
            self.tabView.removeTabViewItem(item)                        // remove tab view item from tabview
        }
        if let index = self.tabViewItemDict.index(forKey: tab.id) {
            self.tabViewItemDict.remove(at: index)                      // remove tab view item from dict
        }
        var shouldSelectAnotherTab = false
        if tab.id == self.tabSelectedList.last {                        // check if the removed tab is the selected one
            shouldSelectAnotherTab = true
        }
        var indexShouldKeep = [Int]()
        for id in self.tabSelectedList {
            if id != tab.id {
                indexShouldKeep.append(id)                              // search all records of this tab
            }
        }
        self.tabSelectedList = indexShouldKeep                          // remove all records of this tab
        if shouldSelectAnotherTab {                                     // select another tab if necessary
            if let idOfAnotherTab = self.tabSelectedList.last {
                self.selectTab(id: idOfAnotherTab)
            }
        }
        self.delegate?.csxTabViewController?(self, didClose: tab.id)    // call delegate
    }
}
