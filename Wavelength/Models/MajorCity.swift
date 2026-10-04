import Foundation
import CoreLocation

/// A bundled major US city center used for on-device urban 5G inference.
struct MajorCity: Sendable, Equatable {
    let name: String
    let lat: Double
    let lon: Double
}

enum MajorCityLocator {

    /// Approximate city-center coordinates for the 50 major US cities used for
    /// probable 5G C-Band inference. Matching is done entirely on-device; no
    /// location leaves the phone.
    static let bundled: [MajorCity] = [
        MajorCity(name: "New York", lat: 40.7128, lon: -74.0060),
        MajorCity(name: "Los Angeles", lat: 34.0522, lon: -118.2437),
        MajorCity(name: "Chicago", lat: 41.8781, lon: -87.6298),
        MajorCity(name: "Houston", lat: 29.7604, lon: -95.3698),
        MajorCity(name: "Phoenix", lat: 33.4484, lon: -112.0740),
        MajorCity(name: "Philadelphia", lat: 39.9526, lon: -75.1652),
        MajorCity(name: "San Antonio", lat: 29.4241, lon: -98.4936),
        MajorCity(name: "San Diego", lat: 32.7157, lon: -117.1611),
        MajorCity(name: "Dallas", lat: 32.7767, lon: -96.7970),
        MajorCity(name: "San Jose", lat: 37.3382, lon: -121.8863),
        MajorCity(name: "Austin", lat: 30.2672, lon: -97.7431),
        MajorCity(name: "Jacksonville", lat: 30.3322, lon: -81.6557),
        MajorCity(name: "San Francisco", lat: 37.7749, lon: -122.4194),
        MajorCity(name: "Columbus", lat: 39.9612, lon: -82.9988),
        MajorCity(name: "Charlotte", lat: 35.2271, lon: -80.8431),
        MajorCity(name: "Indianapolis", lat: 39.7684, lon: -86.1581),
        MajorCity(name: "Seattle", lat: 47.6062, lon: -122.3321),
        MajorCity(name: "Denver", lat: 39.7392, lon: -104.9903),
        MajorCity(name: "Washington", lat: 38.9072, lon: -77.0369),
        MajorCity(name: "Nashville", lat: 36.1627, lon: -86.7816),
        MajorCity(name: "Oklahoma City", lat: 35.4676, lon: -97.5164),
        MajorCity(name: "Boston", lat: 42.3601, lon: -71.0589),
        MajorCity(name: "Portland", lat: 45.5152, lon: -122.6784),
        MajorCity(name: "Las Vegas", lat: 36.1699, lon: -115.1398),
        MajorCity(name: "Memphis", lat: 35.1495, lon: -90.0490),
        MajorCity(name: "Louisville", lat: 38.2527, lon: -85.7585),
        MajorCity(name: "Baltimore", lat: 39.2904, lon: -76.6122),
        MajorCity(name: "Milwaukee", lat: 43.0389, lon: -87.9065),
        MajorCity(name: "Albuquerque", lat: 35.0844, lon: -106.6504),
        MajorCity(name: "Tucson", lat: 32.2226, lon: -110.9747),
        MajorCity(name: "Fresno", lat: 36.7378, lon: -119.7871),
        MajorCity(name: "Sacramento", lat: 38.5816, lon: -121.4944),
        MajorCity(name: "Mesa", lat: 33.4152, lon: -111.8315),
        MajorCity(name: "Kansas City", lat: 39.0997, lon: -94.5786),
        MajorCity(name: "Atlanta", lat: 33.7490, lon: -84.3880),
        MajorCity(name: "Omaha", lat: 41.2565, lon: -95.9345),
        MajorCity(name: "Colorado Springs", lat: 38.8339, lon: -104.8214),
        MajorCity(name: "Raleigh", lat: 35.7796, lon: -78.6382),
        MajorCity(name: "Long Beach", lat: 33.7701, lon: -118.1937),
        MajorCity(name: "Miami", lat: 25.7617, lon: -80.1918),
        MajorCity(name: "Oakland", lat: 37.8044, lon: -122.2712),
        MajorCity(name: "Minneapolis", lat: 44.9778, lon: -93.2650),
        MajorCity(name: "Tampa", lat: 27.9506, lon: -82.4572),
        MajorCity(name: "Arlington", lat: 32.7357, lon: -97.1081),
        MajorCity(name: "New Orleans", lat: 29.9511, lon: -90.0715),
        MajorCity(name: "Wichita", lat: 37.6872, lon: -97.3301),
        MajorCity(name: "Cleveland", lat: 41.4993, lon: -81.6944),
        MajorCity(name: "Honolulu", lat: 21.3069, lon: -157.8583),
        MajorCity(name: "Anchorage", lat: 61.2181, lon: -149.9003),
        MajorCity(name: "Detroit", lat: 42.3314, lon: -83.0458),
    ]

    /// The closest bundled city center within `radiusKm`, or nil.
    nonisolated static func nearestCity(
        lat: Double, lon: Double,
        cities: [MajorCity] = bundled,
        radiusKm: Double = 20.0
    ) -> MajorCity? {
        let userLocation = CLLocation(latitude: lat, longitude: lon)
        let radiusMeters = radiusKm * 1000
        return cities
            .map { ($0, userLocation.distance(from: CLLocation(latitude: $0.lat, longitude: $0.lon))) }
            .filter { $0.1 <= radiusMeters }
            .min { $0.1 < $1.1 }?
            .0
    }
}
