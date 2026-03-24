import Testing
import Foundation
@testable import Wavelength

struct NetworkMonitorTests {

    @MainActor @Test func initialStateIsOnline() {
        let monitor = NetworkMonitor()
        #expect(monitor.isOnline == true)
    }

    @MainActor @Test func lastOnlineDateSetOnInit() {
        let before = Date()
        let monitor = NetworkMonitor()
        let after = Date()
        #expect(monitor.lastOnlineDate >= before)
        #expect(monitor.lastOnlineDate <= after)
    }
}
