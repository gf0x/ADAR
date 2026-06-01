import UIKit
import UniformTypeIdentifiers

fileprivate let segueToExperienceIdentifier = "segueToExperience"
fileprivate let segueToConnectIdentifier = "segueToConnect"

class IntroViewController: UIViewController {

    @IBOutlet private weak var titleLabel: UILabel!

    private var selectedUrl: URL?

    override func viewDidLoad() {
        super.viewDidLoad()
        NotificationCenter.default.addObserver(self, selector: #selector(willEnterForeground),
                                               name: UIApplication.willEnterForegroundNotification, object: nil)
#if ADAR_DEMO_MODE
        self.titleLabel.text?.append("\r(demo mode)")
#endif
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        SettingsProvider.shared.userRole = .undefined
    }

    @objc func willEnterForeground() {}

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        switch segue.identifier {
        case segueToExperienceIdentifier: SettingsProvider.shared.userRole = .master
        case segueToConnectIdentifier: SettingsProvider.shared.userRole = .slave
        default: ()
        }
    }

    @IBAction func startButtonClick(_ sender: Any) {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: [.adar])
        documentPicker.allowsMultipleSelection = false
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }

    @IBAction func connectButtonClick(_ sender: Any) {
        self.performSegue(withIdentifier: segueToConnectIdentifier, sender: nil)
    }
}

// MARK: - UIDocumentPickerDelegate
extension IntroViewController: UIDocumentPickerDelegate {

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard FileSession.shared.graphData == nil, let firstURL = urls.first else { return }
        guard firstURL.startAccessingSecurityScopedResource() else {
            showAlert("Could not access the selected file.")
            return
        }
        do {
            FileSession.shared.graphData = try Data(contentsOf: firstURL)
            firstURL.stopAccessingSecurityScopedResource()
            self.performSegue(withIdentifier: segueToExperienceIdentifier, sender: nil)
        } catch {
            firstURL.stopAccessingSecurityScopedResource()
            showAlert("Failed to load file: \(error.localizedDescription)")
        }
    }

    private func showAlert(_ message: String) {
        let alert = UIAlertController(title: "Error", message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}

extension UTType {
    static let adar = UTType("ua.edu.ukma.adar")!
}
