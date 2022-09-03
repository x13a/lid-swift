import XCTest
@testable import Lid

final class LidTests: XCTestCase {
    func testGetState() throws {
        print(Lid.getState())
    }
}
