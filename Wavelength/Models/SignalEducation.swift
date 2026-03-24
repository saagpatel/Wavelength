/// Educational blurbs for each signal category.
/// Displayed in the SignalDetailPanel when a user taps a signal.
enum SignalEducation {

    static let blurbs: [SignalCategory: (title: String, detail: String)] = [
        .bluetooth: (
            "Bluetooth Low Energy",
            "Short-range wireless protocol at 2.4 GHz with 78 MHz bandwidth. Used by headphones, watches, fitness trackers, and smart home devices within roughly 10 meters."
        ),
        .wifi: (
            "Wi-Fi (IEEE 802.11)",
            "Wireless networking across 2.4 GHz, 5 GHz, and 6 GHz bands with channels up to 160 MHz wide. Your device uses Wi-Fi to connect to your router and the internet."
        ),
        .cellular: (
            "Cellular Network",
            "Mobile signals spanning 600 MHz to 3.7 GHz, licensed to carriers in specific bands. Lower bands (600\u{2013}900 MHz) travel farther; higher bands (2.5\u{2013}3.7 GHz) carry more data."
        ),
        .fm: (
            "FM Radio Broadcasting",
            "Analog radio stations transmitting between 88\u{2013}108 MHz with 200 kHz channel spacing. Each station is licensed by the FCC with a specific frequency, power level, and coverage area."
        ),
        .gps: (
            "GPS Navigation Satellites",
            "The L1 signal at 1575.42 MHz is broadcast by 24\u{2013}31 satellites at 20,200 km altitude. Your phone uses signals from at least 4 satellites to compute your position."
        ),
        .satellite: (
            "Communications Satellite",
            "Satellites in low Earth orbit (780 km for Iridium) and medium orbit (20,200 km for GPS) transmit on dedicated bands. Visible satellites change every few minutes as they cross the sky."
        ),
        .broadcast: (
            "Broadcast Signal",
            "One-to-many transmissions including TV, ADS-B aircraft transponders (1090 MHz), and emergency beacons. ADS-B lets aircraft broadcast their identity, position, and altitude."
        ),
        .emergency: (
            "Emergency Frequency",
            "Internationally reserved frequencies for distress and safety. Aviation emergency at 121.5 MHz, maritime distress at 156.8 MHz (VHF Ch 16), and satellite beacons at 406 MHz."
        ),
    ]
}
