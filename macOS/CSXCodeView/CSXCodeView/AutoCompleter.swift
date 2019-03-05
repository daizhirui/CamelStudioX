//
//  AutoCompleter.swift
//  CSXCodeView
//
//  Created by Zhirui Dai on 2018/10/3.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

class AutoCompleter: NSObject {
    static let reservedCppWords = ["asm", "auto", "bool", "break", "case", "catch",
                                   "char", "class", "const", "continue", "default", "delete",
                                   "do", "double", "dynamic_cast", "else", "enum", "explicit",
                                   "export", "extern", "false", "float", "for", "friend",
                                   "goto", "if", "inline", "int", "long", "mutable",
                                   "namespace", "new", "operator", "private", "protected", "public",
                                   "register", "reinterpret_cast", "return", "short", "signed", "sizeof",
                                   "static", "static_cast", "struct", "switch", "template", "this",
                                   "throw", "true", "try", "typedef", "typeid", "typename",
                                   "union", "unsigned", "using", "virtual", "void", "volatile", "wchar_t", "while"]
    
    static func lexer(content: String) -> Set<String> {
        guard let contentData = content.data(using: .utf8) else { return [] }
        
        let process = Process()
        
        if #available(macOS 10.13, *) {
            process.executableURL = Bundle(for: AutoCompleter.self).url(forResource: "lexer", withExtension: nil)
        } else {
            process.launchPath = Bundle(for: AutoCompleter.self).url(forResource: "lexer", withExtension: nil)?.relativePath
        }
        
        let stdin = Pipe()
        let stdout = Pipe()
        let stderr = Pipe()
        
        process.standardInput = stdin
        process.standardOutput = stdout
        process.standardError = stderr
        
        process.launch()
        
        stdin.fileHandleForWriting.write(contentData)
        stdin.fileHandleForWriting.closeFile()
        let result = String(data: stdout.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8)
        
        guard let unwrappedResult = result else { return [] }
        var words = Set(unwrappedResult.components(separatedBy: .newlines))
        words.remove("")
        return words.union(AutoCompleter.reservedCppWords)
    }
    
    override init() {
        super.init()
        self.words = AutoCompleter.lexer(content: "")
    }
    
    var textView: NSTextView? {
        willSet {
            guard let textStorage = self.textView?.textStorage as? CodeTextStorage else { return }
            NotificationCenter.default.removeObserver(self, name: NSTextStorage.didProcessEditingNotification, object: textStorage)
        }
        didSet {
            guard let textStorage = self.textView?.textStorage as? CodeTextStorage else { return }
            NotificationCenter.default.addObserver(self, selector: #selector(self.textViewDidEditText(_:)),
                                                   name: NSTextStorage.didProcessEditingNotification, object: textStorage)
        }
    }
    var words = Set<String>()
    var currentWord = ""
    var lexerTimer: Timer?
    public var isEnabled = true
    var delegate: AutoCompleterDelegate?
    @objc func textViewDidEditText(_ notification: NSNotification) {
        // update `words`
        self.lexerTimer?.invalidate()
        // 2-second delay to avoid frequent updating `words`
        self.lexerTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(0.5), repeats: false, block: { (timer) in
            if self.isEnabled {
                guard let textView = self.textView else { return }
                // current word should not be contained
                self.words = AutoCompleter.lexer(content: textView.string).subtracting([self.currentWord])
            }
        })
        
        if self.isEnabled {
            guard let textView = self.textView else { return }
            let end = min(textView.string.count, textView.selectedRange().lowerBound)
            guard let currentWord = (textView.string as NSString).substring(with: NSMakeRange(0, end)).components(separatedBy: .whitespacesAndNewlines).last else { return }
            self.currentWord = currentWord
            var possibleWords = Set<String>()
            if currentWord.count > 0 {
                for word in self.words {
                    if word.hasPrefix(currentWord) {
                        possibleWords.insert(word)
                    }
                }
            }
            
            self.delegate?.autoCompleter(self, didFind: possibleWords.sorted())
        }
    }
}

protocol AutoCompleterDelegate {
    func autoCompleter(_ autoCompleter: AutoCompleter, didFind words: [String])
}
