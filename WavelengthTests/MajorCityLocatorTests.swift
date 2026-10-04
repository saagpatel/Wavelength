import Testing
import Foundation
@testable import Wavelength

struct MajorCityLocatorTests {

    @Test func downtownMatchesCity() {
        let city = MajorCityLocator.nearestCity(lat: 37.7793, lon: -122.4193)  // SF Civic Center
        #expect(city?.name == "San Francisco")
    }

    @Test func ruralLocationMatchesNothing() {
        let city = MajorCityLocator.nearestCity(lat: 39.5501, lon: -105.7821)  // central Colorado mountains
        #expect(city == nil)
    }

    @Test func closestCityWinsWhenRadiiOverlap() {
        // Downtown Oakland is ~13 km from San Francisco's center but ~0 km from Oakland's.
        let city = MajorCityLocator.nearestCity(lat: 37.8044, lon: -122.2712)
        #expect(city?.name == "Oakland")
    }

    @Test func radiusIsRespected() {
        let sf = MajorCity(name: "San Francisco", lat: 37.7749, lon: -122.4194)
        // ~25 km south of SF center.
        #expect(MajorCityLocator.nearestCity(lat: 37.55, lon: -122.42, cities: [sf], radiusKm: 20) == nil)
        #expect(MajorCityLocator.nearestCity(lat: 37.55, lon: -122.42, cities: [sf], radiusKm: 30) == sf)
    }

    @Test func bundledTableHasFiftyUniqueCities() {
        #expect(MajorCityLocator.bundled.count == 50)
        #expect(Set(MajorCityLocator.bundled.map(\.name)).count == 50)
    }
}
