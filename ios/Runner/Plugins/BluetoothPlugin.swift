import Foundation
import CoreBluetooth
import Flutter

/**
 * BluetoothPlugin - اتصال BLE مع جهاز ELD
 *
 * Discovery is intentionally unfiltered: the previous version scanned only for
 * the FFE0 service, so Pacific Track PT30/PT40 modules and NUS-based adapters
 * never appeared. The plugin now:
 *  - scans for every peripheral,
 *  - classifies FFE0 / NUS / Pacific Track / generic ELD,
 *  - subscribes to every notify+indicate characteristic (CCCD),
 *  - emits raw frames as hex + ASCII so the PT30 protocol can be captured,
 *  - reconnects with 2s -> 30s backoff unless the driver stopped the session.
 */
class BluetoothPlugin: NSObject, FlutterPlugin, CBCentralManagerDelegate,
    CBPeripheralDelegate
{

    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var eventSink: FlutterEventSink?

    private var isScanning = false
    private var servicesDiscovered = false
    private var batteryLevel: Int?

    private var writeCharacteristic: CBCharacteristic?
    private var notifyCharacteristics: Set<String> = []

    private var lastPeripheralIdentifier: UUID?
    private var lastPeripheralName: String?
    private var lastScanEmit: [UUID: Date] = [:]

    private var isSessionActive = true
    private var isManualMode = false
    private var reconnectAttempts = 0
    private var reconnectTimer: DispatchWorkItem?

    private static let eldServiceUUID = CBUUID(string: "0000ffe0-0000-1000-8000-00805f9b34fb")
    private static let eldCharacteristicUUID = CBUUID(
        string: "0000ffe1-0000-1000-8000-00805f9b34fb"
    )
    private static let nusServiceUUID = CBUUID(string: "6e400001-b5a3-f393-e0a9-e50e24dcca9e")
    private static let nusRxUUID = CBUUID(string: "6e400003-b5a3-f393-e0a9-e50e24dcca9e")
    private static let nusTxUUID = CBUUID(string: "6e400002-b5a3-f393-e0a9-e50e24dcca9e")
    private static let batteryServiceUUID = CBUUID(
        string: "0000180f-0000-1000-8000-00805f9b34fb"
    )
    private static let batteryLevelUUID = CBUUID(
        string: "00002a19-0000-1000-8000-00805f9b34fb"
    )

    private static let lastDeviceKey = "last_peripheral_id"
    private static let lastDeviceNameKey = "last_peripheral_name"

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

    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: .main)
        if let stored = UserDefaults.standard.string(forKey: Self.lastDeviceKey) {
            lastPeripheralIdentifier = UUID(uuidString: stored)
        }
        lastPeripheralName = UserDefaults.standard.string(forKey: Self.lastDeviceNameKey)
    }

    // MARK: - MethodChannel

    func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startScan":
            startScan(result: result)
        case "stopScan":
            stopScan(result: result)
        case "connect", "executeConnect":
            guard let arguments = call.arguments as? [String: Any],
                let identifier = arguments["macAddress"] as? String
            else {
                result(
                    FlutterError(code: "NO_MAC", message: "MAC/identifier required", details: nil)
                )
                return
            }
            result(connect(identifier: identifier))
        case "disconnect":
            disconnect()
            result(true)
        case "isConnected":
            result(connectedPeripheral?.state == .connected)
        case "readDeviceInfo":
            result(deviceInfo())
        case "sendCommand":
            sendCommand(call: call, result: result)
        case "getLastDevice":
            result([
                "macAddress": lastPeripheralIdentifier?.uuidString ?? "",
                "name": lastPeripheralName ?? "",
            ])
        case "setSessionState":
            setSessionState(call: call, result: result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    // MARK: - Session / reconnect state

    private func setSessionState(call: FlutterMethodCall, result: @escaping FlutterResult) {
        let arguments = call.arguments as? [String: Any] ?? [:]
        isSessionActive = arguments["isActive"] as? Bool ?? false
        isManualMode = arguments["isManualMode"] as? Bool ?? false

        if arguments["clearMac"] as? Bool == true {
            lastPeripheralIdentifier = nil
            lastPeripheralName = nil
            UserDefaults.standard.removeObject(forKey: Self.lastDeviceKey)
            UserDefaults.standard.removeObject(forKey: Self.lastDeviceNameKey)
            reconnectAttempts = 0
            cancelReconnect()
        }
        if !isSessionActive || isManualMode {
            cancelReconnect()
            if isManualMode {
                reconnectAttempts = 0
            }
        }
        result(true)
    }

    private func scheduleReconnect() {
        guard isSessionActive, !isManualMode,
            let peripheral = connectedPeripheral ?? knownPeripheral()
        else {
            return
        }
        cancelReconnect()
        reconnectAttempts += 1

        let delay = min(2.0 * pow(2.0, Double(reconnectAttempts - 1)), 30.0)
        TrackingLogStore.shared.warn(
            "BLE reconnect attempt #\(reconnectAttempts) in \(Int(delay))s",
            tag: "BLE"
        )
        emit([
            "type": "ble_reconnect_retry_event",
            "attemptNumber": reconnectAttempts,
        ])

        let work = DispatchWorkItem { [weak self] in
            guard let self = self, self.isSessionActive, !self.isManualMode else { return }
            self.centralManager.connect(peripheral, options: nil)
        }
        reconnectTimer = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func cancelReconnect() {
        reconnectTimer?.cancel()
        reconnectTimer = nil
    }

    private func knownPeripheral() -> CBPeripheral? {
        guard let identifier = lastPeripheralIdentifier else { return nil }
        return centralManager.retrievePeripherals(withIdentifiers: [identifier]).first
    }

    // MARK: - Scan

    private func startScan(result: @escaping FlutterResult) {
        guard centralManager.state == .poweredOn else {
            result(
                FlutterError(
                    code: "BT_UNAVAILABLE",
                    message: "Bluetooth is not powered on",
                    details: nil
                )
            )
            return
        }
        lastScanEmit.removeAll()
        isScanning = true
        // No service filter: PT30/PT40 and NUS adapters do not advertise FFE0.
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: true]
        )
        TrackingLogStore.shared.info("BLE scan started (unfiltered)", tag: "BLE")
        emit(["type": "scanStarted"])
        result(true)
    }

    private func stopScan(result: @escaping FlutterResult) {
        centralManager.stopScan()
        isScanning = false
        emit(["type": "scanStopped"])
        result(true)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            TrackingLogStore.shared.info("Bluetooth powered on", tag: "BLE")
            if let peripheral = knownPeripheral(),
                isSessionActive && !isManualMode
            {
                central.connect(peripheral, options: nil)
            }
        case .poweredOff:
            emit(["type": "scanFailed", "error": "poweredOff"])
        case .unauthorized:
            emit(["type": "scanFailed", "error": "unauthorized"])
        default:
            break
        }
    }

    func centralManager(
        _ central: CBCentralManager,
        didDiscover peripheral: CBPeripheral,
        advertisementData: [String: Any],
        rssi RSSI: NSNumber
    ) {
        let now = Date()
        if let last = lastScanEmit[peripheral.identifier],
            now.timeIntervalSince(last) < 0.7
        {
            return
        }
        lastScanEmit[peripheral.identifier] = now

        let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String
        let name = localName ?? peripheral.name ?? "Unknown"
        let serviceUUIDs = (advertisementData[CBAdvertisementDataServiceUUIDsKey] as? [CBUUID])
            ?.map { $0.uuidString.lowercased() } ?? []

        var manufacturerData: [String: String] = [:]
        if let data = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            let bytes = [UInt8](data)
            if bytes.count >= 2 {
                let company = UInt16(bytes[0]) | (UInt16(bytes[1]) << 8)
                let payload = bytes.dropFirst(2).map { String(format: "%02X", $0) }.joined()
                manufacturerData[String(format: "0x%04X", company)] = payload
            }
        }

        emit([
            "type": "deviceFound",
            "data": [
                "name": name,
                "macAddress": peripheral.identifier.uuidString,
                "rssi": RSSI.intValue,
                "serviceUuids": serviceUUIDs,
                "isConnectable": true,
                "kind": classify(name: name, serviceUUIDs: serviceUUIDs),
                "bonded": false,
                "manufacturerData": manufacturerData,
            ],
        ])
    }

    private func classify(name: String, serviceUUIDs: [String]) -> String {
        let upperName = name.uppercased()
        let services = Set(serviceUUIDs.map { $0.lowercased() })
        if upperName.hasPrefix("PT30") || upperName.hasPrefix("PT40")
            || upperName.contains("PACIFIC")
        {
            return "pacificTrack"
        }
        if services.contains(Self.nusServiceUUID.uuidString.lowercased()) {
            return "nus"
        }
        if services.contains(Self.eldServiceUUID.uuidString.lowercased()) {
            return "ffe0"
        }
        if upperName.contains("ELD") || upperName.contains("OBD") {
            return "eld"
        }
        return "unknown"
    }

    // MARK: - Connect

    @discardableResult
    private func connect(identifier: String) -> Bool {
        let uuid: UUID?
        if let parsed = UUID(uuidString: identifier) {
            uuid = parsed
        } else if let stored = lastPeripheralIdentifier {
            // The Dart layer may still send a MAC-style value; fall back to the
            // remembered peripheral on iOS where MACs are not exposed.
            uuid = stored
        } else {
            uuid = nil
        }

        guard let target = uuid else {
            emit(["type": "connectFailed", "reason": "unknown identifier"])
            return false
        }

        lastPeripheralIdentifier = target
        UserDefaults.standard.set(target.uuidString, forKey: Self.lastDeviceKey)
        cancelReconnect()

        if let peripheral = connectedPeripheral, peripheral.identifier == target,
            peripheral.state == .connected
        {
            return true
        }

        let peripheral =
            centralManager.retrievePeripherals(withIdentifiers: [target]).first
            ?? knownPeripheral()
        guard let targetPeripheral = peripheral else {
            emit(["type": "connectFailed", "reason": "peripheral not found"])
            return false
        }

        connectedPeripheral?.delegate = nil
        connectedPeripheral = targetPeripheral
        targetPeripheral.delegate = self
        servicesDiscovered = false
        writeCharacteristic = nil
        notifyCharacteristics.removeAll()
        batteryLevel = nil

        centralManager.connect(targetPeripheral, options: nil)
        TrackingLogStore.shared.info(
            "BLE connect initiated to \(target.uuidString) (\(targetPeripheral.name ?? "unknown"))",
            tag: "BLE"
        )
        return true
    }

    private func disconnect() {
        isSessionActive = false
        cancelReconnect()
        reconnectAttempts = 0
        if let peripheral = connectedPeripheral {
            centralManager.cancelPeripheralConnection(peripheral)
        }
        connectedPeripheral = nil
        servicesDiscovered = false
        writeCharacteristic = nil
        notifyCharacteristics.removeAll()
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectedPeripheral = peripheral
        lastPeripheralIdentifier = peripheral.identifier
        lastPeripheralName = peripheral.name
        UserDefaults.standard.set(
            peripheral.identifier.uuidString, forKey: Self.lastDeviceKey
        )
        if let name = peripheral.name {
            UserDefaults.standard.set(name, forKey: Self.lastDeviceNameKey)
        }
        reconnectAttempts = 0
        emit([
            "type": "connected",
            "macAddress": peripheral.identifier.uuidString,
            "name": peripheral.name ?? "",
        ])
        TrackingLogStore.shared.info(
            "BLE connected to \(peripheral.name ?? peripheral.identifier.uuidString)",
            tag: "BLE"
        )
        peripheral.discoverServices(nil)
    }

    func centralManager(
        _ central: CBCentralManager,
        didFailToConnect peripheral: CBPeripheral,
        error: Error?
    ) {
        emit([
            "type": "disconnected",
            "macAddress": peripheral.identifier.uuidString,
            "status": error?.localizedDescription ?? "connectFailed",
        ])
        TrackingLogStore.shared.warn(
            "BLE connect failed: \(error?.localizedDescription ?? "unknown")", tag: "BLE"
        )
        connectedPeripheral = nil
        scheduleReconnect()
    }

    func centralManager(
        _ central: CBCentralManager,
        didDisconnectPeripheral peripheral: CBPeripheral,
        error: Error?
    ) {
        emit([
            "type": "disconnected",
            "macAddress": peripheral.identifier.uuidString,
            "status": error?.localizedDescription ?? "disconnected",
        ])
        TrackingLogStore.shared.warn(
            "BLE disconnected: \(error?.localizedDescription ?? "no error")", tag: "BLE"
        )
        connectedPeripheral = nil
        servicesDiscovered = false
        writeCharacteristic = nil
        notifyCharacteristics.removeAll()
        scheduleReconnect()
    }

    // MARK: - GATT

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            TrackingLogStore.shared.error(
                "Service discovery failed: \(error.localizedDescription)", tag: "BLE"
            )
            emit(["type": "discoveryFailed", "status": error.localizedDescription])
            return
        }
        var servicesInfo: [[String: Any]] = []
        for service in peripheral.services ?? [] {
            servicesInfo.append([
                "uuid": service.uuid.uuidString.lowercased(),
                "characteristics": [],
            ])
            peripheral.discoverCharacteristics(nil, for: service)
        }
        servicesDiscovered = true
        emit([
            "type": "services",
            "mtu": peripheral.maximumWriteValueLength(for: .withoutResponse),
            "services": servicesInfo,
        ])
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didDiscoverCharacteristicsFor service: CBService,
        error: Error?
    ) {
        guard error == nil else { return }

        for characteristic in service.characteristics ?? [] {
            if characteristic.properties.contains(.notify)
                || characteristic.properties.contains(.indicate)
            {
                notifyCharacteristics.insert(characteristic.uuid.uuidString.lowercased())
                peripheral.setNotifyValue(true, for: characteristic)
            }
            if characteristic.properties.contains(.write)
                || characteristic.properties.contains(.writeWithoutResponse)
            {
                if writeCharacteristic == nil
                    || characteristic.uuid == Self.eldCharacteristicUUID
                    || characteristic.uuid == Self.nusTxUUID
                {
                    writeCharacteristic = characteristic
                }
            }
            if characteristic.uuid == Self.batteryLevelUUID {
                peripheral.readValue(for: characteristic)
            }
        }

        emit([
            "type": "services",
            "mtu": peripheral.maximumWriteValueLength(for: .withoutResponse),
            "services": [
                [
                    "uuid": service.uuid.uuidString.lowercased(),
                    "characteristics": (service.characteristics ?? []).map { characteristic in
                        [
                            "uuid": characteristic.uuid.uuidString.lowercased(),
                            "properties": describeProperties(characteristic.properties),
                        ]
                    },
                ]
            ],
        ])
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didUpdateValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        guard error == nil, let value = characteristic.value, !value.isEmpty else { return }

        if characteristic.uuid == Self.batteryLevelUUID {
            batteryLevel = Int(value[0])
            emit(["type": "battery", "level": batteryLevel ?? 0])
            return
        }

        let bytes = [UInt8](value)
        emit([
            "type": "data",
            "data": bytes.map { String($0) }.joined(separator: ","),
            "values": bytes.map { Int($0) },
            "hex": bytes.map { String(format: "%02X", $0) }.joined(),
            "ascii": String(bytes: bytes, encoding: .ascii) ?? "",
            "characteristic": characteristic.uuid.uuidString.lowercased(),
            "service": characteristic.service?.uuid.uuidString.lowercased() ?? "",
            "timestamp": Int(Date().timeIntervalSince1970 * 1000),
        ])
    }

    func peripheral(
        _ peripheral: CBPeripheral,
        didWriteValueFor characteristic: CBCharacteristic,
        error: Error?
    ) {
        if let error = error {
            TrackingLogStore.shared.error(
                "BLE write failed: \(error.localizedDescription)", tag: "BLE"
            )
        }
    }

    private func describeProperties(_ properties: CBCharacteristicProperties) -> [String] {
        var result: [String] = []
        if properties.contains(.read) { result.append("read") }
        if properties.contains(.write) { result.append("write") }
        if properties.contains(.writeWithoutResponse) { result.append("writeNoResponse") }
        if properties.contains(.notify) { result.append("notify") }
        if properties.contains(.indicate) { result.append("indicate") }
        return result
    }

    // MARK: - Commands & diagnostics

    private func sendCommand(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let peripheral = connectedPeripheral, peripheral.state == .connected else {
            result(
                FlutterError(code: "NOT_CONNECTED", message: "No BLE device connected", details: nil)
            )
            return
        }
        guard let characteristic = writeCharacteristic else {
            result(
                FlutterError(
                    code: "NO_WRITE_CHARACTERISTIC",
                    message: "Device has no writable characteristic",
                    details: nil
                )
            )
            return
        }

        let arguments = call.arguments as? [String: Any] ?? [:]
        let payload: Data
        if let hex = arguments["hex"] as? String, !hex.isEmpty {
            guard let data = Self.data(fromHex: hex) else {
                result(
                    FlutterError(
                        code: "INVALID_COMMAND", message: "Invalid hex payload", details: nil
                    )
                )
                return
            }
            payload = data
        } else if let text = arguments["text"] as? String {
            payload = Data(text.utf8)
        } else {
            result(
                FlutterError(
                    code: "INVALID_COMMAND", message: "hex or text argument required", details: nil
                )
            )
            return
        }

        let writeType: CBCharacteristicWriteType =
            characteristic.properties.contains(.write)
            ? .withResponse
            : .withoutResponse
        peripheral.writeValue(payload, for: characteristic, type: writeType)
        result(true)
    }

    private func deviceInfo() -> [String: Any] {
        let peripheral = connectedPeripheral
        var services: [[String: Any]] = []
        if let peripheral = peripheral, let discovered = peripheral.services {
            services = discovered.map { service in
                [
                    "uuid": service.uuid.uuidString.lowercased(),
                    "characteristics": (service.characteristics ?? []).map { characteristic in
                        [
                            "uuid": characteristic.uuid.uuidString.lowercased(),
                            "properties": describeProperties(characteristic.properties),
                        ]
                    },
                ]
            }
        }

        return [
            "connected": peripheral?.state == .connected,
            "macAddress": peripheral?.identifier.uuidString
                ?? lastPeripheralIdentifier?.uuidString ?? "",
            "name": peripheral?.name ?? lastPeripheralName ?? "",
            "mtu": peripheral?.maximumWriteValueLength(for: .withoutResponse) ?? 23,
            "batteryLevel": batteryLevel ?? 0,
            "notifyCharacteristics": Array(notifyCharacteristics),
            "writeCharacteristic": writeCharacteristic?.uuid.uuidString.lowercased() ?? "",
            "services": services,
            "scanning": isScanning,
            "scanElapsedMs": 0,
        ]
    }

    private static func data(fromHex hex: String) -> Data? {
        let clean = hex.replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: ":", with: "")
            .replacingOccurrences(of: "-", with: "")
        guard clean.count % 2 == 0 else { return nil }
        var data = Data()
        var index = clean.startIndex
        while index < clean.endIndex {
            let next = clean.index(index, offsetBy: 2)
            guard let byte = UInt8(clean[index..<next], radix: 16) else { return nil }
            data.append(byte)
            index = next
        }
        return data
    }

    private func emit(_ event: [String: Any]) {
        if Thread.isMainThread {
            eventSink?(event)
        } else {
            DispatchQueue.main.async { [weak self] in
                self?.eventSink?(event)
            }
        }
    }
}

extension BluetoothPlugin: FlutterStreamHandler {
    func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink)
        -> FlutterError?
    {
        self.eventSink = events
        return nil
    }

    func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
