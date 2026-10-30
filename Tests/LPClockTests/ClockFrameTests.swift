import Foundation
import Testing
@testable import LPClock

struct ClockFrameTests {
    private func frame(_ year: Int, _ month: Int, _ day: Int, _ hour: Int, _ minute: Int, _ second: Int) -> ClockFrame {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(
            year: year, month: month, day: day, hour: hour, minute: minute, second: second
        ))!
        return ClockFrame(date: date, calendar: calendar)
    }

    private func value(_ frame: ClockFrame, _ column: Int) -> Int {
        (0..<8).reduce(0) { value, bit in
            value + (frame.colors[bit * 8 + column] == 0 ? 0 : 1 << bit)
        }
    }

    @Test func fieldLayout() {
        let frame = frame(2026, 10, 30, 23, 59, 58)
        #expect(frame.colors.count == 64)
        #expect(value(frame, 0) + (value(frame, 1) << 8) == 2026)
        #expect(value(frame, 2) == 10)
        #expect(value(frame, 3) == 30)
        #expect(value(frame, 4) == 0)
        #expect(value(frame, 5) == 23)
        #expect(value(frame, 6) == 59)
        #expect(value(frame, 7) == 58)
        #expect(frame.colors[7] == 0)
        #expect(frame.colors[15] == 49)

        let palette: [UInt8] = [5, 5, 9, 13, 0, 21, 45, 49]
        for column in 0..<8 {
            let lit = (0..<8).map { frame.colors[$0 * 8 + column] }.filter { $0 != 0 }
            #expect(lit.allSatisfy { $0 == palette[column] })
        }
    }

    @Test func midnightAndLeapDay() {
        let frame = frame(2024, 2, 29, 0, 0, 0)
        #expect(value(frame, 2) == 2)
        #expect(value(frame, 3) == 29)
        for column in 5...7 { #expect(value(frame, column) == 0) }
    }

    @Test func yearBoundary() {
        let before = frame(2025, 12, 31, 23, 59, 59)
        let after = frame(2026, 1, 1, 0, 0, 0)
        #expect(before.colors != after.colors)
        #expect(value(after, 0) + (value(after, 1) << 8) == 2026)
        #expect(value(after, 2) == 1)
        #expect(value(after, 3) == 1)
        #expect(value(after, 7) == 0)
    }

    @Test func brightnessGradient() {
        let frame = frame(2047, 1, 1, 0, 0, 0)
        let message = frame.message
        for row in 0..<8 {
            let offset = 1 + row * 8 * 5
            #expect(message[offset + 2] == UInt8(127 - row * 15))
            #expect(message[offset + 3] == 0)
            #expect(message[offset + 4] == 0)
        }

        for index in 0..<64 where frame.colors[index] == 0 {
            let offset = 1 + index * 5
            #expect(Array(message[(offset + 2)...(offset + 4)]) == [0, 0, 0])
        }
    }

    @Test func protocolLayout() {
        #expect(ClockFrame.pads.first == 11)
        #expect(ClockFrame.pads.last == 88)
        #expect(Set(ClockFrame.pads + ClockFrame.controls).count == 80)
        let message = frame(2026, 1, 1, 0, 0, 1).message
        #expect(message.count == 321)
        #expect(Array(message.prefix(3)) == [3, 3, 11])
        #expect(message.allSatisfy { $0 < 128 })
        #expect(ClockFrame.clearMessage.count == 241)
    }
}
