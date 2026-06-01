import UIKit

final class ItemSizeScalarSheetViewController: UIViewController {
    var initialValue: CGFloat = 1.0
    var valueChanged: ((CGFloat) -> Void)?

    private let slider = UISlider()
    private let valueLabel = UILabel()
    private var lastHapticAt1 = false
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        preferredContentSize = CGSize(width: 320, height: 160)

        slider.minimumValue = 0.5
        slider.maximumValue = 10
        slider.value = Float(initialValue)
        slider.isContinuous = true
        slider.addTarget(self, action: #selector(sliderChanged(_:)), for: .valueChanged)

        valueLabel.textAlignment = .center
        valueLabel.font = UIFont.monospacedDigitSystemFont(ofSize: 22, weight: .medium)
        valueLabel.text = self.labelText(for: self.initialValue)

        let stack = UIStackView(arrangedSubviews: [valueLabel, slider])
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

    @objc private func sliderChanged(_ sender: UISlider) {
        let value = CGFloat(sender.value)
        let steppedValue = (round(value * 2) / 2.0)
        if steppedValue != value {
            sender.value = Float(steppedValue)
        }
        valueLabel.text = self.labelText(for: steppedValue)
        valueChanged?(steppedValue)

        // Haptic when crossing 1.0 (one time per crossing)
        let isAt1 = abs(steppedValue - 1.0) < 0.025
        if isAt1 && !lastHapticAt1 {
            feedbackGenerator.impactOccurred()
        }
        lastHapticAt1 = isAt1
    }

    private func labelText(for value: CGFloat) -> String {
        "Item size scalar: \(String(format: "%.2f", value))"
    }
}
