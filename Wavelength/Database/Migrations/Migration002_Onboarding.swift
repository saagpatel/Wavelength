import GRDB

enum Migration002_Onboarding {
    static func migrate(_ db: Database) throws {
        try db.alter(table: "settings") { t in
            t.add(column: "has_seen_onboarding", .boolean).notNull().defaults(to: false)
        }
    }
}
