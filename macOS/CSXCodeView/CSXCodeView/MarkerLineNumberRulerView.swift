//
//  MarkerLineNumberRulerView.swift
//  CSXTextView
//
//  Created by Zhirui Dai on 2018/7/11.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

class MarkerLineNumberRulerView: LineNumberRulerView {

    private var markerImage: NSImage?
    private var markerHeight: CGFloat = 0.0
    
    override var ruleThickness: CGFloat {
        didSet {
            super.ruleThickness = ruleThickness
            self.markerImage?.size = NSMakeSize(self.ruleThickness, self.markerHeight)
        }
    }
    
    deinit {
        self.markerImage = nil
    }
    
    @objc private func drawMarkerImageIntoRep(rep: NSCustomImageRep) {
        
        let path = NSBezierPath()
        let maxX: CGFloat = rep.size.width - 2.0
        let minX: CGFloat = 0.0
        let maxY: CGFloat = rep.size.height
        let minY: CGFloat = 0.0
        let midY: CGFloat = minY + rep.size.height / 2
        path.move(to: NSMakePoint(maxX, midY))
        path.line(to: NSMakePoint(maxX - 5.0, maxY))
        path.line(to: NSMakePoint(minX, maxY))
        path.line(to: NSMakePoint(minX, minY))
        path.line(to: NSMakePoint(maxX - 5.0, minY))
        path.line(to: NSMakePoint(maxX, midY))
        path.close()
        
        NSColor(calibratedRed: 0, green: 0.56, blue: 0.85, alpha: 1.0).set()
        path.fill()
    }
    
    private func markerImageWithSize(size: NSSize) -> NSImage {
        if (self.markerImage == nil) {
            let rep: NSCustomImageRep
            self.markerImage = NSImage(size: size)
            rep = NSCustomImageRep(draw: #selector(self.drawMarkerImageIntoRep(rep:)), delegate: self)
            rep.size = size
            markerImage?.addRepresentation(rep)
        }
        return self.markerImage!
    }
    
    override internal func mouseDown(with event: NSEvent) {

        let location = self.convert(event.locationInWindow, from: nil)
        let line = self.lineNumberForLocation(location: location.y)
        
        if line != NSNotFound {
            if let marker = self.markerAtLine(lineNumber: line) {
                self.removeMarker(marker)
            } else {
                guard let font = self.textView.font else { return }
                guard let layoutManager = self.textView.layoutManager else { return }
                self.markerHeight = layoutManager.defaultLineHeight(for: font)
                let marker = LineNumberRulerMarker(rulerView: self, markerLocation: CGFloat(line),
                                                    image: self.markerImageWithSize(size: NSMakeSize(self.bounds.width, self.markerHeight)), imageOrigin: NSMakePoint(0, markerHeight / 2))
                self.addMarker(marker: marker)
            }
            self.needsDisplay = true
        }
    }
}
