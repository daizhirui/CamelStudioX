//
//  AppDelegate.swift
//  CamelStudioX
//
//  Created by Zhirui Dai on 2018/10/4.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa
import CSXWelcome
import CSXUtilities
import Sparkle
import CSXLog
import CSXFileBrowser
import CSXSerialManager
import CSXToolchains
import CSXWelcome
import CSXCodeView
import CSXTabViewController
import CSXWebView
import CSXUtilities
import ORSSerial

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, SUUpdaterDelegate {
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK:- Sparkle Updater
    @IBOutlet weak var sparkleUpdater: SUUpdater!
    func setupSparkleUpdater() {
        // Set feed url
        let serverLocation: String
        if let location = UserDefaults.standard.object(forKey: "ServerLocation") as? String {
            serverLocation = location
        } else {
            if TimeZone.current.secondsFromGMT() / 3600 == 8 {
                serverLocation = "China"
                UserDefaults.standard.set(serverLocation as Any, forKey: "ServerLocation")
            } else {
                serverLocation = "International"
            }
        }
        if serverLocation == "China" {
            self.sparkleUpdater.updateFeedURL(URL(string: "https://camelmicro.oss-cn-beijing.aliyuncs.com/appcast.xml"))
        } else {
            self.sparkleUpdater.updateFeedURL(URL(string: "https://raw.githubusercontent.com/daizhirui/CamelStudioX/master/macOS/appcast.xml"))
        }
    }
    /// Example Menu
    static let exampleMenu = NSMenu(title: "Example")
    static var exampleList = [NSMenuItem : URL]()
    @objc func openExample(_ sender: NSMenuItem) {
        guard let url = AppDelegate.exampleList[sender] else { return }
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.begin { (response) in
            guard response.rawValue == NSApplication.ModalResponse.OK.rawValue else { return }
            guard let newURL = panel.url else { return }
            do {
                let oldFolderURL = url.deletingLastPathComponent()
                let fileName = url.lastPathComponent
                let newFolderURL = newURL.appendingPathComponent(url.deletingLastPathComponent().lastPathComponent)
                try FileManager.default.copyItem(at: oldFolderURL,
                                                 to: newFolderURL)
                NSWorkspace.shared.open(newFolderURL.appendingPathComponent(fileName))
            } catch {
                _ = InfoAndAlert.shared.showAlertWindow(type: .alert, title: "Fail to open \(url.lastPathComponent)",
                    message: "Fail to open \(url.lastPathComponent): \(error.localizedDescription)")
                CSXLog.printLog(error.localizedDescription)
                return
            }
        }
    }
    
    @IBAction func showExampleMenu(_ sender: Any) {
        guard let view = sender as? NSView else { return }
//        guard let window = NSApp.mainWindow else { return }
        AppDelegate.exampleMenu.popUp(positioning: nil, at: view.frame.origin, in: view)
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        #if DEBUG
        CSXLog.enable = true
        CSXFileBrowser.printLog = {
            string in
            CSXLog.printLog(string)
        }
        #endif
        self.setupHockeySDK()
        // Do some additional configuration if needed here
        // Insert code here to initialize your application
        if let exampleFolder = Bundle.main.url(forResource: "Examples", withExtension: nil) {
            // M2
            let m2ExampleFoler = exampleFolder.appendingPathComponent("M2")
            if let paths = try? FileManager.default.subpathsOfDirectory(atPath: m2ExampleFoler.relativePath) {
                for path in paths {
                    let fileURL = m2ExampleFoler.appendingPathComponent(path)
                    guard fileURL.pathExtension == "cmsx" else { continue }
                    let menuItem = NSMenuItem(title: "M2-\(fileURL.lastPathComponent)",
                                              action: #selector(self.openExample(_:)), keyEquivalent: "")
                    AppDelegate.exampleList[menuItem] = fileURL
                    AppDelegate.exampleMenu.addItem(menuItem)
                }
            }
        } else {
            CSXLog.printLog("AppDelegate: Examples are lost!")
        }
        // Welcome Window Control
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            AppDelegate.wc.windowWillLoad()
            AppDelegate.wc.loadWindow()
            AppDelegate.wc.windowDidLoad()
            AppDelegate.wc.openExampleButton.action = #selector(self.showExampleMenu(_:))
            if !WelcomeWindow.isWelcomeWindowShowed && ViewController.viewControllerCount == 0 {
                AppDelegate.wc.showWindow(self)
            } else {
                AppDelegate.wc.close()
            }
        }
        // Serial Device Notification
        NotificationCenter.default.addObserver(self, selector: #selector(self.receiveNotification(_:)),
                                               name: CSXSerialManager.didConnectSerialPortNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.receiveNotification(_:)),
                                               name: CSXSerialManager.didDisconnectSerialPortNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.receiveNotification(_:)),
                                               name: CSXSerialManager.didEncounterErrorNotification, object: nil)
    }
    
    // MARK:- Serial Device Notification
    @objc func receiveNotification(_ notification: NSNotification) {
        
        guard let userInfo = notification.userInfo else { return }
        switch notification.name {
        case CSXSerialManager.didConnectSerialPortNotification:
            guard let portName = userInfo[CSXSerialManager.Key.PortName] as? String else { return }
            InfoAndAlert.shared.postNotification(title: "Serial Device Connected",
                                                 informativeText: "Serial Port \(portName) is connected to your Mac.")
            
        case CSXSerialManager.didDisconnectSerialPortNotification:
            guard let portName = userInfo[CSXSerialManager.Key.PortName] as? String else { return }
            InfoAndAlert.shared.postNotification(title: "Serial Device Disconnected",
                                                 informativeText: "Serial Port \(portName) is disconnected from your Mac.")
            
        case CSXSerialManager.didEncounterErrorNotification:
            guard let error = userInfo[CSXSerialManager.Key.Error] as? Error else { return }
            guard let portName = userInfo[CSXSerialManager.Key.PortName] as? String else { return }
            InfoAndAlert.shared.showAlertWindow(type: .alert, title: "Serial Port Error",
                                                message: "Fail to open \(portName): \(error.localizedDescription)")
        default:
            return
        }
    }
    
    // MARK:- HockeySDK
    func setupHockeySDK() {
        let hockeyManager = BITHockeyManager.shared()
        hockeyManager?.configure(withIdentifier: "798a2dae49b04400bcadaf69bda80417")
        hockeyManager?.crashManager.isAutoSubmitCrashReport = true
        if let userID = UserDefaults.standard.object(forKey: "UserID") as? String,
            let userName = UserDefaults.standard.object(forKey: "UserName") as? String,
            let userMailAddress = UserDefaults.standard.object(forKey: "UserMailAddress") as? String {
            hockeyManager?.setUserID(userID)
            hockeyManager?.setUserName(userName)
            hockeyManager?.setUserEmail(userMailAddress)
            CSXLog.printLog("HockeyAppSDK: User ID = \(userID)")
            CSXLog.printLog("HockeyAppSDK: User Name = \(userName)")
            CSXLog.printLog("HockeyAppSDK: User Mail Address = \(userMailAddress)")
        } else {
            self.openRegisterWindow()
        }
        hockeyManager?.start()
    }
    func openRegisterWindow() {
        let sb = NSStoryboard.init(name: "Register", bundle: nil)
        if let registerWC = sb.instantiateController(withIdentifier: "RegisterWindowController") as? NSWindowController {
            NSApp.runModal(for: registerWC.window!)
        }
    }
    func feedParameters(for updater: SUUpdater, sendingSystemProfile sendingProfile: Bool) -> [[String : String]] {
        return BITSystemProfile.shared().systemUsageData() as! [[String : String]]
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
    }
    
    
    // MARK:- Welcome Window Control
    static let wc = WelcomeWindowController.initiate()
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        return false
    }
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !WelcomeWindow.isWelcomeWindowShowed && ViewController.viewControllerCount == 0 && SerialMonitorViewController.count == 0 {
            AppDelegate.wc.showWindow(self)
        }
        return false
    }
    
    // MARK:- Preference
    @IBAction func openPreference(_ sender: Any) {
        let sb = NSStoryboard.init(name: "Preference", bundle: nil)
        if let preferenceWindowController = sb.instantiateController(withIdentifier: "PreferenceWindowController") as? NSWindowController {
            preferenceWindowController.showWindow(self)
        }
    }
    
    // MARK:- Debug mode
    @IBAction func toggleDebugMode(_ sender: NSMenuItem) {
        CSXLog.enable = !CSXLog.enable
        sender.state = CSXLog.enable ? .on : .off
    }
    
    @IBAction func openSerialDriverInstallerSheet(_ sender: Any?) {
        if !WelcomeWindow.isWelcomeWindowShowed && ViewController.viewControllerCount == 0 {
            AppDelegate.wc.showWindow(self)
        }
        SerialDriver.chooseInstaller()
    }
    
    @IBAction func createNewSerialMonitorWindow(_ sender: Any?) {
        SerialMonitorWindowController.initiate().showWindow(nil)
    }
}

