import Foundation

enum RefreshInterval: Int, CaseIterable {
    case one = 1, five = 5, ten = 10, fifteen = 15

    private static let defaultsKey = "refreshIntervalSeconds"
    var seconds: TimeInterval { TimeInterval(rawValue) }

    static func load() -> RefreshInterval {
        RefreshInterval(rawValue: UserDefaults.standard.integer(forKey: defaultsKey)) ?? .five
    }

    func save() { UserDefaults.standard.set(rawValue, forKey: Self.defaultsKey) }
}
