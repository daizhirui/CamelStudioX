//
//  preferenceViewController.swift
//  CamelStudioX
//
//  Created by 戴植锐 on 2018/3/28.
//  Copyright © 2018年 戴植锐. All rights reserved.
//

import Cocoa
import CSXCodeView
import Sparkle

class PreferenceViewController: NSViewController {

    @IBOutlet weak var codeThemeBox: NSComboBox!
    @IBOutlet weak var autoUpdate: NSButton!
    @IBOutlet weak var autoDownload: NSButton!
    @IBOutlet weak var updateCheckInterval: NSPopUpButton!
    @IBOutlet weak var updateServer: NSPopUpButton!
    
    var sparkleUpdater: SUUpdater {
        return (NSApp.delegate as! AppDelegate).sparkleUpdater
    }
    
    let themes: [String] = Highlightr()?.availableThemes().sorted() ?? []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.loadSetup()
    }
    /**
     Load preference stored in Preference.plist
    */
    func loadSetup() {
        // prepare codeThemeBox
        self.codeThemeBox.removeAllItems()
        self.codeThemeBox.addItems(withObjectValues: self.themes)
        let defaults = UserDefaults.standard
        let themeName: String
        if let temp = defaults.string(forKey: "CodeTheme") {
            themeName = temp
        } else {
            themeName = "xcode"
        }
        for index in ( 0..<self.themes.count ) {
            if self.themes[index] == themeName {
                self.codeThemeBox.selectItem(at: index)
            }
        }
        if let state = defaults.value(forKey: "AutoUpdate") as? NSControl.StateValue {
            self.autoUpdate.state = state
        } else {
            self.autoUpdate.state = .on
            defaults.set(NSControl.StateValue.on as Any, forKey: "AutoUpdate")
        }
        if let state = defaults.value(forKey: "AutoDownload") as? NSControl.StateValue {
            self.autoUpdate.state = state
        } else {
            self.autoUpdate.state = .on
            defaults.set(NSControl.StateValue.on as Any, forKey: "AutoDownload")
        }
        if let tag = defaults.value(forKey: "UpdateCheckInterval") as? Int {
            self.updateCheckInterval.selectItem(withTag: tag)
        } else {
            self.updateCheckInterval.selectItem(withTag: 86400)
            defaults.set(self.updateCheckInterval.selectedTag() as Any, forKey: "UpdateCheckInterval")
        }
        if let location = defaults.object(forKey: "ServerLocation") as? String {
            self.updateServer.selectItem(withTitle: location)
        } else {
            if TimeZone.current.secondsFromGMT() / 3600 == 8 {
                self.updateServer.selectItem(withTitle: "China")
            } else {
                self.updateServer.selectItem(withTitle: "International")
            }
        }
    }
    
    @IBAction func okAction(_ sender: Any) {
        self.applyAction(sender)
        self.view.window?.close()
    }
    
    @IBAction func applyAction(_ sender: Any) {
        let defaults = UserDefaults.standard
        let oldThemeName = defaults.string(forKey: "CodeTheme") ?? ""
        let theme = self.codeThemeBox.stringValue
        if theme != oldThemeName {
            NotificationCenter.default.post(name: NSNotification.Name.CSXCodeViewCodeThemeShouldChange, object: theme)
        }
        // save setup to Preference.plist
        defaults.set(theme, forKey: "CodeTheme")
        
        defaults.set(self.autoUpdate.state as Any, forKey: "AutoUpdate")
        self.sparkleUpdater.automaticallyChecksForUpdates = (self.autoUpdate.state == .on)
        
        defaults.set(self.autoDownload.state as Any, forKey: "AutoDownload")
        self.sparkleUpdater.automaticallyDownloadsUpdates = (self.autoDownload.state == .on)
        
        defaults.set(self.updateCheckInterval.selectedTag() as Any, forKey: "UpdateCheckInterval")
        self.sparkleUpdater.updateCheckInterval = TimeInterval(self.updateCheckInterval.selectedTag())
        
        defaults.set(self.updateServer.selectedItem!.title, forKey: "ServerLocation")
        if self.updateServer.selectedItem?.title == "China" {
            self.sparkleUpdater.updateFeedURL(URL(string: "https://camelmicro.oss-cn-beijing.aliyuncs.com/appcast.xml"))
        } else {
            self.sparkleUpdater.updateFeedURL(URL(string: "https://raw.githubusercontent.com/daizhirui/CamelStudioX_Mac/master/appcast.xml"))
        }
    }
    /// cancel setup
    @IBAction func cancelAction(_ sender: Any) {
        self.view.window?.close()
    }
}
