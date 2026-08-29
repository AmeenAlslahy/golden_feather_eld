import Foundation
import CoreBluetooth
import Flutter

/**
 * BluetoothPlugin - اتصال BLE مع جهاز ELD
 */
class BluetoothPlugin: NSObject, FlutterPlugin {
    
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var eventSink: FlutterEventSink?
    
    private let ELD_SERVICE_UUID = CBUUID(string: "0000ffe0-0000-1000-8000-00805f9b34fb")
    private let ELD_CHARACTERISTIC_UUID = CBUUID(string: "0000ffe1-0000-1000-8000-00805f9b34fb")
    
    static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "com.goldenfeather.eld/bluetooth",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "com.goldenfeather.eld/bluetooth/events",
            binaryMessenger: registrar.messenger()
        )
        
        let instance = BluetoothPlugin()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }
    
    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startScan":
            startScan(result: result)
        case "stopScan":
            stopScan(result: result)
        case "connect":
            connectDevice(call: call, result: result)
        case "disconnect":
            disconnectDevice(result: result)
        case "isConnected":
            result(connectedPeripheral != nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func startScan(result: @escaping FlutterResult) {
        centralManager = CBCentralManager(delegate: self, queue: nil)
        result(true)
    }
    
    private func stopScan(result: @escaping FlutterResult) {
        centralManager?.stopScan()
        result(true)
    }
    
    private func connectDevice(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let macAddress = (call.arguments as? [String: Any])?["macAddress"] as? String else {
            result(FlutterError(code: "NO_MAC", message: "MAC address required", details: nil))
            return
        }
        
        // Note: iOS uses UUID not MAC address
        let uuid = UUID(uuidString: macAddress) ?? UUID()
        let peripherals = centralManager.retrievePeripherals(withIdentifiers: [uuid])
        
        if let peripheral = peripherals.first {
            connectedPeripheral = peripheral
            centralManager.connect(peripheral, options: nil)
        }
        
        result(true)
    }
    
    private func disconnectDevice(result: @escaping FlutterResult) {
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
            connectedPeripheral = nil
        }
        result(true)
    }
}

extension BluetoothPlugin: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}

extension BluetoothPlugin: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            central.scanForPeripherals(withServices: [ELD_SERVICE_UUID], options: nil)
        case .poweredOff:
            eventSink?(FlutterError(code: "BT_OFF", message: "Bluetooth is off", details: nil))
        default:
            break
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        let data: [String: Any] = [
            "type": "deviceFound",
            "data": [
                "name": peripheral.name ?? "Unknown",
                "macAddress": peripheral.identifier.uuidString,
                "rssi": RSSI.intValue
            ]
        ]
        eventSink?(data)
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        eventSink?(["type": "connected"])
        peripheral.delegate = self
        peripheral.discoverServices([ELD_SERVICE_UUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        eventSink?(["type": "disconnected"])
        connectedPeripheral = nil
    }
}

extension BluetoothPlugin: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else { return }
        
        for service in services {
            if service.uuid == ELD_SERVICE_UUID {
                peripheral.discoverCharacteristics([ELD_CHARACTERISTIC_UUID], for: service)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == ELD_CHARACTERISTIC_UUID {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let value = characteristic.value {
            let data: [String: Any] = [
                "type": "data",
                "data": value.map { String($0) }.joined(separator: ",")
            ]
            eventSink?(data)
        }
    }
}
