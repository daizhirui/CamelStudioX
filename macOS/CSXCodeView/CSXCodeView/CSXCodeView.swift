//
//  CSXCodeView.swift
//  CSXCodeView
//
//  Created by Zhirui Dai on 2018/10/2.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

public extension NSNotification.Name {
    static let CSXCodeViewCodeThemeShouldChange = NSNotification.Name("CSXCodeViewCodeThemeShouldChange")
}

public class CSXCodeView: NSTextView {
    
    public static var availableThemes = [String]()

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    public override var backgroundColor: NSColor {
        didSet {
            super.backgroundColor = self.backgroundColor
            self.lineNumberView.backgroundColor = backgroundColor
        }
    }
    
    public var highlighter: Highlightr {
        get {
            return (self.textStorage as! CodeTextStorage).highlighter
        }
    }
    
    public var codeLanguage: String? {
        get {
            return (self.textStorage as! CodeTextStorage).codeLanguage
        }
        set(language) {
            (self.textStorage as! CodeTextStorage).codeLanguage = language
        }
    }
    
    public var autoCompleterIsEnabled: Bool {
        get {
            return self.autoCompleterViewController.autoCompleter.isEnabled
        }
        set(isEnabled) {
            self.autoCompleterViewController.autoCompleter.isEnabled = isEnabled
        }
    }
    
    var lineNumberView: MarkerLineNumberRulerView!
    var autoCompleterViewController = AutoCompleterViewController.init(nibName: NSNib.Name("AutoCompleterView"),
                                                                       bundle: Bundle(for: AutoCompleterViewController.self))
    
    public override init(frame frameRect: NSRect) {
        
        super.init(frame: frameRect)
        self.setupHighlightStorage()
        self.turnOffAllSmartOrAutoFunctionExceptLinkDetection()
        self.allowsUndo = true
    }
    
    required public init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupHighlightStorage()
        self.turnOffAllSmartOrAutoFunctionExceptLinkDetection()
        self.allowsUndo = true
    }
    
    private func setupHighlightStorage() {
        let highlightStorage = CodeTextStorage()
//        highlightStorage.highlightDelegate = self
        highlightStorage.codeLanguage = "cpp"
        
        if let theme = UserDefaults.standard.string(forKey: "CodeTheme"),
            highlightStorage.highlighter.setTheme(to: theme) == true {
        } else {
            if let color = self.backgroundColor.usingColorSpace(.deviceRGB) {
                let red = color.redComponent
                let green = color.greenComponent
                let blue = color.blueComponent
                if (red + green + blue) / 3 > 0.5 {
                    highlightStorage.highlighter.setTheme(to: "atom-one-light")
                } else {
                    highlightStorage.highlighter.setTheme(to: "atom-one-dark")
                }
            }
        }
        
        self.layoutManager?.replaceTextStorage(highlightStorage)
        CSXCodeView.availableThemes = self.highlighter.availableThemes()
        NotificationCenter.default.addObserver(self, selector: #selector(self.changeCodeTheme(_:)), name: NSNotification.Name.CSXCodeViewCodeThemeShouldChange, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func changeCodeTheme(_ notification: NSNotification) {
        guard let codeThemeString = notification.object as? String else { return }
        self.highlighter.setTheme(to: codeThemeString)
    }
    
    private func setupAutoCompleterViewController() {
        self.autoCompleterViewController.csxCodeView = self
        self.autoCompleterViewController.loadView()
        self.autoCompleterViewController.viewDidLoad()
    }
    
    public override func awakeFromNib() {
        guard let scrollView = self.enclosingScrollView else {
            fatalError("\(#function): CodeTextView should be wrapped by an NSScrollView!")
        }
        self.turnOffAllSmartOrAutoFunctionExceptLinkDetection()
        self.lineNumberView = MarkerLineNumberRulerView(scrollView: scrollView, orientation: .horizontalRuler)
        scrollView.verticalRulerView = self.lineNumberView
        scrollView.hasHorizontalRuler = false
        scrollView.hasVerticalRuler = true
        scrollView.rulersVisible = true
        self.setupAutoCompleterViewController()
        self.setFont(NSFont.userFixedPitchFont(ofSize: NSFont.smallSystemFontSize)!, range: NSMakeRange(0, self.string.count))
    }
    
    // MARK:- Auto Indent
    func replaceSubString(with insertion: StringInsertion) {
        let range = NSMakeRange(insertion.range.lowerBound, (insertion.content as NSString).length)
        self.insertText(insertion.content, replacementRange: insertion.range)   // undo manager records this automatically
        self.setSelectedRange(NSMakeRange(range.upperBound - insertion.cursorOffset, 0))
    }
    
    static let characterRegx = CharacterRegx()
    override public func keyDown(with event: NSEvent) {
        let selectedRangeBeforeKeyDown = self.selectedRange()
        let keyCode = event.keyCode
        let regxSet = CSXCodeView.characterRegx
        // manipulate auto completer
        if self.autoCompleterViewController.viewIsShowed {
            switch keyCode {
            case 49: self.autoCompleterViewController.hideView()            // space
            case 53:
                self.autoCompleterViewController.hideView()                 // esc
                return
            case 125:
                self.autoCompleterViewController.selectNextPossibleWord()   // down
                return
            case 126:
                self.autoCompleterViewController.selectLastPossibleWord()   // up
                return
            case 36:
                self.autoCompleterViewController.insertSelection()          // enter
                return
            default:
                break
            }
        }
        
        var cursorPos = selectedRangeBeforeKeyDown.lowerBound
        
        // quick comment
        if keyCode == 44 && event.modifierFlags.contains(NSEvent.ModifierFlags.command) {   // command + /
            let posToInsert = self.lineNumberView.lineIndices[self.lineNumberView.lineNumberForCharacterIndex(index: cursorPos)]
            if (self.string as NSString).substring(with: NSMakeRange(posToInsert, 2)) == "//" {
                self.replaceSubString(with: StringInsertion(content: "", range: NSMakeRange(posToInsert, 2), cursorOffset: posToInsert - cursorPos + 2))
            } else {
                self.replaceSubString(with: StringInsertion(content: "//", range: NSMakeRange(posToInsert, 0), cursorOffset: posToInsert - cursorPos))
            }
            return
        }
        
        
        if selectedRangeBeforeKeyDown.length > 0 {  // a subString is selected
            guard let leftChar = event.characters else { return }
            
            func wrapSubString() {
                self.replaceSubString(with: StringInsertion(content: leftChar, range: NSMakeRange(cursorPos, 0), cursorOffset: 0))
                let rightChar: String
                switch leftChar {
                case "{":
                    rightChar = "}"
                case "[":
                    rightChar = "]"
                case "(":
                    rightChar = ")"
                case "\"":
                    rightChar = "\""
                case "'":
                    rightChar = "'"
                default:
                    return
                }
                
                let length = selectedRangeBeforeKeyDown.length
                self.replaceSubString(with: StringInsertion(content: rightChar,
                                                            range: NSMakeRange(cursorPos + length + 1, 0),
                                                            cursorOffset: 0))
            }
            
            switch keyCode {
            case 25:
                if let char = event.characters, char == "9" {   // '9'
                    super.keyDown(with: event)
                    return
                } else {
                    wrapSubString() // '('
                }
            case 33, 39:    // 33: [ { 39: ' "
                wrapSubString()
            default:
                super.keyDown(with: event)
            }
            
        } else {
            super.keyDown(with: event)
            cursorPos = self.selectedRange().lowerBound
            
            switch keyCode {
            case 25:    // 9 or (
                if let char = event.characters, char == "(" {
                    fallthrough
                }
            case 33:    // 33: [ { 
                guard let leftChar = event.characters else { return }
                
                let rightChar: String
                switch leftChar {
                case "{":
                    rightChar = "}"
                case "[":
                    rightChar = "]"
                case "(":
                    rightChar = ")"
                default:
                    return
                }
                
                self.replaceSubString(with: StringInsertion(content: rightChar, range: NSMakeRange(cursorPos, 0), cursorOffset: 1))
            case 39:
                guard let leftChar = event.characters else { return }
                if cursorPos < self.string.count {
                    let nextCharacter = (self.string as NSString).substring(with: NSMakeRange(cursorPos, 1))
                    switch nextCharacter {
                    case "\"":
                        if regxSet.doubleQuotationMark.matches(in: self.string,
                                                               options: [],
                                                               range: NSMakeRange(0, cursorPos)).count % 2 == 0 {
                            self.replaceSubString(with: StringInsertion(content: "", range: NSMakeRange(cursorPos, 1), cursorOffset: 0))
                            return
                        }
                    case "'":
                        if regxSet.singleQuotationMark.matches(in: self.string,
                                                               options: [],
                                                               range: NSMakeRange(0, cursorPos)).count % 2 == 0 {
                            self.replaceSubString(with: StringInsertion(content: "", range: NSMakeRange(cursorPos, 1), cursorOffset: 0))
                            return
                        }
                    default:
                        // auto pair
                        self.replaceSubString(with: StringInsertion(content: leftChar, range: NSMakeRange(cursorPos, 0), cursorOffset: 1))
                        return;
                    }
                }
            case 29:    // 0 or )
                if let char = event.characters, char == ")" {
                    fallthrough
                } else {
                    return
                }
            case 30:    // ] }
                if cursorPos < self.string.count {
                    let nextCharacter = (self.string as NSString).substring(with: NSMakeRange(cursorPos, 1))
                    
                    var braceDiff = 0
                    switch nextCharacter {
                    case "}":
                        let leftCount = regxSet.leftCurlyBrace.matches(in: self.string,
                                                                       options: [],
                                                                       range: NSMakeRange(0, cursorPos)).count
                        let rightCount = regxSet.rightCurlyBrace.matches(in: self.string,
                                                                         options: [],
                                                                         range: NSMakeRange(0, cursorPos)).count
                        braceDiff = leftCount - rightCount
                    case "]":
                        let leftCount = regxSet.leftSquareBracket.matches(in: self.string,
                                                                          options: [],
                                                                          range: NSMakeRange(0, cursorPos)).count
                        let rightCount = regxSet.rightSquareBracket.matches(in: self.string,
                                                                            options: [],
                                                                            range: NSMakeRange(0, cursorPos)).count
                        braceDiff = leftCount - rightCount
                    case ")":
                        let leftCount = regxSet.leftParenthesis.matches(in: self.string,
                                                                        options: [],
                                                                        range: NSMakeRange(0, cursorPos)).count
                        let rightCount = regxSet.rightParenthesis.matches(in: self.string,
                                                                          options: [],
                                                                          range: NSMakeRange(0, cursorPos)).count
                        braceDiff = leftCount - rightCount
                    default:
                        return
                    }
                    
                    if braceDiff == 0 {
                        self.replaceSubString(with: StringInsertion(content: "", range: NSMakeRange(cursorPos, 1), cursorOffset: 0))
                    }
                }
            case 36:    //enter
                let leftCurlyBraceCount = regxSet.leftCurlyBrace.matches(in: self.string,
                                                                         options: [],
                                                                         range: NSMakeRange(0, cursorPos - 1)).count
                let rightCurlyBraceCount = regxSet.rightCurlyBrace.matches(in: self.string,
                                                                           options: [],
                                                                           range: NSMakeRange(0, cursorPos - 1)).count
                let numberOfSpacesToInsertBefore = (leftCurlyBraceCount - rightCurlyBraceCount) * 4;
                guard numberOfSpacesToInsertBefore > 0 else { return }
                var sequenceToInsert = String(repeating: " ", count: numberOfSpacesToInsertBefore)
                
                var cursorOffset = 0
                if cursorPos < self.string.count {
                    let nextCharacter = (self.string as NSString).substring(with: NSMakeRange(cursorPos, 1))
                    
                    if nextCharacter == "}" {
                        let numberOfSpacesToInsertAfter = numberOfSpacesToInsertBefore - 4
                        sequenceToInsert.append("\n")
                        cursorOffset = 1
                        if numberOfSpacesToInsertAfter > 0 {
                            sequenceToInsert.append(String(repeating: " ", count: numberOfSpacesToInsertAfter))
                        }
                    }
                }
                self.replaceSubString(with: StringInsertion(content: sequenceToInsert,
                                                            range: NSMakeRange(cursorPos, 0),
                                                            cursorOffset: cursorOffset))
            case 48:    // tab
                self.replaceSubString(with: StringInsertion(content: "    ", range: NSMakeRange(cursorPos - 1, 1), cursorOffset: 0))
            default:
                break
            }
        }
    }
    
    public override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        if !self.autoCompleterViewController.view.frame.contains(event.locationInWindow) {
            self.autoCompleterViewController.hideView()
        }
        
    }
}

struct CharacterRegx {
    let leftCurlyBrace = try! NSRegularExpression(pattern: "\\{", options: [])
    let rightCurlyBrace = try! NSRegularExpression(pattern: "\\}", options: [])
    let leftParenthesis = try! NSRegularExpression(pattern: "\\(", options: [])
    let rightParenthesis = try! NSRegularExpression(pattern: "\\)", options: [])
    let leftSquareBracket = try! NSRegularExpression(pattern: "\\[", options: [])
    let rightSquareBracket = try! NSRegularExpression(pattern: "\\]", options: [])
    let singleQuotationMark = try! NSRegularExpression(pattern: "\\'", options: [])
    let doubleQuotationMark = try! NSRegularExpression(pattern: "\\\"", options: [])
}

struct StringInsertion {
    var content: String
    var range: NSRange
    var cursorOffset: Int
}
