//
//  BLEManager.swift
//  Pichamabob
//
//  Handles BLE connection to the T-Deck Plus relay
//

import Foundation
import CoreBluetooth
import Combine
#if canImport(UIKit)
import UIKit
#endif

// Protocol UUIDs - must match T-Deck Plus firmware
struct PitchComUUIDs {
    static let service = CBUUID(string: "19B10000-E8F2-537E-4F6C-D104768A1214")
    static let signalCharacteristic = CBUUID(string: "19B10001-E8F2-537E-4F6C-D104768A1214")
}

enum ConnectionState: String {
    case disconnected = "Disconnected"
    case scanning = "Scanning..."
    case connecting = "Connecting..."
    case connected = "Connected"
    case ready = "Ready"
}

@MainActor
class BLEManager: NSObject, ObservableObject {
    
    @Published var connectionState: ConnectionState = .disconnected
    @Published var lastError: String?
    @Published var signalSentCount: Int = 0
    
    private var centralManager: CBCentralManager!
    private var peripheral: CBPeripheral?
    private var signalCharacteristic: CBCharacteristic?
    
    private let targetDeviceName = "PitchCom-Relay"
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            lastError = "Bluetooth is not available"
            return
        }
        
        lastError = nil
        connectionState = .scanning
        
        // Scan for devices advertising our service
        centralManager.scanForPeripherals(
            withServices: [PitchComUUIDs.service],
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        
        // Timeout after 10 seconds
        Task {
            try? await Task.sleep(nanoseconds: 10_000_000_000)
            if connectionState == .scanning {
                stopScanning()
                lastError = "Relay not found. Make sure T-Deck is powered on."
                connectionState = .disconnected
            }
        }
    }
    
    func stopScanning() {
        centralManager.stopScan()
    }
    
    func disconnect() {
        if let peripheral = peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        peripheral = nil
        signalCharacteristic = nil
        connectionState = .disconnected
    }
    
    func sendSignal(code: String = "Goodbye world") -> Int {
        guard connectionState == .ready,
              let characteristic = signalCharacteristic,
              let peripheral = peripheral else {
            lastError = "Not connected to relay"
            return 1
        }
        
        //let data = Data([code])
        guard let data = code.data(using: .ascii) else { return 0 }
        print("Data: \(String(data: data, encoding: .ascii))")
        peripheral.writeValue(data, for: characteristic, type: .withoutResponse)
        
        signalSentCount += 1
        
        // Brief haptic feedback on send
        #if canImport(UIKit)
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        #endif
        return 0
    }
}

// MARK: - CBCentralManagerDelegate

extension BLEManager: CBCentralManagerDelegate {
    
    nonisolated func centralManagerDidUpdateState(_ central: CBCentralManager) {
        Task { @MainActor in
            switch central.state {
            case .poweredOn:
                // Ready to scan
                break
            case .poweredOff:
                lastError = "Bluetooth is turned off"
                connectionState = .disconnected
            case .unauthorized:
                lastError = "Bluetooth permission denied"
                connectionState = .disconnected
            case .unsupported:
                lastError = "Bluetooth not supported"
                connectionState = .disconnected
            default:
                break
            }
        }
    }
    
    nonisolated func centralManager(_ central: CBCentralManager,
                                    didDiscover peripheral: CBPeripheral,
                                    advertisementData: [String: Any],
                                    rssi RSSI: NSNumber) {
        Task { @MainActor in
            // Check if this is our relay
            let name = peripheral.name ?? advertisementData[CBAdvertisementDataLocalNameKey] as? String
            
            if name == targetDeviceName {
                stopScanning()
                self.peripheral = peripheral
                connectionState = .connecting
                central.connect(peripheral, options: nil)
            }
        }
    }
    
    nonisolated func centralManager(_ central: CBCentralManager,
                                    didConnect peripheral: CBPeripheral) {
        Task { @MainActor in
            connectionState = .connected
            peripheral.delegate = self
            peripheral.discoverServices([PitchComUUIDs.service])
        }
    }
    
    nonisolated func centralManager(_ central: CBCentralManager,
                                    didFailToConnect peripheral: CBPeripheral,
                                    error: Error?) {
        Task { @MainActor in
            lastError = "Failed to connect: \(error?.localizedDescription ?? "Unknown error")"
            connectionState = .disconnected
            self.peripheral = nil
        }
    }
    
    nonisolated func centralManager(_ central: CBCentralManager,
                                    didDisconnectPeripheral peripheral: CBPeripheral,
                                    error: Error?) {
        Task { @MainActor in
            if let error = error {
                lastError = "Disconnected: \(error.localizedDescription)"
            }
            connectionState = .disconnected
            self.peripheral = nil
            signalCharacteristic = nil
        }
    }
}

// MARK: - CBPeripheralDelegate

extension BLEManager: CBPeripheralDelegate {
    
    nonisolated func peripheral(_ peripheral: CBPeripheral,
                                didDiscoverServices error: Error?) {
        Task { @MainActor in
            if let error = error {
                lastError = "Service discovery failed: \(error.localizedDescription)"
                return
            }
            
            guard let service = peripheral.services?.first(where: { $0.uuid == PitchComUUIDs.service }) else {
                lastError = "PitchCom service not found"
                return
            }
            
            peripheral.discoverCharacteristics([PitchComUUIDs.signalCharacteristic], for: service)
        }
    }
    
    nonisolated func peripheral(_ peripheral: CBPeripheral,
                                didDiscoverCharacteristicsFor service: CBService,
                                error: Error?) {
        Task { @MainActor in
            if let error = error {
                lastError = "Characteristic discovery failed: \(error.localizedDescription)"
                return
            }
            
            guard let characteristic = service.characteristics?.first(where: {
                $0.uuid == PitchComUUIDs.signalCharacteristic
            }) else {
                lastError = "Signal characteristic not found"
                return
            }
            
            signalCharacteristic = characteristic
            connectionState = .ready
            lastError = nil
        }
    }
}
