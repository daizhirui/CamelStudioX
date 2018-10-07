//
//  ViewController.swift
//  csxDownloaderTest
//
//  Created by Zhirui Dai on 2018/7/11.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa
import CSXUtilities

class DownloaderViewController: NSViewController {

    @IBOutlet weak var downloadLog: NSTextView!
    @IBOutlet weak var progressBar: NSProgressIndicator!
    var downloader = CSXDownloader()
    @IBOutlet weak var urlTextField: NSTextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.downloader.delegate = self
        // Do any additional setup after loading the view.
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }

    @IBAction func onDownload(_ sender: Any) {
        guard let origin = URL(string: self.urlTextField.stringValue) else {
            self.downloadLog.string.append("\nInvalid url!")
            return
        }
        let destination = FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Downloads").appendingPathComponent(origin.lastPathComponent)
        self.downloader.addDownloadTask(url: origin, destinationURL: destination)
    }
}

extension DownloaderViewController: CSXDownloaderDelegate {
    func csxDownloader(_ downloader: CSXDownloader, didStartDownloadingFrom url: URL) {
        self.downloadLog.string.append("\nStart downloading files from: \(url.absoluteString)")
    }
    
    func csxDownloader(_ downloader: CSXDownloader, updatedProgress: Double) {
        self.progressBar.doubleValue = updatedProgress
    }
    
    func csxDownloader(_ downloader: CSXDownloader, didFinishDownloadingTo location: URL) {
        self.downloadLog.string.append("\nSave downloaded files to \(location.relativePath)")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.progressBar.doubleValue = 0.0
        }
    }
    
    func csxDownloader(_ downloader: CSXDownloader, meet error: Error) {
        self.downloadLog.string.append("\nEncounter an error: \(error.localizedDescription)")
    }
}
