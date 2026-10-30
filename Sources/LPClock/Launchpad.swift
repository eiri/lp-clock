import CoreMIDI
import Foundation

struct MIDIError: LocalizedError {
    let operation: String
    let status: OSStatus

    var errorDescription: String? { "\(operation) failed (MIDI \(status))." }
}

final class Launchpad {
    private var client: MIDIClientRef = 0
    private var port: MIDIPortRef = 0
    private var endpoint: MIDIEndpointRef = 0
    private var lastFrame: [UInt8] = []

    init() throws {
        try check(MIDIClientCreateWithBlock("LP Clock" as CFString, &client, nil), "Create MIDI client")
        do {
            try check(MIDIOutputPortCreate(client, "Clock lights" as CFString, &port), "Create MIDI port")
        } catch {
            MIDIClientDispose(client)
            throw error
        }
    }

    deinit {
        MIDIPortDispose(port)
        MIDIClientDispose(client)
    }

    func show(_ frame: ClockFrame) throws -> Bool {
        let destination = findDevice()
        guard destination != 0 else {
            endpoint = 0
            lastFrame = []
            return false
        }

        do {
            // Re-enter Programmer mode after a USB reconnect.
            if destination != endpoint {
                endpoint = destination
                lastFrame = []
                try send([0x0E, 1])
                try send(ClockFrame.clearMessage)
            }

            if frame.colors != lastFrame {
                try send(frame.message)
                lastFrame = frame.colors
            }
            return true
        } catch {
            endpoint = 0
            lastFrame = []
            throw error
        }
    }

    func stop() throws {
        guard endpoint != 0 else { return }
        defer {
            endpoint = 0
            lastFrame = []
        }

        // Attempt the mode switch even if clearing the grid fails.
        var failure: Error?
        do { try send(ClockFrame.clearMessage) } catch { failure = error }
        do { try send([0x0E, 0]) } catch { failure = error }
        if let failure { throw failure }
    }

    private func findDevice() -> MIDIEndpointRef {
        for index in 0..<MIDIGetNumberOfDestinations() {
            let candidate = MIDIGetDestination(index)
            var name: Unmanaged<CFString>?
            guard MIDIObjectGetStringProperty(candidate, kMIDIPropertyDisplayName, &name) == noErr,
                  let name else { continue }
            let text = name.takeRetainedValue() as String
            if text.contains("LPMiniMK3 MIDI In") { return candidate }
        }
        return 0
    }

    private func send(_ payload: [UInt8]) throws {
        let bytes: [UInt8] = [0xF0, 0, 0x20, 0x29, 2, 0x0D] + payload + [0xF7]
        // CoreMIDI uses a variable-size packet list. Reserve room for the whole frame.
        let capacity = 1024
        let storage = UnsafeMutableRawPointer.allocate(
            byteCount: capacity, alignment: MemoryLayout<MIDIPacketList>.alignment
        )
        defer { storage.deallocate() }
        let list = storage.bindMemory(to: MIDIPacketList.self, capacity: 1)
        let packet = MIDIPacketListInit(list)
        guard bytes.count + 32 <= capacity else {
            throw MIDIError(operation: "Build MIDI packet", status: -1)
        }
        _ = bytes.withUnsafeBufferPointer { buffer in
            MIDIPacketListAdd(list, capacity, packet, 0, buffer.count, buffer.baseAddress!)
        }
        try check(MIDISend(port, endpoint, list), "Send lights")
    }

    private func check(_ status: OSStatus, _ operation: String) throws {
        if status != noErr { throw MIDIError(operation: operation, status: status) }
    }
}
