import Foundation
import CoreLocation

struct Airport: Codable, Sendable {
    let ident: String
    let name: String
    let lat: Double
    let lon: Double
}

enum AirportLoader {

    static func loadBundled() -> [Airport] {
        guard let url = Bundle.main.url(forResource: "airports", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let airports = try? JSONDecoder().decode([Airport].self, from: data)
        else { return [] }
        return airports
    }

    /// Find the nearest airport within a threshold distance.
    nonisolated static func nearestAirport(
        lat: Double, lon: Double,
        airports: [Airport],
        thresholdKm: Double = 2.0
    ) -> Airport? {
        let userLocation = CLLocation(latitude: lat, longitude: lon)
        let thresholdMeters = thresholdKm * 1000
        return airports.first { airport in
            let airportLocation = CLLocation(latitude: airport.lat, longitude: airport.lon)
            return userLocation.distance(from: airportLocation) <= thresholdMeters
        }
    }
}
