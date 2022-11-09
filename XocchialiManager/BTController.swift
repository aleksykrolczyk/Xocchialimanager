//
//  BTVievModel.swift
//  XocchialiManager
//
//  Created by Aleksy Krolczyk on 05/11/2022.
//

import CoreBluetooth
import Foundation
import SwiftUI

struct Constants {
    static let RSSIThreshold = -60
    static let ESPName = "Phone Killer v0.1"
    static let ESPServiceUUID = CBUUID(string: "0x1111")

    static let ServiceUUID = CBUUID(string: "0x00FF")
    static let ButtonCharacteristicUUID = CBUUID(string: "0xFF01")
    static let LedCharacteristicUUID = CBUUID(string: "0xFF02")
}

struct Touchpads {
    var play: UInt16 = 1337
    var set: UInt16 = 1337
    var volumeDown: UInt16 = 1337
    var volumeUp: UInt16 = 1337
}

class BTController: NSObject, ObservableObject {
    private var centralManager: CBCentralManager!
    private var unnamedCounter = 0

    @Published var peripheral: CBPeripheral?
    @Published var touchpads: Touchpads?

    var ledCharacteristic: CBCharacteristic?

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
    }

    private func toggleLED(value: Bool) {
        guard let peripheral = peripheral, let ledCharacteristic = ledCharacteristic else { return }
        let data = Data(repeating: value ? 1 : 0, count: 1)
        peripheral.writeValue(data, for: ledCharacteristic, type: .withResponse)
    }

    func toggleLEDOn() { toggleLED(value: true) }
    func toggleLEDOff() { toggleLED(value: false) }
}

extension BTController: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            central.scanForPeripherals(withServices: [Constants.ServiceUUID])
        default:
            debugPrint("Central state: \(central.state)")
        }
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String: Any], rssi RSSI: NSNumber) {
        if peripheral.name == Constants.ESPName {
            self.peripheral = peripheral
            central.connect(peripheral)
            central.stopScan()
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        debugPrint("Successfully connected to \(peripheral.name ?? "unnamed device")")
        peripheral.delegate = self
        peripheral.discoverServices(nil)
    }
}

extension BTController: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        debugPrint("Service(s) discovered!")

        guard let services = peripheral.services else { return }
        for service in services {
            debugPrint("Discovering characteristics for service \(service.uuid)")
            peripheral.discoverCharacteristics(nil, for: service)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }

        debugPrint("Characteristics for service \(service)")
        for characteristic in characteristics {
            debugPrint("  \(characteristic)")
            peripheral.readValue(for: characteristic)

            if characteristic.uuid == Constants.LedCharacteristicUUID {
                debugPrint("Found LED Characteristic...")
                ledCharacteristic = characteristic
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
            case Constants.ButtonCharacteristicUUID:
                guard let value = characteristic.value else { return }
                var t = Touchpads()
                
                value[0 ... 1].withUnsafeBytes { t.play = $0.load(as: UInt16.self) }
                value[2 ... 3].withUnsafeBytes { t.set = $0.load(as: UInt16.self) }
                value[4 ... 5].withUnsafeBytes { t.volumeDown = $0.load(as: UInt16.self) }
                value[6 ... 7].withUnsafeBytes { t.volumeUp = $0.load(as: UInt16.self) }
                
                touchpads = t
                peripheral.readValue(for: characteristic)
                
            default:
                break
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        debugPrint("Peripheral disconnected: \(peripheral)")
        self.peripheral = nil
        self.ledCharacteristic = nil
        self.touchpads = nil

        central.scanForPeripherals(withServices: [Constants.ServiceUUID])
    }
}
