import Foundation

/// Holds the raw .adar file data for the current session.
/// Separated from SettingsProvider which manages session/role state.
final class FileSession {

    static let shared = FileSession()
    private init() {}

    var graphData: Data?

    func reset() {
        graphData = nil
    }
}
