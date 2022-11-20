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
    enum State {
        case idle, shortPress, longPress

        init?(_ pressType: UInt8) {
            switch pressType {
            case 0:
                self = .shortPress
            case 1:
                self = .longPress
            default:
                return nil
            }
        }
    }

    private(set) var play: State = .idle
    private(set) var set: State = .idle
    private(set) var volumeDown: State = .idle
    private(set) var volumeUp: State = .idle

    subscript(index: UInt8) -> State? {
        get {
            switch index {
            case 8:
                return play
            case 9:
                return set
            case 4:
                return volumeDown
            case 7:
                return volumeUp
            default:
                return nil
            }
        }
        set {
            switch index {
            case 8:
                play = newValue!
            case 9:
                set = newValue!
            case 4:
                volumeDown = newValue!
            case 7:
                volumeUp = newValue!
            default:
                debugPrint("Unrecognized index=\(index), ignoring...")
            }
        }
    }

    mutating func changeState(for buttonID: UInt8, state: State?) {
        guard let state = state else { return }
        debugPrint("Changing state of \(buttonID) to \(state)")
        self[buttonID] = state
    }
}

class BTController: NSObject, ObservableObject {
    private var centralManager: CBCentralManager!
    private var unnamedCounter = 0

    @Published var peripheral: CBPeripheral?
    @Published var touchpads: Touchpads = Touchpads()

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
            central.scanForPeripherals(withServices: nil)
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

//            getPropertiesFor(for: characteristic)

            if characteristic.uuid == Constants.LedCharacteristicUUID {
                debugPrint("Found LED Characteristic...")
                ledCharacteristic = characteristic
            }
            if characteristic.uuid == Constants.ButtonCharacteristicUUID {
                debugPrint("Found Button Characteristic...")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        switch characteristic.uuid {
        case Constants.ButtonCharacteristicUUID:
            guard let value = characteristic.value else { return }

            let button = value[0]
            let pressType = value[1]
            debugPrint("Button=\(button), press type=\(pressType)")
            touchpads.changeState(for: button, state: Touchpads.State(pressType))

            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(1)) {
                self.touchpads.changeState(for: button, state: Touchpads.State.idle)
            }

        default:
            break
        }
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        debugPrint("Peripheral disconnected: \(peripheral)")
        self.peripheral = nil
        self.ledCharacteristic = nil
        central.scanForPeripherals(withServices: [Constants.ServiceUUID])
    }
}

extension BTController { // UTILS
    func getPropertiesFor(for char: CBCharacteristic) {
        if char.properties.contains(.read) {
            print("\(char.uuid): properties contains .read")
        }
        if char.properties.contains(.notify) {
            print("\(char.uuid): properties contains .notify")
        }
        if char.properties.contains(.write) {
            print("\(char.uuid): properties contains .write")
        }
    }
}
