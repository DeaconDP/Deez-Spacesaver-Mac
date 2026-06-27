import XCTest
@testable import DeezSpacesaver

final class ByteFormattingTests: XCTestCase {
    func testFormatsBytes() {
        XCTAssertFalse(ByteFormatting.string(for: 0).isEmpty)
        XCTAssertTrue(ByteFormatting.string(for: 1_073_741_824).contains("GB") || ByteFormatting.string(for: 1_073_741_824).contains("MB"))
    }

    func testDiskStatsUsedFraction() {
        let stats = DiskStats(totalBytes: 1000, availableBytes: 250)
        XCTAssertEqual(stats.usedBytes, 750)
        XCTAssertEqual(stats.usedFraction, 0.75, accuracy: 0.001)
    }
}
