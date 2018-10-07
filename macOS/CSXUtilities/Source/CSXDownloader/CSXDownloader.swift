//
//  CSXDownloader.swift
//  CSXDownloader
//
//  Created by Zhirui Dai on 2018/7/10.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

public class CSXDownloader: NSObject {
    static let shared = CSXDownloader()
    static let sessionConfig = URLSessionConfiguration.background(withIdentifier: "\(Bundle.main.bundleIdentifier!).backgroundDownloader")
    static let operationQueue = OperationQueue()
    
    var session: URLSession!
    var downloadTasks = [URLSessionDownloadTask : URL]()
    public weak var delegate: CSXDownloaderDelegate?
    
    public override init() {
        super.init()
        self.session = URLSession(configuration: CSXDownloader.sessionConfig,
                                  delegate: self, delegateQueue: CSXDownloader.operationQueue)
    }
    
    public func addDownloadTask(url: URL, destinationURL: URL) {
        let task = self.session.downloadTask(with: url)
        self.downloadTasks[task] = destinationURL
        task.resume()
        DispatchQueue.main.async {
            self.delegate?.csxDownloader(self, didStartDownloadingFrom: destinationURL)
        }
    }
}

extension CSXDownloader: URLSessionDelegate, URLSessionDownloadDelegate {
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        if let destinationURL = self.downloadTasks[downloadTask] {
            do {
                if FileManager.default.fileExists(atPath: destinationURL.relativePath) {
                    try FileManager.default.removeItem(at: destinationURL)
                }
                try FileManager.default.moveItem(at: location, to: destinationURL)
            } catch {
                DispatchQueue.main.async {
                    self.delegate?.csxDownloader(self, meet: error)
                }
            }
            _ = self.downloadTasks.removeValue(forKey: downloadTask)    // remove download task
            DispatchQueue.main.async {
                self.delegate?.csxDownloader(self, didFinishDownloadingTo: destinationURL)
            }
        }
    }
    
    public func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didWriteData bytesWritten: Int64, totalBytesWritten: Int64, totalBytesExpectedToWrite: Int64) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite) * 100
        DispatchQueue.main.async {
            self.delegate?.csxDownloader(self, updatedProgress: progress)
        }
        
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        DispatchQueue.main.async {
            if let aError = error {
                self.delegate?.csxDownloader(self, meet: aError)
            }
        }
    }
}

public protocol CSXDownloaderDelegate: class {
    func csxDownloader(_ downloader: CSXDownloader, didStartDownloadingFrom url: URL)
    func csxDownloader(_ downloader: CSXDownloader, updatedProgress: Double)
    func csxDownloader(_ downloader: CSXDownloader, didFinishDownloadingTo location: URL)
    func csxDownloader(_ downloader: CSXDownloader, meet error: Error)
}
