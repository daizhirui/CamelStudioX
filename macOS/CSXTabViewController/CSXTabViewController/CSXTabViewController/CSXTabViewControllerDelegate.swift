//
//  CSXTabViewControllerDelegate.swift
//  CSXTabViewController
//
//  Created by Zhirui Dai on 2018/6/26.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Foundation

@objc public protocol CSXTabViewControllerDelegate {
    @objc optional func csxTabViewController(_ csxTabViewController: CSXTabViewController, willChange selection: Int)
    @objc optional func csxTabViewController(_ csxTabViewController: CSXTabViewController, didChange selection: Int)
    @objc optional func csxTabViewController(_ csxTabViewController: CSXTabViewController, willClose selection: Int)
    @objc optional func csxTabViewController(_ csxTabViewController: CSXTabViewController, didClose selection: Int)
}
