//
//  CSXSerialManager.swift
//  CSXSerialManager
//
//  Created by Zhirui Dai on 2018/9/28.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa
import ORSSerial

public class CSXSerialManager: NSObject {
    
    public static let shared: CSXSerialManager = {
        return CSXSerialManager()
    }()
    
    @objc let orsSerialManager = ORSSerialPortManager.shared()
    
    /// Available baudrates
    @objc let availableBaudrates = [300, 1200, 2400, 4800, 9600, 14400, 19200, 28800, 38400, 57600, 115200, 230400]
    
    var bufferDict = [ORSSerialPort : CSXSerialBuffer]()
    
    public override init() {
        super.init()
        // receive notifications about serialports
        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(self.serialPortsWereConnected(_:)),
                       name: NSNotification.Name.ORSSerialPortsWereConnected, object: nil)
        nc.addObserver(self, selector: #selector(self.serialPortsWereDisconnected(_:)),
                       name: NSNotification.Name.ORSSerialPortsWereDisconnected, object: nil)
        // add all ports
        for port in self.orsSerialManager.availablePorts {
            let buffer = CSXSerialBuffer(port: port)
            buffer.delegate = self
            self.bufferDict[port] = buffer
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    public func getSerialBuffer(for serialPort: ORSSerialPort) -> CSXSerialBuffer? {
        return self.bufferDict[serialPort]
    }
    
    public func connectTextViewToPort(with textView: NSTextView, to serialPort: ORSSerialPort) {
        let buffer = self.bufferDict[serialPort]
        buffer?.screenView = textView
        if let view = textView as? SerialOutputView {
            view.userInputDelegate = buffer
        }
    }
}

extension CSXSerialManager {
    @objc func serialPortsWereConnected(_ aNotification: Notification) {
        guard let userInfo = aNotification.userInfo else { return }
        guard let ports = userInfo[ORSConnectedSerialPortsKey] as? [ORSSerialPort] else { return }
        
        for port in ports {
            let buffer = CSXSerialBuffer(port: port)
            buffer.delegate = self
            self.bufferDict[port] = buffer
            
            NotificationCenter.default.post(name: CSXSerialManager.didConnectSerialPortNotification,
                                            object: self,
                                            userInfo: [CSXSerialManager.Key.PortName : port.name])
        }
    }
    
    @objc func serialPortsWereDisconnected(_ aNotification: Notification) {
        guard let userInfo = aNotification.userInfo else { return }
        guard let ports = userInfo[ORSDisconnectedSerialPortsKey] as? [ORSSerialPort] else { return }   // disconnected ports
        
        for port in ports {
            self.bufferDict.removeValue(forKey: port)
            
            NotificationCenter.default.post(name: CSXSerialManager.didDisconnectSerialPortNotification,
                                            object: self,
                                            userInfo: [CSXSerialManager.Key.PortName : port.name])
        }
    }
}

extension CSXSerialManager: CSXSerialBufferDelegate {
    func didOpenSerialPort(_ buffer: CSXSerialBuffer) {
        print("Port \(buffer.serialPort.name) opened")
        NotificationCenter.default.post(name: CSXSerialManager.didOpenSerialPortNotification,
                                        object: self,
                                        userInfo: [CSXSerialManager.Key.Port : buffer.serialPort])
    }
    
    func didCloseSerialPort(_ buffer: CSXSerialBuffer) {
        print("Port \(buffer.serialPort.name) closed")
        NotificationCenter.default.post(name: CSXSerialManager.didCloseSerialPortNotification,
                                        object: self,
                                        userInfo: [CSXSerialManager.Key.Port : buffer.serialPort])
    }
    
    func csxSerialBuffer(_ buffer: CSXSerialBuffer, didReceive request: SerialRequest) {
        print("Receive: \(request.response)")
        NotificationCenter.default.post(name: CSXSerialManager.didReceiveRequestNotification,
                                        object: self,
                                        userInfo: [CSXSerialManager.Key.Port : buffer.serialPort,
                                                   CSXSerialManager.Key.Request : request])
    }
    
    func csxSerialBuffer(_ buffer: CSXSerialBuffer, isTimeout request: SerialRequest) {
        print("Timeout: \(request.response)")
        NotificationCenter.default.post(name: CSXSerialManager.requestIsTimeoutNotification,
                                        object: self,
                                        userInfo: [CSXSerialManager.Key.Port : buffer.serialPort,
                                                   CSXSerialManager.Key.Request : request])
    }
    
    func didRemoveSerialPort(_ buffer: CSXSerialBuffer) {
        NotificationCenter.default.post(name: CSXSerialManager.didRemoveSerialPortNotification,
                                        object: self,
                                        userInfo: [CSXSerialManager.Key.PortName : buffer.serialPort.name])
    }
    
    func didEncounterError(_ buffer: CSXSerialBuffer, error: Error) {
        NotificationCenter.default.post(name: CSXSerialManager.didEncounterErrorNotification,
                                        object: self, userInfo: [CSXSerialManager.Key.PortName : buffer.serialPort.name,
                                                                 CSXSerialManager.Key.Error : error])
    }
    
}

extension CSXSerialManager {
    public static let didConnectSerialPortNotification = NSNotification.Name("didConnectSerialPort")
    public static let didDisconnectSerialPortNotification = NSNotification.Name("didDisconnectSerialPort")
    public static let didReceiveRequestNotification = NSNotification.Name("didReceiveRequest")
    public static let requestIsTimeoutNotification = NSNotification.Name("requestIsTimeout")
    public static let didRemoveSerialPortNotification = NSNotification.Name("didRemoveSerialPort")
    public static let didEncounterErrorNotification = NSNotification.Name("didEncounterError")
    public static let didOpenSerialPortNotification = NSNotification.Name("didOpenSerialPort")
    public static let didCloseSerialPortNotification = NSNotification.Name("didCloseSerialPort")
    public enum Key: String {
        case Port = "Port"
        case PortName = "PortName"
        case Request = "Request"
        case Error = "Error"
    }
}
