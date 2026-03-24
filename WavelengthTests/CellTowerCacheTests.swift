import Testing
import Foundation
import GRDB
@testable import Wavelength

struct CellTowerCacheTests {

    @Test func bboxComputationCorrect() {
        let bbox = CellTowerService.computeBBOX(lat: 37.7749, lon: -122.4194, radiusKm: 5.0)
        // 5km / 111 = ~0.045 degrees lat
        #expect(abs(bbox.latMin - (37.7749 - 0.045)) < 0.001)
        #expect(abs(bbox.latMax - (37.7749 + 0.045)) < 0.001)
        #expect(bbox.lonMin < -122.4194)
        #expect(bbox.lonMax > -122.4194)
    }

    @Test func radioToFrequencyMapping() {
        #expect(CellTowerService.radioToFrequency("LTE").mhz == 1900)
        #expect(CellTowerService.radioToFrequency("NR").mhz == 3500)
        #expect(CellTowerService.radioToFrequency("UMTS").mhz == 1900)
        #expect(CellTowerService.radioToFrequency("GSM").mhz == 900)
        #expect(CellTowerService.radioToFrequency(nil).band == "Unknown")
    }

    @Test func openCellIDAreaResponseDecoding() throws {
        let json = """
        {
            "count": 2,
            "cells": [
                {"lat": 37.7749, "lon": -122.4194, "mcc": 310, "mnc": 260,
                 "lac": 7001, "cellid": 1234, "radio": "LTE", "range": 500},
                {"lat": 37.7750, "lon": -122.4195, "mcc": 310, "mnc": 260,
                 "lac": 7001, "cellid": 5678, "radio": "NR"}
            ]
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(OpenCellIDAreaResponse.self, from: json)
        #expect(response.count == 2)
        #expect(response.cells.count == 2)
        #expect(response.cells[0].radio == "LTE")
        #expect(response.cells[1].range == nil)
    }

    @Test func towersConvertToSignals() {
        let tower = CellTowerRecord(
            mcc: 310, mnc: 260, lac: 7001, cellId: 1234,
            latitude: 37.7749, longitude: -122.4194,
            frequencyMhz: 1900, bandName: "LTE",
            operatorName: nil, signalDbm: -85, fetchedAt: .now
        )
        let signals = CellTowerService.toSignals([tower])
        #expect(signals.count == 1)
        #expect(signals[0].category == .cellular)
        #expect(signals[0].provenance == .nearby)
        #expect(signals[0].frequencyMHz == 1900)
        #expect(signals[0].signalDBM == -85)
    }

    @Test func recordUpsertPreventsDuplicates() throws {
        let db = try DatabaseQueue()
        var migrator = DatabaseMigrator()
        migrator.registerMigration("001_schema", migrate: Migration001_Schema.migrate)
        try migrator.migrate(db)

        try db.write { db in
            var record1 = CellTowerRecord(
                mcc: 310, mnc: 260, lac: 7001, cellId: 1234,
                latitude: 37.0, longitude: -122.0,
                frequencyMhz: 1900, bandName: "LTE",
                fetchedAt: .now
            )
            try record1.insert(db)

            var record2 = CellTowerRecord(
                mcc: 310, mnc: 260, lac: 7001, cellId: 1234,
                latitude: 37.1, longitude: -122.1,
                frequencyMhz: 1900, bandName: "LTE",
                fetchedAt: .now
            )
            try record2.upsert(db)
        }

        let count = try db.read { db in
            try CellTowerRecord.fetchCount(db)
        }
        #expect(count == 1)
    }
}
