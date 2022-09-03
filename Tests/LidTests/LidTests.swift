import XCTest
@testable import Lid

final class LidTests: XCTestCase {
    func testGetState() throws {
        print(Lid.getState())
    }
    
    func testNotifier() throws {
        let notifier = LidNotifier { arg in
            print(arg & LidNotifier.kClamshellStateBit)
        }
        assert(notifier != nil)
        RunLoop.main.run()
    }
}
