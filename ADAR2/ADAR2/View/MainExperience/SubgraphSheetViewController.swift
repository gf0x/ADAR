import UIKit

final class SubgraphSheetViewController: UIViewController {

    var nodeDisplayName: String = ""
    var onConfirm: ((Int, @escaping (Double) -> Void, @escaping () -> Void) -> Void)?
    var onDismiss: (() -> Void)?

    private let stepper = UIStepper()
    private let depthLabel = UILabel()
    private var stack: UIStackView!
    private var progressView: UIProgressView?

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        preferredContentSize = CGSize(width: 320, height: 180)

        let titleLabel = UILabel()
        titleLabel.text = nodeDisplayName
        titleLabel.font = .systemFont(ofSize: 15, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 2

        stepper.minimumValue = 1
        stepper.maximumValue = 10
        stepper.value = 2
        stepper.stepValue = 1
        stepper.addTarget(self, action: #selector(stepperChanged), for: .valueChanged)

        depthLabel.text = depthText(for: 2)
        depthLabel.textAlignment = .center
        depthLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 20, weight: .medium)

        let stepperRow = UIStackView(arrangedSubviews: [depthLabel, stepper])
        stepperRow.axis = .horizontal
        stepperRow.spacing = 16
        stepperRow.alignment = .center

        let showButton = UIButton(type: .system)
        showButton.setTitle("Show subgraph", for: .normal)
        showButton.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        showButton.addTarget(self, action: #selector(confirmTapped), for: .touchUpInside)

        stack = UIStackView(arrangedSubviews: [titleLabel, stepperRow, showButton])
        stack.axis = .vertical
        stack.spacing = 16
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
    }

    @objc private func stepperChanged() {
        depthLabel.text = depthText(for: Int(stepper.value))
    }

    @objc private func confirmTapped() {
        let depth = Int(stepper.value)
        confirmed = true
        showProgressBar()
        onConfirm?(depth, { [weak self] progress in
            DispatchQueue.main.async {
                self?.progressView?.setProgress(Float(progress), animated: progress > 0)
            }
        }, { [weak self] in
            self?.dismiss(animated: true)
        })
    }

    private func showProgressBar() {
        stack.isHidden = true

        let bar = UIProgressView(progressViewStyle: .default)
        bar.progress = 0
        bar.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(bar)
        NSLayoutConstraint.activate([
            bar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            bar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            bar.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        progressView = bar
    }

    private var confirmed = false

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if !confirmed { onDismiss?() }
    }

    private func depthText(for depth: Int) -> String {
        "Depth: \(depth) hop\(depth == 1 ? "" : "s")"
    }
}
