//
//  AutoCompleterViewController.swift
//  CSXCodeView
//
//  Created by Zhirui Dai on 2018/10/3.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

class AutoCompleterViewController: NSViewController {

    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var tableView: NSTableView!
    let autoCompleter = AutoCompleter()
    var possibleWords = [String]()
    var csxCodeView: CSXCodeView? {
        didSet {
            self.autoCompleter.delegate = self
            self.autoCompleter.textView = self.csxCodeView
            self.csxCodeScrollView = self.csxCodeView?.enclosingScrollView
        }
    }
    var csxCodeScrollView: NSScrollView?
    var viewIsShowed = false
    var selectedWord: String? {
        get {
            if self.tableView.selectedRow >= 0 && self.tableView.selectedRow < self.possibleWords.count {
                return self.possibleWords[self.tableView.selectedRow]
            }
            return nil
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.tableView.dataSource = self
    }
    
    func selectLastPossibleWord() {
        if self.tableView != nil && self.viewIsShowed {
            let indexToSelect = (self.tableView.selectedRow - 1 + self.tableView.numberOfRows) % self.tableView.numberOfRows
            self.tableView.selectRowIndexes(IndexSet(arrayLiteral: indexToSelect), byExtendingSelection: false)
            self.tableView.scrollRowToVisible(indexToSelect)
        }
    }
    
    func selectNextPossibleWord() {
        if self.tableView != nil && self.viewIsShowed {
            let indexToSelect = (self.tableView.selectedRow + 1) % self.tableView.numberOfRows
            self.tableView.selectRowIndexes(IndexSet(arrayLiteral: indexToSelect), byExtendingSelection: false)
            self.tableView.scrollRowToVisible(indexToSelect)
        }
    }
    
    func insertSelection() {
        guard let codeView = self.csxCodeView else { return }
        if self.tableView.selectedRow >= 0 && self.tableView.selectedRow < self.possibleWords.count {
            let selectedWord = self.possibleWords[self.tableView.selectedRow]
            self.autoCompleter.words.remove(selectedWord)
            let currentPart = self.autoCompleter.currentWord
            let partToInsert = (selectedWord as NSString).replacingCharacters(in: NSMakeRange(0, currentPart.count), with: "")
            let cursorPos = codeView.selectedRange().lowerBound
            codeView.insertText(partToInsert, replacementRange: NSMakeRange(cursorPos, 0))
            codeView.setSelectedRange(NSMakeRange(cursorPos + partToInsert.count, 0))
            self.hideView()
        }
    }
    
    func hideView() {
        if self.viewIsShowed {
            self.view.removeFromSuperview()
            self.viewIsShowed = false
        }
    }
    
    func showView() {
        if !self.viewIsShowed {
            self.csxCodeScrollView?.addFloatingSubview(self.view, for: .horizontal)
            self.viewIsShowed = true
            self.selectNextPossibleWord()
        }
    }
}

extension AutoCompleterViewController: AutoCompleterDelegate {
    func autoCompleter(_ autoCompleter: AutoCompleter, didFind words: [String]) {
        self.possibleWords = words
        
        guard self.tableView != nil else { return }
        self.tableView.reloadData()
        
        guard self.autoCompleter.isEnabled else { return }
        
        if self.possibleWords.count > 0 {
            // show
            guard let codeView = self.csxCodeView else { return }
            let attr = codeView.typingAttributes
            let editedLine = codeView.lineNumberView.lineNumberForCharacterIndex(index: codeView.selectedRange().location)
            let textSize = codeView.string.components(separatedBy: .newlines)[editedLine].size(withAttributes: attr)
            let x = textSize.width
            let y = textSize.height + codeView.lineNumberView.linePositions[editedLine] + 4.0
            self.view.setFrameOrigin(NSPoint(x: x, y: y))
            if let longestWord = self.possibleWords.max(by: {s1, s2 in return s1.count < s2.count}) {
                let textSize = longestWord.size(withAttributes: self.tableView.attributedStringValue.attributes(at: 0, effectiveRange: nil))
                let width = textSize.width > 300 ? 300 : textSize.width + 20
                var height = CGFloat(self.tableView.numberOfRows) * (self.tableView.rowHeight + 2.0)
                height = height > 100 ? 100 : height
                self.view.setFrameSize(NSSize(width: width, height: height))
            }
            self.showView()
            
        } else {
            // hide
            self.hideView()
        }
    }
}

extension AutoCompleterViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return self.possibleWords.count
    }
    
    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        return self.possibleWords[row]
    }
}

