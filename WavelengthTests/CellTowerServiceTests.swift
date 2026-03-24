import Testing
import Foundation
@testable import Wavelength

struct CellTowerServiceTests {

    @Test func parseValidOpenCellIDResponse() throws {
        let json = """
        {
            "lat": 37.7749,
            "lon": -122.4194,
            "mcc": 310,
            "mnc": 260,
            "lac": 7001,
            "cellid": 7241401,
            "averageSignalStrength": -85,
            "range": 500,
            "status": "ok"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OpenCellIDResponse.self, from: json)
        #expect(response.lat == 37.7749)
        #expect(response.lon == -122.4194)
        #expect(response.mcc == 310)
        #expect(response.status == "ok")
    }

    @Test func parseResponseWithNullOptionals() throws {
        let json = """
        {
            "lat": 37.0,
            "lon": -122.0,
            "mcc": 310,
            "mnc": 260,
            "lac": 1,
            "cellid": 1,
            "status": "ok"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OpenCellIDResponse.self, from: json)
        #expect(response.averageSignalStrength == nil)
        #expect(response.range == nil)
    }

    @Test func coordinatesAreInValidRange() throws {
        let json = """
        {"lat": 37.7749, "lon": -122.4194, "mcc": 310, "mnc": 260,
         "lac": 7001, "cellid": 7241401, "status": "ok"}
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OpenCellIDResponse.self, from: json)
        #expect(response.lat >= -90 && response.lat <= 90)
        #expect(response.lon >= -180 && response.lon <= 180)
    }
}
