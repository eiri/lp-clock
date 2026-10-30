import Foundation

struct ClockFrame {
    static let pads: [UInt8] = (1...8).flatMap { row in
        (1...8).map { UInt8(row * 10 + $0) }
    }
    static let controls: [UInt8] = (1...8).flatMap { (index: Int) -> [UInt8] in
        [UInt8(90 + index), UInt8(index * 10 + 9)]
    }
    let colors: [UInt8]

    init(date: Date, calendar: Calendar = .current) {
        let parts = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: date)
        let year = parts.year ?? 0
        let values = [
            year & 255, (year >> 8) & 255, parts.month ?? 0, parts.day ?? 0,
            0, parts.hour ?? 0, parts.minute ?? 0, parts.second ?? 0,
        ]
        // Each field has a color. The year continues in the second column.
        let palette: [UInt8] = [5, 5, 9, 13, 0, 21, 45, 49]
        colors = (0..<8).flatMap { bit in
            (0..<8).map { column in
                values[column] & (1 << bit) == 0 ? 0 : palette[column]
            }
        }
    }

    var message: [UInt8] {
        let hues: [UInt8: [Int]] = [
            0: [0, 0, 0], 5: [127, 0, 0], 9: [127, 48, 0],
            13: [127, 100, 0], 21: [0, 127, 0],
            45: [0, 0, 127], 49: [72, 0, 127],
        ]

        // RGB messages preserve each hue while fading from full at the bottom to 17% at the top.
        return [3] + Self.pads.enumerated().flatMap { index, pad -> [UInt8] in
            let brightness = 127 - (index / 8) * 15
            let rgb = hues[colors[index]]!.map { UInt8($0 * brightness / 127) }
            return [3, pad] + rgb
        }
    }

    static func ledMessage(_ lights: [(UInt8, UInt8)]) -> [UInt8] {
        [3] + lights.flatMap { [0, $0.0, $0.1] }
    }

    static var clearMessage: [UInt8] {
        ledMessage((pads + controls).map { ($0, 0) })
    }
}
