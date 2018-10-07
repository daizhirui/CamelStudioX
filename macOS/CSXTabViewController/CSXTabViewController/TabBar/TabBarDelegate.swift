//
//  File.swift
//  TabViewController
//
//  Created by Zhirui Dai on 2018/6/26.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa

@objc protocol TabBarDelegate {
//    @objc optional func tabBar(_ tabBar: TabBar, willSelect tab: Tab)
    @objc optional func tabBar(_ tabBar: TabBar, didSelect tab: Tab)
//    @objc optional func tabBar(_ tabBar: TabBar, willClose tab: Tab)
    @objc optional func tabBar(_ tabBar: TabBar, didClose tab: Tab)
}
