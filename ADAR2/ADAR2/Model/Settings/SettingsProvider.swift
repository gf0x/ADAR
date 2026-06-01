import Foundation

final class SettingsProvider {

    static let shared = SettingsProvider()
    private init() {}

    var userRole: UserRole = .undefined

    func reset() {
        self.userRole = .undefined
    }
}
