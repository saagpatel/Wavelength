import Testing
import CoreLocation
@testable import Wavelength

struct LocationMonitorTests {

    @Test func firstLocationAlwaysAccepted() {
        let newLocation = CLLocation(latitude: 37.7749, longitude: -122.4194)
        let result = LocationMonitor.shouldUpdate(
            newLocation: newLocation,
            currentLocation: nil,
            threshold: 500
        )
        #expect(result == true)
    }

    @Test func locationUnder500mIsRejected() {
        let current = CLLocation(latitude: 37.7749, longitude: -122.4194)
        // ~100m north
        let nearby = CLLocation(latitude: 37.7758, longitude: -122.4194)
        let result = LocationMonitor.shouldUpdate(
            newLocation: nearby,
            currentLocation: current,
            threshold: 500
        )
        #expect(result == false)
    }

    @Test func locationOver500mIsAccepted() {
        let current = CLLocation(latitude: 37.7749, longitude: -122.4194)
        // ~1km north
        let farAway = CLLocation(latitude: 37.7849, longitude: -122.4194)
        let result = LocationMonitor.shouldUpdate(
            newLocation: farAway,
            currentLocation: current,
            threshold: 500
        )
        #expect(result == true)
    }

    @Test func locationExactlyAtThresholdIsAccepted() {
        let current = CLLocation(latitude: 0, longitude: 0)
        let atThreshold = CLLocation(latitude: 0.0045, longitude: 0)
        let distance = atThreshold.distance(from: current)

        let result = LocationMonitor.shouldUpdate(
            newLocation: atThreshold,
            currentLocation: current,
            threshold: distance
        )
        #expect(result == true)
    }

    @Test func customThresholdRespected() {
        let current = CLLocation(latitude: 37.7749, longitude: -122.4194)
        // ~300m away
        let location300m = CLLocation(latitude: 37.7776, longitude: -122.4194)

        #expect(LocationMonitor.shouldUpdate(
            newLocation: location300m, currentLocation: current, threshold: 500
        ) == false)

        #expect(LocationMonitor.shouldUpdate(
            newLocation: location300m, currentLocation: current, threshold: 200
        ) == true)
    }
}
