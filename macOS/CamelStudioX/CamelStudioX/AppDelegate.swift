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
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes

let APP_CENTER_IDENTIFIER = "798a2dae-49b0-4400-bcad-af69bda80417"

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, SUUpdaterDelegate {
    
    var sendCrashReportViewController: SendCrashReportViewController?
    var userName: String = "N/A"
    var userMailAddress: String = "N/A"
    
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
        self.setupMSAppCenter()
        self.setupSparkleUpdater()
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
    
    // MARK:- MSAppCenter
    func setupMSAppCenter() {
        // Enable catching uncaught exceptions thrown on the main thread
        // https://docs.microsoft.com/en-us/appcenter/sdk/crashes/macos#enable-catching-uncaught-exceptions-thrown-on-the-main-thread
        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])
        MSCrashes.setDelegate(self)
        // Ask for the users' consent to send a crash log
        // https://docs.microsoft.com/en-us/appcenter/sdk/crashes/macos#ask-for-the-users-consent-to-send-a-crash-log
        MSCrashes.setUserConfirmationHandler({ (errorReports: [MSErrorReport]) in
            
            // Your code to present your UI to the user, e.g. an NSAlert.
            let alert: NSAlert = NSAlert()
            alert.messageText = "Sorry about that!"
            alert.informativeText = "Do you want to send an anonymous crash report so we can fix the issue?"
            alert.addButton(withTitle: "Always send")
            alert.addButton(withTitle: "Send")
            alert.addButton(withTitle: "Don't send")
            alert.alertStyle = .warning
            
            switch (alert.runModal()) {
            case NSApplication.ModalResponse.alertFirstButtonReturn:
                MSCrashes.notify(with: .always)
                break;
            case NSApplication.ModalResponse.alertSecondButtonReturn:
                MSCrashes.notify(with: .send)
                break;
            case NSApplication.ModalResponse.alertThirdButtonReturn:
                MSCrashes.notify(with: .dontSend)
                break;
            default:
                break;
            }
            
            return true // Return true if the SDK should await user confirmation, otherwise return false.
        })
        MSAppCenter.setLogLevel(MSLogLevel.verbose)
        
        if let userID = UserDefaults.standard.object(forKey: "UserID") as? String,
            let userName = UserDefaults.standard.object(forKey: "UserName") as? String,
            let userMailAddress = UserDefaults.standard.object(forKey: "UserMailAddress") as? String {
            MSAppCenter.setUserId(userID)
            self.userName = userName
            self.userMailAddress = userMailAddress
            CSXLog.printLog("MSAppCenter: User ID = \(userID)")
            CSXLog.printLog("MSAppCenter: User Name = \(userName)")
            CSXLog.printLog("MSAppCenter: User Mail Address = \(userMailAddress)")
        } else {
            self.openRegisterWindow()
        }
        
        MSAppCenter.start(APP_CENTER_IDENTIFIER, withServices: [MSAnalytics.self, MSCrashes.self])
    }
    func openRegisterWindow() {
        let sb = NSStoryboard.init(name: "Register", bundle: nil)
        if let registerWC = sb.instantiateController(withIdentifier: "RegisterWindowController") as? NSWindowController {
            NSApp.runModal(for: registerWC.window!)
        }
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
    
    @IBAction func openHelp(_ sender: Any?) {
        guard let tutorialURL = Bundle.main.url(forResource: "Tutorial.pdf", withExtension: nil) else { return }
        let webViewController = CSXWebViewController.initiate()
        let window = NSWindow(contentViewController: webViewController)
        window.title = "CamelStudioX Help"
        window.setContentSize(NSSize(width: 800, height: 600))
        let wc = NSWindowController(window: window)
        wc.showWindow(nil)
        webViewController.loadURL(tutorialURL)
    }
    
    @IBAction func openCamelDocumentation(_ sender: Any?) {
        guard let documentationFolder = Bundle.main.url(forResource: "Documentation", withExtension: nil) else { return }
        let webViewController = CSXWebViewController.initiate()
        let window = NSWindow(contentViewController: webViewController)
        window.title = "CamelStudioX Documentations"
        window.setContentSize(NSSize(width: 800, height: 600))
        let wc = NSWindowController(window: window)
        wc.showWindow(nil)
        webViewController.loadURL(documentationFolder.appendingPathComponent("index.html"))
    }
}

extension AppDelegate: MSCrashesDelegate {
    func crashes(_ crashes: MSCrashes!, shouldProcessErrorReport errorReport: MSErrorReport!) -> Bool {
        return true; // return true if the crash report should be processed, otherwise false.
    }
    
    func crashes(_ crashes: MSCrashes!, willSend errorReport: MSErrorReport!) {
        // Your code, e.g. to present a custom UI.
        DispatchQueue.main.async {
            let sb = NSStoryboard(name: "SendCrashReport", bundle: Bundle.main)
            guard let reportWC = sb.instantiateController(withIdentifier: "SendCrashReportWindowController") as? NSWindowController
                else { return }
            guard let vc = reportWC.contentViewController as? SendCrashReportViewController else { return }
            self.sendCrashReportViewController = vc
            reportWC.showWindow(nil)
        }
    }
    
    func crashes(_ crashes: MSCrashes!, didSucceedSending errorReport: MSErrorReport!) {
        DispatchQueue.main.async {
            self.sendCrashReportViewController?.progressInfo.stringValue = "Succeeded!"
            self.sendCrashReportViewController?.okButton.isHidden = false
        }
    }
    
    func crashes(_ crashes: MSCrashes!, didFailSending errorReport: MSErrorReport!, withError error: Error!) {
        DispatchQueue.main.async {
            self.sendCrashReportViewController?.progressInfo.stringValue = "Failed: \(error.localizedDescription)"
            self.sendCrashReportViewController?.okButton.isHidden = false
        }
    }
    
    func attachments(with crashes: MSCrashes, for errorReport: MSErrorReport) -> [MSErrorAttachmentLog] {
        let attachment1 = MSErrorAttachmentLog.attachment(withText: "\(self.userName): \(self.userMailAddress)", filename: "user_info.txt")
//        let attachment2 = MSErrorAttachmentLog.attachment(withBinary: "Fake image".data(using: String.Encoding.utf8), filename: nil, contentType: "image/jpeg")
        return [attachment1!]
    }
}
