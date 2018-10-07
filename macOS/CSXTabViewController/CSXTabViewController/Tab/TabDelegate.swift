//
//  TabDelegate.swift
//  TabViewController
//
//  Created by Zhirui Dai on 2018/6/26.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

protocol TabDelegate {
    func tabIsSelected(_ tab: Tab)
    func tabIsAskedToClose(_ tab: Tab)
}
