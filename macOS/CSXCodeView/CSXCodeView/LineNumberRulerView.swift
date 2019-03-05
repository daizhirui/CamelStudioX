//
//  LineNumberRulerView.swift
//  CSXTextView
//
//  Created by Zhirui Dai on 2018/7/11.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

fileprivate let DEFAULT_THICKNESS: CGFloat = 22.0
fileprivate let RULER_MARGIN: CGFloat = 10.0
fileprivate let NULL_RANGE = NSMakeRange(NSNotFound, 0)
fileprivate let FONT_CODING_KEY = "font"
//fileprivate let TEXT_HIGHLIGHT_COLOR_CODING_KEY = "textHighlightColor"
fileprivate let ALT_TEXT_COLOR_CODING_KEY = "alternateTextColor"
fileprivate let BACKGROUND_COLOR_CODING_KEY = "backgroundColor"

class LineNumberRulerView: NSRulerView {
    
    // String indices of the beginings of lines
    var lineIndices: [Int]! {
        didSet {
            if self.lineIndices == nil {
                self.calculateLineIndices()
            }
        }
    }
    var linePositions = [CGFloat]()
    // MARK:- UI Attributes
    var textView: NSTextView! {
        didSet {
            self.layoutManager = self.textView.layoutManager!
            self.textContainer = self.textView.textContainer!
        }
    }
    private var layoutManager: NSLayoutManager!
    private var textContainer: NSTextContainer!
    private var selectedLines = [Int]()
    // Maps line numbers to markers
    var linesToMarkers: [Int : LineNumberRulerMarker]
    private var font: NSFont
    private let textColor = NSColor.gray
    private var textHighlightColor: NSColor {
        get {
            let color = self.backgroundColor.usingColorSpace(.deviceRGB)!
            let red = color.redComponent
            let blue = color.blueComponent
            let green = color.greenComponent
            if (red + blue + green) / 3 > 0.5 {
                return NSColor.black
            } else {
                return NSColor.white
            }
        }
    }
    private func textAttributes() -> [NSAttributedString.Key : Any] {
        var dict = [NSAttributedString.Key : Any]()
        dict[NSAttributedString.Key.font] = self.font
        dict[NSAttributedString.Key.foregroundColor] = self.textColor
        return dict
    }
    private func textAttributes(forLine: Int) -> [NSAttributedString.Key : Any] {
        var dict = self.textAttributes()
        if self.selectedLines.contains(forLine) {
            dict[NSAttributedString.Key.foregroundColor] = self.textHighlightColor
        }
        return dict
    }
    private var markerTextAttributes: [NSAttributedString.Key : Any] {
        get {
            var dict = [NSAttributedString.Key : Any]()
            dict[NSAttributedString.Key.font] = self.font
            dict[NSAttributedString.Key.foregroundColor] = self.alternateTextColor
            return dict
        }
    }
    private var alternateTextColor: NSColor
    var backgroundColor: NSColor
    
    // MARK:- Override attributes
    override var requiredThickness: CGFloat {
        get {
            let count = self.lineIndices.max() ?? 1
            let digits = Int(log10(Double(count + 1)) + 1)
            let sampleString = NSMutableString()
            for _ in 0..<digits {
                sampleString.append("8")    // 8 is the fattest number
            }
            let stringSize = sampleString.size(withAttributes: self.textAttributes())
            let thickness = CGFloat(max(DEFAULT_THICKNESS, stringSize.width + RULER_MARGIN * 2.0))
            return thickness
        }
    }
    
    // MARK:- Init and deinit
    override init(scrollView: NSScrollView?, orientation: NSRulerView.Orientation) {
        self.lineIndices = [0]
        self.linesToMarkers = [Int : LineNumberRulerMarker]()
        self.font = NSFont.systemFont(ofSize: 10)
        self.alternateTextColor = NSColor.white
        self.backgroundColor = NSColor.white
        super.init(scrollView: scrollView, orientation: orientation)
        if let aTextView = scrollView?.documentView as? NSTextView {
            self.setClientView(view: aTextView)
        }
    }
    
    required init(coder: NSCoder) {
        self.lineIndices = [Int]()
        self.linesToMarkers = [Int : LineNumberRulerMarker]()
        if coder.allowsKeyedCoding {
            self.font = coder.decodeObject(forKey: FONT_CODING_KEY) as! NSFont
//            self.textHighlightColor = coder.decodeObject(forKey: TEXT_HIGHLIGHT_COLOR_CODING_KEY) as! NSColor
            self.alternateTextColor = coder.decodeObject(forKey: ALT_TEXT_COLOR_CODING_KEY) as! NSColor
            self.backgroundColor = coder.decodeObject(forKey: BACKGROUND_COLOR_CODING_KEY) as! NSColor
        } else {
            self.font = NSFont.systemFont(ofSize: 10)
//            self.textHighlightColor = NSColor.black
            self.alternateTextColor = NSColor.white
            self.backgroundColor = NSColor.white
        }
        super.init(coder: coder)
    }
    
    override func encode(with aCoder: NSCoder) {
        super.encode(with: aCoder)
        if aCoder.allowsKeyedCoding {
            aCoder.encode(self.font, forKey: FONT_CODING_KEY)
//            aCoder.encode(self.textColor, forKey: TEXT_HIGHLIGHT_COLOR_CODING_KEY)
            aCoder.encode(self.alternateTextColor, forKey: ALT_TEXT_COLOR_CODING_KEY)
            aCoder.encode(self.backgroundColor, forKey: BACKGROUND_COLOR_CODING_KEY)
        } else {
            aCoder.encode(self.font)
            aCoder.encode(self.textColor)
            aCoder.encode(self.alternateTextColor)
            aCoder.encode(self.backgroundColor)
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
        self.lineIndices.removeAll()
        self.linesToMarkers.removeAll()
    }
    
    private func setClientView(view: NSTextView) {
        if let oldTextView = self.clientView as? NSTextView {
            NotificationCenter.default.removeObserver(self, name: NSTextStorage.didProcessEditingNotification, object: oldTextView.textStorage)
            NotificationCenter.default.removeObserver(self, name: NSTextView.didChangeSelectionNotification, object: oldTextView)
        }
        self.clientView = view
        if let newTextView = self.clientView as? NSTextView {
            self.textView = newTextView
            if let font = newTextView.font {
                self.font = font
            }
            self.backgroundColor = newTextView.backgroundColor
            NotificationCenter.default.addObserver(self, selector: #selector(self.textDidChange(_:)), name: NSTextStorage.didProcessEditingNotification, object: newTextView.textStorage)
            NotificationCenter.default.addObserver(self, selector: #selector(self.textSelectionDidChange(_:)), name: NSTextView.didChangeSelectionNotification, object: newTextView)
        }
    }
    @objc private func textDidChange(_ aNotification: NSNotification) {
        self.shouldRecalculateLineIndices()
        self.needsDisplay = true
    }
    @objc private func textSelectionDidChange(_ aNotification: NSNotification) {
        self.updateSelectedLineIndices()
        self.needsDisplay = true
    }
    
    // MARK:- Marker Operation
    internal func addMarkers(markers: [LineNumberRulerMarker]) {
        
        for marker in markers {
            self.linesToMarkers[marker.lineNumber] = marker
        }
    }
    internal func addMarker(marker: LineNumberRulerMarker) {
        
        self.linesToMarkers[marker.lineNumber] = marker
    }
    internal func removeMarker(_ marker: LineNumberRulerMarker) {
        
        self.linesToMarkers.removeValue(forKey: marker.lineNumber)
    }
    /// get the marker for the line
    internal func markerAtLine(lineNumber: Int) -> LineNumberRulerMarker? {
        return self.linesToMarkers[lineNumber]
    }
    
    // MARK:- Line Index Calculation
    private func shouldRecalculateLineIndices() {
        self.lineIndices = nil
    }
    
    /// Get the line number from the screen location
    internal func lineNumberForLocation(location: CGFloat) -> Int {
        
        // get visible rect
        guard let visibleRect = self.scrollView?.contentView.bounds else { return NSNotFound }
        // 'location' is based on the window's coordinate system
        // we should convert it with the visibleRect's coordinate system
        let newLocation = location + NSMinY(visibleRect)
        
        var rectCount = 0
        // line number here starts from 0, this is a internal function so it is okay to start from 0.
        for (lineNumber, stringIndex) in self.lineIndices.enumerated() {
            guard let rects = self.layoutManager.rectArray(forCharacterRange: NSMakeRange(stringIndex, 0),
                                                           withinSelectedCharacterRange: NULL_RANGE,
                                                           in: self.textContainer,
                                                           rectCount: &rectCount)
                else { return NSNotFound }
            
            for rectIndex in 0..<rectCount {
                if newLocation >= NSMinY(rects[rectIndex]) && newLocation < NSMaxY(rects[rectIndex]) {
                    return lineNumber
                }
            }
        }
        
        return NSNotFound
    }
    func lineNumberForCharacterIndex(index: Int) -> Int {
        
        if index >= self.lineIndices.last! {
            return self.lineIndices.count - 1   // final line
        }
        
        if index < self.lineIndices.first! {
            return 0                            // first line
        }
        
        var left = 0
        var right = self.lineIndices.count - 1
        var mid = 0
        var lineStart = 0
        
        while right - left > 1 {
            mid = (right + left) / 2
            lineStart = self.lineIndices[mid]
            if (index < lineStart) { right = mid }
            else if (index > lineStart) { left = mid }
            else { return mid }
        }
        return left
    }
    /// calculate the beginning index in the content string of every line
    private func calculateLineIndices() {
        
        if let aTextView = self.clientView as? NSTextView {
            // prepare
            let textContent = aTextView.string
            let stringLength = textContent.count
            self.lineIndices = [0]
            
            // calculate the number of lines and store the position of the beginning of every line
            guard let newlineRegularExp = try? NSRegularExpression(pattern: "\\n", options: []) else { return }
            newlineRegularExp.enumerateMatches(in: textContent, options: [], range: NSMakeRange(0, stringLength)) {
                (result, flags, pointer) in
                if let unwrappedResult = result {
                    self.lineIndices.append(unwrappedResult.range.upperBound)
                }
            }
            
            let oldThickness = self.ruleThickness
            let newThickness = self.requiredThickness
            
            if abs(oldThickness - newThickness) > 1 {
                DispatchQueue.main.async {
                    self.ruleThickness = newThickness
                }
            }
            
            self.updateSelectedLineIndices()
        }
    }
    
    private func updateSelectedLineIndices() {
        self.selectedLines.removeAll()
        let lowerBound = self.textView.selectedRange().lowerBound
        let upperBound = self.textView.selectedRange().upperBound
        let minIndex = self.lineNumberForCharacterIndex(index: lowerBound)
        let maxIndex = self.lineNumberForCharacterIndex(index: upperBound)
        self.selectedLines.append(minIndex)
        for index in minIndex...maxIndex {
            self.selectedLines.append(index)
        }
    }
    
    override func drawHashMarksAndLabels(in rect: NSRect) {
        
        self.backgroundColor.set()
        self.bounds.fill()
        
        NSColor(calibratedWhite: 0.9, alpha: 1.0).set()
        NSBezierPath.strokeLine(from: NSMakePoint(NSMaxX(self.bounds) - 0.5, NSMinX(self.bounds)),
                                to: NSMakePoint(NSMaxX(self.bounds) - 0.5, NSMaxY(self.bounds)))
        
        if let visibleRect = self.scrollView?.contentView.bounds {
            
            // find the characters that are currently visible
            let glyphRange = self.layoutManager.glyphRange(forBoundingRect: visibleRect,
                                                           in: textContainer)
            var range = self.layoutManager.characterRange(forGlyphRange: glyphRange, actualGlyphRange: nil)
            
            // fudge that range a tad in case there is an extra new line at end
            // It doesn't show up in the glyphs so would not be accounted for.
            range.length += 1
            
            var index = 0       // string index of the beginning of a line
            var line = self.lineNumberForCharacterIndex(index: range.location)  // get the start line number
            
            // draw line number
            while line < self.lineIndices.count, index < NSMaxRange(range) {
                index = self.lineIndices[line]
                var currentTextAttributes: [NSAttributedString.Key : Any]
                if range.upperBound > self.textView.string.count {
                    range.length -= self.textView.string.count - range.upperBound
                }
                // the location is in this range
                if NSLocationInRange(index, range) {
                    var rectCount = 0
                    guard let rects = self.layoutManager.rectArray(forCharacterRange: NSMakeRange(index, 0),
                                                                   withinSelectedCharacterRange: NULL_RANGE,
                                                                   in: textContainer,
                                                                   rectCount: &rectCount)
                        else { return }
                    if line < self.linePositions.count {
                        self.linePositions[line] = rects[0].origin.y
                    } else {
                        self.linePositions.append(rects[0].origin.y)
                    }
                    if rectCount > 0 {
                        // Note that the ruler view is only as tall as the visible
                        // portion. Need to compensate for the clipview's coordinates
                        // rects is in the whole document view, but visible rect is the clipView
                        let yPos, yInset: CGFloat
                        yInset = self.textView.textContainerInset.height
                        yPos = yInset + NSMinY(rects[0]) - NSMinY(visibleRect)
                        // draw marker
                        if let marker = self.linesToMarkers[line] {
                            let markerImage = marker.image
                            let markerSize = markerImage.size
                            // marker is flush right and centered vertically within the line
                            let x = NSWidth(bounds) - markerSize.width
                            let y = yPos + NSHeight(rects[0]) / 2.0 - marker.imageOrigin.y
                            let markerRect = NSMakeRect(x, y, markerSize.width, markerSize.height)
                            markerImage.draw(in: markerRect,
                                             from: NSMakeRect(0, 0, markerSize.width, markerSize.height),
                                             operation: NSCompositingOperation.sourceOver, fraction: 1.0)
                            currentTextAttributes = self.markerTextAttributes
                        } else {
                            currentTextAttributes = self.textAttributes(forLine: line)
                        }
                        
                        // Line numbers are internally stored starting at 0
                        let labelText = "\(line + 1)"
                        let stringSize = labelText.size(withAttributes: currentTextAttributes)
                        // draw string flush right, centered vertically within the line
                        labelText.draw(in: NSMakeRect(NSWidth(bounds) - stringSize.width - RULER_MARGIN,
                                                      yPos + (NSHeight(rects[0]) - stringSize.height) / 2.0,
                                                      NSWidth(bounds) - RULER_MARGIN * 2.0,
                                                      NSHeight(rects[0])),
                                       withAttributes:currentTextAttributes)
                    }
                } // End of NSLocationInRange
                
                line += 1   // move to next line
            } // End of while
        }
    }
}
