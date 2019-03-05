//
//  NSViewExtension.swift
//  CSXFileBrowser
//
//  Created by Zhirui Dai on 2018/7/14.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Foundation

extension NSView {
    
    public enum AdjustSubViewFrameOption {
        case squre
    }
    
    public func addSubViewWithQuickLayout(view: NSView,
                                   topDistance: CGFloat?, bottomDistance: CGFloat?,
                                   leadingDistance: CGFloat?, trailingDistance: CGFloat?,
                                   options: [AdjustSubViewFrameOption]) {
        self.addSubview(view)
        
        view.translatesAutoresizingMaskIntoConstraints = false
        
        if let distance1 = topDistance, let distance2 = bottomDistance {
            if options.contains(.squre) {
                view.setFrameSize(NSSize(width: self.frame.height - distance1 - distance2, height: self.frame.height - distance1 - distance2))
            } else {
                view.setFrameSize(NSSize(width: view.frame.width, height: self.frame.height - distance1 - distance2))
            }
        }
        
        if let distance = topDistance {
            let constraint = view.topAnchor.constraint(equalTo: self.topAnchor, constant: distance)
            NSLayoutConstraint.activate([constraint])
        }
        
        if let distance = bottomDistance {
            let constraint = view.bottomAnchor.constraint(equalTo: self.bottomAnchor, constant: -distance)
            NSLayoutConstraint.activate([constraint])
        }
        
        if let distance = leadingDistance {
            let constraint = view.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: distance)
            NSLayoutConstraint.activate([constraint])
        }
        
        if let distance = trailingDistance {
            let constraint = view.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -distance)
            NSLayoutConstraint.activate([constraint])
        }

    }
}
