//
//  CodeTextStorage.swift
//  CSXTextView
//
//  Created by Zhirui Dai on 2018/7/15.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

class CodeTextStorage: NSTextStorage {
    
    let storage = NSTextStorage()
    
    override var string: String {
        get {
            return self.storage.string
        }
    }
    
    public let highlighter = Highlightr()!
    public var highlightDelegate: HighlightDelegate?
    public var codeLanguage: String? {
        didSet {
            self.processSyntaxHighlighting()
        }
    }
    
    private func setupListeners() {
        self.highlighter.themeChanged = {
            _ in
            self.processSyntaxHighlighting()
        }
    }
    
    /// Initialize the CodeTextStorage
    public override init() {
        super.init()
        self.setupListeners()
    }
    
    /// Initialize the CodeTextStorage
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupListeners()
    }
    
    required init?(pasteboardPropertyList propertyList: Any, ofType type: NSPasteboard.PasteboardType) {
        super.init(pasteboardPropertyList: propertyList, ofType: type)
        self.setupListeners()
    }
    
    // [Fourth] This function will be continuously called when the corresponding textview is being used.
    override func attributes(at location: Int, effectiveRange range: NSRangePointer?) -> [NSAttributedString.Key : Any] {
        return self.storage.attributes(at: location, effectiveRange: range)
    }
    // [first: for plain str] This function will be called when the content is changed (add, insert or delete any character)
    override func replaceCharacters(in range: NSRange, with str: String) {
        self.beginEditing()
        self.storage.replaceCharacters(in: range, with: str)
        self.edited(.editedCharacters, range: range, changeInLength: (str as NSString).length - range.length)
        self.endEditing()
    }
    // [first: for attrString] This function will be called when some attributed strings are pasted into the corresponding textview
    override func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) {
        self.beginEditing()
        self.storage.replaceCharacters(in: range, with: attrString)
        self.edited(.editedCharacters, range: range, changeInLength: attrString.length - range.length)
        self.endEditing()
    }
    // [Second] This function will be called when any character is added to the text view
    override func setAttributes(_ attrs: [NSAttributedString.Key : Any]?, range: NSRange) {
        self.beginEditing()
        self.storage.setAttributes(attrs, range: range)
        self.edited(.editedAttributes, range: range, changeInLength: 0)
        self.endEditing()
    }
    // [Third]
    override func processEditing() {
        // highlight when the content is changed
        if self.editedMask.contains(NSTextStorageEditActions.editedCharacters) {
            self.processSyntaxHighlighting()
        }
        // Apply highlighting before super so that attribute changes are combined
        super.processEditing()
    }
    
    private func processSyntaxHighlighting() {
        if self.codeLanguage == nil { return }
        
        DispatchQueue.global().async {
            let tempStrg = self.highlighter.highlight(self.string, as: self.codeLanguage!)

            DispatchQueue.main.async {
                if tempStrg?.string != self.storage.string { return }
                self.beginEditing()
                tempStrg?.enumerateAttributes(in: NSMakeRange(0, tempStrg!.length), options: [],
                                              using:
                    { (attrs, locRange, stop) in
                        self.storage.setAttributes(attrs, range: locRange)
                })
                self.endEditing()
                self.edited(NSTextStorageEditActions.editedAttributes, range: NSMakeRange(0, self.string.count), changeInLength: 0)
            }
        }
    }
}
