//
//  CSXUploader.swift
//  CSXSerialManager
//
//  Created by Zhirui Dai on 2018/10/3.
//  Copyright © 2018 Zhirui Dai. All rights reserved.
//

import Cocoa
import ORSSerial

class CSXUploader: NSObject {
    
    enum UploadStage: Int {
        case checkRootSpace     = 1
        case setBaudrate19200   = 2
        case eraseFlash         = 3
        case checkFlash         = 4
        case sendBinary         = 5
        case setBaudrate9600    = 6
    }
    
    let csxSerialManager: CSXSerialManager
    var delegate: CSXUploaderDelegate?
    weak var buffer: CSXSerialBuffer?
    var heartBeatTimer: Timer?
    
    init(csxSerialManager: CSXSerialManager) {
        self.csxSerialManager = csxSerialManager
        super.init()
        NotificationCenter.default.addObserver(self, selector: #selector(self.receiveResponse(_:)),
                                               name: CSXSerialManager.didReceiveRequestNotification, object: self.csxSerialManager)
        NotificationCenter.default.addObserver(self, selector: #selector(self.requestTimeout(_:)),
                                               name: CSXSerialManager.requestIsTimeoutNotification, object: self.csxSerialManager)
        NotificationCenter.default.addObserver(self, selector: #selector(self.serialPortDisconnected(_:)),
                                               name: CSXSerialManager.didDisconnectSerialPortNotification, object: self.csxSerialManager)
        NotificationCenter.default.addObserver(self, selector: #selector(self.serialPortEncounterError(_:)),
                                               name: CSXSerialManager.didEncounterErrorNotification, object: self.csxSerialManager)
        NotificationCenter.default.addObserver(self, selector: #selector(self.serialPortIsClosed(_:)),
                                               name: CSXSerialManager.didCloseSerialPortNotification, object: self.csxSerialManager)
    }
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func receiveResponse(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if self.checkPortInNotification(notification) {
            guard let request = userInfo[CSXSerialManager.Key.Request] as? SerialRequest else { return }
            guard let stage = request.userInfo.first as? CSXUploader.UploadStage else { return }
            self.delegate?.csxUploader(self, didFinish: stage)
        }
    }
    
    @objc func requestTimeout(_ notification: Notification) {
        if self.checkPortInNotification(notification) {
            self.stopUpload()
            self.delegate?.csxUploader(self, failure: "Request is timeout")
        }
    }
    
    @objc func serialPortDisconnected(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if self.checkPortInNotification(notification) {
            self.stopUpload()
            let port = userInfo[CSXSerialManager.Key.PortName] as? String
            self.delegate?.csxUploader(self, failure: "\(port ?? "Serialport") is disconnected")
        }
    }
    
    @objc func serialPortEncounterError(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if self.checkPortInNotification(notification) {
            self.stopUpload()
            guard let error = userInfo[CSXSerialManager.Key.Error] as? Error else {
                self.delegate?.csxUploader(self, failure: "Unknown serialport error")
                return
            }
            self.delegate?.csxUploader(self, failure: error.localizedDescription)
        }
    }
    
    @objc func serialPortIsClosed(_ notification: Notification) {
        guard let userInfo = notification.userInfo else { return }
        if self.checkPortInNotification(notification) {
            self.stopUpload()
            let port = userInfo[CSXSerialManager.Key.Port] as? ORSSerialPort
            self.delegate?.didCloseSerialPort(self, portName: port?.name ?? "")
        }
    }
    
    func checkPortInNotification(_ notification: Notification) -> Bool {
        guard let userInfo = notification.userInfo else { return false }
        guard let port = userInfo[CSXSerialManager.Key.Port] as? ORSSerialPort else { return false }
        return port.name == self.buffer?.serialPort.name
    }
    
    func upload(with binaryURL: URL, to buffer: CSXSerialBuffer, targetAddress: String) {
        self.buffer = buffer
        buffer.serialPort.baudRate = 9600
        if !buffer.serialPort.isOpen {
            buffer.serialPort.open()
        }
        buffer.serialPortMode = .upload
        
        let setBaudrate9600Request3 = SerialRequest(command: "\n", response: "hello", searchingRangeLength: 10, timeout: 10,
                                                     userInfo: [CSXUploader.UploadStage.setBaudrate9600], execute: {
                                                        buffer.serialPortMode = .normal
                                                        self.delegate?.didUploadSuccessfully(self)
        })!
        let setBaudrate9600Request2 = SerialRequest(command: "1f800702\n", response: "Value in hex>", searchingRangeLength: 20, timeout: 10,
                                                     userInfo: [CSXUploader.UploadStage.setBaudrate9600], execute: {
                                                        self.buffer?.sendString("00000000\n")   // baudrate=9600
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
                                                            self.buffer?.serialPort.baudRate = 9600
                                                            self.nextStep(with: setBaudrate9600Request3)
                                                        })
        })!
        let setBaudrate9600Request1 = SerialRequest(command: "1", response: "Address in hex>", searchingRangeLength: 20, timeout: 10,
                                                     userInfo: [CSXUploader.UploadStage.setBaudrate9600], execute: {
                                                        self.nextStep(with: setBaudrate9600Request2)
        })!
        let sendBinaryRequest3 = SerialRequest(command: "\n", response: "hello", searchingRangeLength: 10, timeout: 10,
                                               userInfo: [CSXUploader.UploadStage.sendBinary], execute: {
                                                self.heartBeatTimer?.invalidate()
                                                self.heartBeatTimer = nil
                                                self.nextStep(with: setBaudrate9600Request1)
        })!
        let sendBinaryRequest2 = SerialRequest(command: "\(targetAddress.uppercased())\n",
                                               response: "Waiting for binary image linked at \(targetAddress.uppercased())",
                                               searchingRangeLength: 200, timeout: 10, userInfo: [CSXUploader.UploadStage.sendBinary],
                                               execute: {
                                                guard let binaryData = try? Data(contentsOf: binaryURL) else {
                                                    self.delegate?.csxUploader(self, failure: "Fail to read the binray")
                                                    self.stopUpload()
                                                    return
                                                }
                                                self.buffer?.serialPort.send(binaryData)
                                                DispatchQueue.main.asyncAfter(deadline: .now() + 1, execute: {
                                                    self.heartBeatTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(0.5), repeats: true, block: { (timer) in
                                                        print("Heatbeat....")
                                                        self.buffer?.sendString(" ")
                                                    })
                                                    self.nextStep(with: sendBinaryRequest3)
                                                })
        })!
        let sendBinaryRequest1 = SerialRequest(command: "5", response: "Address in hex>", searchingRangeLength: 20, timeout: 10,
                                               userInfo: [CSXUploader.UploadStage.sendBinary], execute: {
                                                self.nextStep(with: sendBinaryRequest2)
        })!
        let checkFlashRequest3 = SerialRequest(command: "64\n", response: "FFFFFFFF FFFFFFFF FFFFFFFF FFFFFFFF", searchingRangeLength: 200, timeout: 10,
                                               userInfo: [CSXUploader.UploadStage.checkFlash], execute: {
                                                self.nextStep(with: sendBinaryRequest1)
        })!
        let checkFlashRequest2 = SerialRequest(command: "10000000\n", response: "Count in hex>", searchingRangeLength: 20, timeout: 10,
                                               userInfo: [CSXUploader.UploadStage.checkFlash], execute: {
                                                self.nextStep(with: checkFlashRequest3)
        })!
        let checkFlashRequest1 = SerialRequest(command: "4", response: "Address in hex>", searchingRangeLength: 20, timeout: 10,
                                               userInfo: [CSXUploader.UploadStage.checkFlash], execute: {
                                                self.nextStep(with: checkFlashRequest2)
        })!
        let eraseFlashRequest3 = SerialRequest(command: "1\n", response: "hello", searchingRangeLength: 10, timeout: 10,
                                               userInfo: [CSXUploader.UploadStage.eraseFlash], execute: {
                                                self.nextStep(with: checkFlashRequest1)
        })!
        let eraseFlashRequest2 = SerialRequest(command: "10300000\n", response: "Value in hex>", searchingRangeLength: 20, timeout: 10,
                                               userInfo: [CSXUploader.UploadStage.eraseFlash], execute: {
                                                self.nextStep(with: eraseFlashRequest3)
        })!
        let eraseFlashRequest1 = SerialRequest(command: "1", response: "Address in hex>", searchingRangeLength: 20, timeout: 10,
                                               userInfo: [CSXUploader.UploadStage.eraseFlash], execute: {
                                                self.nextStep(with: eraseFlashRequest2)
        })!
        let setBaudrate19200Request3 = SerialRequest(command: "\n", response: "hello", searchingRangeLength: 10, timeout: 10,
                                                     userInfo: [CSXUploader.UploadStage.setBaudrate19200], execute: {
                                                        self.nextStep(with: eraseFlashRequest1)
        })!
        let setBaudrate19200Request2 = SerialRequest(command: "1f800702\n", response: "Value in hex>", searchingRangeLength: 20, timeout: 10,
                                                     userInfo: [CSXUploader.UploadStage.setBaudrate19200], execute: {
                                                        self.buffer?.sendString("00001000\n")   // baudrate=9600
                                                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
                                                            self.buffer?.serialPort.baudRate = 19200
                                                            self.nextStep(with: setBaudrate19200Request3)
                                                        })
        })!
        let setBaudrate19200Request1 = SerialRequest(command: "1", response: "Address in hex>", searchingRangeLength: 20, timeout: 10,
                                                     userInfo: [CSXUploader.UploadStage.setBaudrate19200], execute: {
                                                        self.nextStep(with: setBaudrate19200Request2)
        })!
        let checkRootRequest = SerialRequest(command: "\n", response: "hello", searchingRangeLength: 10, timeout: 10,
                                             userInfo: [CSXUploader.UploadStage.checkRootSpace], execute: {
                                                self.nextStep(with: setBaudrate19200Request1)
        })!
        self.nextStep(with: checkRootRequest)
    }
    
    func nextStep(with request: SerialRequest) {
        guard let unwrappedBuffer = self.buffer else {
            self.delegate?.csxUploader(self, failure: "Lost internal buffer")
            return
        }
        unwrappedBuffer.addRequest(request: request)
    }
    
    func stopUpload() {
        self.buffer?.serialPort.baudRate = 9600
        self.buffer?.closePort()
        self.buffer?.reset()
        self.heartBeatTimer?.invalidate()
        self.heartBeatTimer = nil
    }
}

protocol CSXUploaderDelegate {
    func csxUploader(_ uploader: CSXUploader, didFinish stage: CSXUploader.UploadStage)
    func csxUploader(_ uplodaer: CSXUploader, failure reason: String)
    func didUploadSuccessfully(_ uploader: CSXUploader)
    func didCloseSerialPort(_ uploader: CSXUploader, portName: String)
}
