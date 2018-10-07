//
//  SerialOutputView.swift
//  CSXSerialManager
//
//  Created by Zhirui Dai on 2018/9/29.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

class SerialOutputView: NSTextView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
    }
    
    var userInputDelegate: SerialOutputViewDelegate?
    var userInputCount = 0

    func processUserInput(content: String) {
        
        let attributes = [NSAttributedString.Key.font : NSFont.boldSystemFont(ofSize: self.font!.pointSize),
                          NSAttributedString.Key.foregroundColor : self.textColor!]
        
        let attributedInput = NSAttributedString(string: content,
                                                 attributes: attributes)
        self.textStorage?.append(attributedInput)
        self.pageDownAndModifySelection(nil)
    }
    
    override public func keyDown(with event: NSEvent) {
        if let chars = event.characters {
            // User does input something
            if event.keyCode == 51 {    // delete something
                if self.userInputCount > 0 {
                    let range = NSMakeRange((self.textStorage?.mutableString.length)! - 1, 1)
                    self.textStorage?.mutableString.deleteCharacters(in: range)
                    self.userInputCount -= 1
                }
            } else {
                self.userInputCount += 1
                self.processUserInput(content: chars)
            }
            self.userInputDelegate?.serialOutputView(self, userDidInput: chars)
        }
    }
}

protocol SerialOutputViewDelegate {
    func serialOutputView(_ textView: SerialOutputView, userDidInput content: String)
}
