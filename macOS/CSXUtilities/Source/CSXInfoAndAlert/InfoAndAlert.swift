//
//  InfoAndAlert.swift
//  CamelStudioX
//
//  Created by ZhiruiDai on 2018/3/20.
//  Copyright © 2018 ZhiruiDai. All rights reserved.
//


import Cocoa

public class InfoAndAlert: NSObject, NSUserNotificationCenterDelegate {
    /// This class only allows to use the shared instance
    public static let shared: InfoAndAlert = InfoAndAlert()
    
    static let alertViewController: AlertViewController = {
        let sb = NSStoryboard.init(name: "Alert", bundle: Bundle.init(for: InfoAndAlert.self))
        let windowController = sb.instantiateController(withIdentifier: "AlertWindowController") as! NSWindowController
        let viewController = windowController.contentViewController as! AlertViewController
        return viewController
    }()
    static var currentAlert: NSWindow?
    
    override init() {
        super.init()
        NSUserNotificationCenter.default.delegate = self
    }
    
    @discardableResult
    public func showAlertWindow(type: InfoAndAlert.MessageType, title: String, message: String, icon: NSImage?=nil,
                                allowCancel:Bool = false, showDontShowAgain: Bool = false,
                                okayHandler: (()->Void)? = nil, cancelHandler: (()->Void)? = nil) -> NSWindow? {
        
        if let donotShowAgainDict = UserDefaults.standard.object(forKey: "Don'tShowAgain") as? [String : Bool] {
            if let value = donotShowAgainDict[message] {
                if value { return nil }     // This message is set to "don't show again"
            }
        }
        
        InfoAndAlert.alertViewController.view.window?.title = title                     // set title
        InfoAndAlert.alertViewController.informativeText.stringValue = message          // set message
        InfoAndAlert.currentAlert = InfoAndAlert.alertViewController.view.window        // keep the window
        if type == .info {  // the following settings are only allowed to be changed when it is info
            InfoAndAlert.alertViewController.needDontShowAgain = showDontShowAgain      // don't show again button
            InfoAndAlert.alertViewController.needCancelButton = allowCancel             // cancel button
        }
        InfoAndAlert.alertViewController.okayHandler = okayHandler                      // okayHandler
        InfoAndAlert.alertViewController.cancelHandler = cancelHandler                  // cancelHandler
        // set icon
        if let unwrappedIcon = icon {
            InfoAndAlert.alertViewController.icon.image = unwrappedIcon
        } else {
            InfoAndAlert.alertViewController.icon.image = CSXUtilities.getAppIcon()
        }
        DispatchQueue.main.asyncAfter(deadline: .now()) {
            NSApp.runModal(for: InfoAndAlert.alertViewController.view.window!)
        }
        return InfoAndAlert.alertViewController.view.window
    }
    
    // MARK: - Post Notification
    static private let userNotificationCenter = NSUserNotificationCenter.default
    /// Post a notification to the User Notification Center
    public func postNotification(title: String, informativeText: String) {
        let userNote = NSUserNotification()
        userNote.title = title
        userNote.informativeText = informativeText
        userNote.soundName = NSUserNotificationDefaultSoundName
        InfoAndAlert.userNotificationCenter.deliver(userNote)
    }
    
    // MARK: - NSUserNotifcationCenterDelegate
    public func userNotificationCenter(_ center: NSUserNotificationCenter, didDeliver notification: NSUserNotification) {
        let popTime = DispatchTime.now() + Double(Int64(3.0 * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        DispatchQueue.main.asyncAfter(deadline: popTime) { () -> Void in
            center.removeDeliveredNotification(notification)    // remove the delivered notification
        }
    }
    public func userNotificationCenter(_ center: NSUserNotificationCenter, shouldPresent notification: NSUserNotification) -> Bool {
        return true
    }
}

extension InfoAndAlert {
    public enum MessageType {
        case info, alert
    }
}
