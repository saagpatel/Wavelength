import Testing
import Foundation
import CoreLocation
@testable import Wavelength

struct ContextualEngineTests {

    @Test func airportProximityTriggersADSB() {
        let sfo = Airport(ident: "KSFO", name: "San Francisco Intl", lat: 37.6213, lon: -122.3790)
        let nearSFO = AirportLoader.nearestAirport(
            lat: 37.620, lon: -122.380,
            airports: [sfo],
            thresholdKm: 2.0
        )
        #expect(nearSFO != nil)
        #expect(nearSFO?.ident == "KSFO")
    }

    @Test func distantAirportNotDetected() {
        let sfo = Airport(ident: "KSFO", name: "San Francisco Intl", lat: 37.6213, lon: -122.3790)
        let farAway = AirportLoader.nearestAirport(
            lat: 37.80, lon: -122.40,  // ~20km north
            airports: [sfo],
            thresholdKm: 2.0
        )
        #expect(farAway == nil)
    }

    @Test func emptyAirportsReturnsNil() {
        let result = AirportLoader.nearestAirport(
            lat: 37.7749, lon: -122.4194,
            airports: [],
            thresholdKm: 2.0
        )
        #expect(result == nil)
    }

    @Test func airportWithinThresholdDetected() {
        let jfk = Airport(ident: "KJFK", name: "JFK Intl", lat: 40.6413, lon: -73.7781)
        let lax = Airport(ident: "KLAX", name: "LAX", lat: 33.9425, lon: -118.4081)
        let sfo = Airport(ident: "KSFO", name: "SFO", lat: 37.6213, lon: -122.3790)

        // Location near SFO
        let result = AirportLoader.nearestAirport(
            lat: 37.622, lon: -122.379,
            airports: [jfk, lax, sfo],
            thresholdKm: 2.0
        )
        #expect(result?.ident == "KSFO")
    }
}
