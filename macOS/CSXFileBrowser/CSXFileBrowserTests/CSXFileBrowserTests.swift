//
//  CSXFileBrowserTests.swift
//  CSXFileBrowserTests
//
//  Created by Zhirui Dai on 2018/10/6.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import XCTest
@testable import CSXFileBrowser

class CSXFileBrowserTests: XCTestCase {
    
    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        FileNode.printLog = {
            log in
            print(log)
        }
        
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    var block: (()->Void)?
    @objc func nodeContentIsModified(_ info: NSNotification) {
        print(info)
        self.block?()
    }

//    func testExample() {
//        // This is an example of a functional test case.
//        // Use XCTAssert and related functions to verify your tests produce the correct results.
//    }
    
    func testInitialization() {
        
        let expectation = self.expectation(description: "All nodes are initialized.")
        
        FileNode.testPast = {
            expectation.fulfill()
        }
        
        let node = FileNode(url: URL(fileURLWithPath: "/Users/daizhirui/Desktop"), parentNode: nil, nodeCreatedHandler: {
            node in
            print("\(FileNode.nodeCount): \(node.url.relativePath)")
        })
        XCTAssert(node?.url.relativePath == "/Users/daizhirui/Desktop")
        
        waitForExpectations(timeout: 1000, handler: nil)
    }
    
//    func testFileChangeMonitor() {
//        FileNode.startContentMonitor(paths: ["/Users/daizhirui/Desktop"])
//        NotificationCenter.default.addObserver(self, selector: #selector(self.nodeContentIsModified(_:)), name: FileNode.NodeContentIsModifiedNotification, object: nil)
//        // file create
//        var expectation = self.expectation(description: "File creations are reported.")
//        self.block = {
//            expectation.fulfill()
//        }
//        FileManager.default.createFile(atPath: "/Users/daizhirui/Desktop/file", contents: nil, attributes: nil)
//        waitForExpectations(timeout: 5, handler: nil)
//        // file modified
//        expectation = self.expectation(description: "File modifications are reported.")
//        self.block = {
//            expectation.fulfill()
//        }
//        do {
//            try "test".write(to: URL(fileURLWithPath: "/Users/daizhirui/Desktop/file"), atomically: true, encoding: .utf8)
//        } catch {}
//        waitForExpectations(timeout: 5, handler: nil)
//        // file deletion
//        expectation = self.expectation(description: "File deletions are reported.")
//        self.block = {
//            expectation.fulfill()
//        }
//        do {
//            try FileManager.default.trashItem(at: URL(fileURLWithPath: "/Users/daizhirui/Desktop/file"), resultingItemURL: nil)
//        } catch {}
//        waitForExpectations(timeout: 5, handler: nil)
//    }

//    func testPerformanceExample() {
//        // This is an example of a performance test case.
//        self.measure {
//            // Put the code you want to measure the time of here.
//        }
//    }

}
