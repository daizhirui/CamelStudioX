//
//  CSXSerialBuffer.swift
//  CSXSerialManager
//
//  Created by Zhirui Dai on 2018/9/28.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa
import ORSSerial

public enum SerialPortMode {
    case normal, request, upload
}

public class CSXSerialBuffer: NSObject {
    
    public var screenView: NSTextView?
    var autoScroll = true
    var serialPort: ORSSerialPort
    var delegate: CSXSerialBufferDelegate?
    var serialPortMode: SerialPortMode = .normal {
        didSet {
            if self.serialPortMode != .normal {
                
                if self.requestCheckTimer == nil {
                    self.requestCheckTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(0.1), repeats: true, block: { (timer) in
                        // Closure
                        if self.serialPortMode != .normal, self.requestInProcess == nil, let request = self.requestQueue.first {
                            /*
                             - serialPortMode is not normal
                             - no request is in process
                             - there is any request to process
                             */
                            self.requestInProcess = request
                            self.sendString(request.command)
                            self.requestTimeoutTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(request.timeout),
                                                                            repeats: false, block: { (timer) in
                                                                                self.delegate?.csxSerialBuffer(self, isTimeout: request)
                                                                                if self.requestQueue.count > 0 {
                                                                                    self.requestQueue.removeFirst()
                                                                                }
                                                                                self.requestInProcess = nil
                            })
                        }
                    })
                }
                
                self.requestCheckTimer?.fire()
            } else {
                self.reset()
            }
        }
    }
    var data: Data = Data()
    var string: String = ""
    var requestQueue = [SerialRequest]()
    var requestInProcess: SerialRequest?
    static var requestDispatch = DispatchQueue(label: "com.daizhirui.csxSerialBufferRequest")
    var requestCheckTimer: Timer?
    var requestTimeoutTimer: Timer? = nil
    
    init(port: ORSSerialPort) {
        self.serialPort = port
        super.init()
        port.delegate = self
    }
    
    deinit {
        self.serialPort.close()
        self.reset()
    }
    
    func reset() {
        self.requestQueue.removeAll()
        self.requestInProcess = nil
        self.requestCheckTimer?.invalidate()
        self.requestCheckTimer = nil
        self.requestTimeoutTimer?.invalidate()
        self.requestTimeoutTimer = nil
    }
    
    public func addRequest(request: SerialRequest) {
        self.requestQueue.append(request)
    }
    
    func processRequest() {
        
        if self.serialPortMode != .normal, let request = self.requestInProcess, self.string.count > request.searchingRangeLength {

            let matches = request.regularExpr.matches(in: self.string, options: [],
                                                      range: NSMakeRange((self.string as NSString).length - request.searchingRangeLength - 1,
                                                                         request.searchingRangeLength))
            if matches.count > 0 {  // the request is matched, inform the delegate
                self.requestTimeoutTimer?.invalidate()
                self.requestTimeoutTimer = nil
                // info delegate and remove the request from the queue
                self.requestInProcess = nil
                self.delegate?.csxSerialBuffer(self, didReceive: self.requestQueue.removeFirst())
                DispatchQueue.main.async {
                    request.execute?()
                }
            }
            
        } // End of if
    }
}

extension CSXSerialBuffer {
    
    func openPort() {
        self.serialPort.open()
    }
    
    func closePort() {
        self.serialPort.close()
    }
    
    func openOrClosePort() {
        if self.serialPort.isOpen {
            self.serialPort.close()
        } else {
            self.serialPort.open()
        }
    }
    
    var portIsOpened: Bool {
        get {
            return self.serialPort.isOpen
        }
    }
    
    func sendString(_ aString: String, using encoding: String.Encoding = .ascii) {
        if let data = aString.data(using: encoding), self.serialPort.isOpen {
            self.serialPort.send(data)
        } else {
            self.delegate?.didEncounterError(self, error: CSXSerialBufferError.STRING_ENCODING_ERROR)
        }
    }
    
}

extension CSXSerialBuffer: ORSSerialPortDelegate {
    public func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
        self.delegate?.didRemoveSerialPort(self)
    }
    
    public func serialPort(_ serialPort: ORSSerialPort, didEncounterError error: Error) {
        self.serialPort.close()
        self.delegate?.didEncounterError(self, error: error)
    }
    
    public func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        
        if let aString = String(data: data, encoding: .ascii) {
            self.string.append(aString)
            if self.requestInProcess != nil {
                CSXSerialBuffer.requestDispatch.sync {
                    self.processRequest()   // check request
                }
            }
            if let view = self.screenView {
                let attributedString = NSAttributedString(string: aString, attributes: [NSAttributedString.Key.foregroundColor : view.textColor!])
                view.textStorage?.append(attributedString)
                view.pageDownAndModifySelection(nil)
                if self.autoScroll {
                    view.scrollToEndOfDocument(self)
                }
            }
            
        } else {
            self.delegate?.didEncounterError(self, error: CSXSerialBufferError.STRING_ENCODING_ERROR)
        }
    }
    
    public func serialPortWasOpened(_ serialPort: ORSSerialPort) {
        self.delegate?.didOpenSerialPort(self)
    }
    
    public func serialPortWasClosed(_ serialPort: ORSSerialPort) {
        self.delegate?.didCloseSerialPort(self)
    }
}

extension CSXSerialBuffer: SerialOutputViewDelegate {
    func serialOutputView(_ textView: SerialOutputView, userDidInput content: String) {
        self.sendString(content)
    }
    
}

protocol CSXSerialBufferDelegate {
    func csxSerialBuffer(_ buffer: CSXSerialBuffer, didReceive request: SerialRequest)
    func csxSerialBuffer(_ buffer: CSXSerialBuffer, isTimeout request: SerialRequest)
    func didRemoveSerialPort(_ buffer: CSXSerialBuffer)
    func didEncounterError(_ buffer: CSXSerialBuffer, error: Error)
    func didOpenSerialPort(_ buffer: CSXSerialBuffer)
    func didCloseSerialPort(_ buffer: CSXSerialBuffer)
}

enum CSXSerialBufferError: String, Error, LocalizedError {
    case STRING_ENCODING_ERROR = "Fail to encode the string"
    
    var localizedDescription: String {
        get {
            return self.rawValue
        }
    }
}
