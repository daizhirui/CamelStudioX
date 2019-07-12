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
        self.view.wantsLayer = true
        self.view.shadow = NSShadow()
        self.view.layer?.shadowColor = NSColor.black.cgColor
        self.view.layer?.shadowOpacity = 0.8
        self.view.layer?.shadowOffset = CGSize(width: 3, height: -3)
        self.view.layer?.shadowRadius = 8
        self.view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        self.view.layer?.cornerRadius = 5.0
        
        self.tableView.wantsLayer = true
        self.tableView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        self.tableView.layer?.cornerRadius = 5.0
        self.tableView.backgroundColor = NSColor.clear
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.tableView.doubleAction = #selector(self.insertSelection)
    }
    
    override func updateViewConstraints() {
        super.updateViewConstraints()
        self.view.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
        self.tableView.layer?.backgroundColor = NSColor.windowBackgroundColor.cgColor
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
    
    @objc func insertSelection() {
        guard let codeView = self.csxCodeView else { return }
        if self.tableView.selectedRow >= 0 && self.tableView.selectedRow < self.possibleWords.count {
            let selectedWord = self.possibleWords[self.tableView.selectedRow]
            self.autoCompleter.words.remove(selectedWord)
            let currentPart = self.autoCompleter.currentWord
            let partToInsert = (selectedWord as NSString).replacingCharacters(in: NSMakeRange(0, currentPart.count), with: "")
            let cursorPos = codeView.selectedRange().lowerBound
            codeView.replaceSubString(with: StringInsertion(content: partToInsert,
                                                            range: NSMakeRange(cursorPos, 0),
                                                            cursorOffset: 0))
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
                let width = textSize.width > 600 ? 600 : textSize.width + 20
                var height = CGFloat(self.tableView.numberOfRows) * (self.tableView.rowHeight + 3.0)
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

extension AutoCompleterViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 18
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "autocompletion"),
                                                owner: nil) as? NSTableCellView
            else { return nil }
        guard let textField = cellView.textField else { return nil }
        textField.stringValue = self.possibleWords[row]
        return cellView
    }
    
    func tableView(_ tableView: NSTableView, didClick tableColumn: NSTableColumn) {
        self.insertSelection()
    }
    
    func tableViewSelectionIsChanging(_ notification: Notification) {
        self.tableView.rowView(atRow: self.tableView.selectedRow, makeIfNecessary: false)?.isEmphasized = false
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        self.tableView.rowView(atRow: self.tableView.selectedRow, makeIfNecessary: false)?.isEmphasized = true
    }
}

